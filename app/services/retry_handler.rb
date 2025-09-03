class RetryHandler
  MAX_RETRIES = 3
  BASE_DELAY = 5 # seconds
  MAX_DELAY = 300 # 5 minutes
  JITTER_FACTOR = 0.1

  TRANSIENT_ERRORS = [
    Net::ReadTimeout,
    Net::OpenTimeout,
    Errno::ECONNREFUSED,
    Errno::ETIMEDOUT,
    Errno::ECONNRESET,
    Faraday::TimeoutError,
    Redis::CannotConnectError,
    ErrorHandler::RateLimitExceededError,
    ErrorHandler::RedisConnectionError
  ].freeze

  class << self
    def with_retry(options = {}, &block)
      max_retries = options[:max_retries] || MAX_RETRIES
      base_delay = options[:base_delay] || BASE_DELAY
      max_delay = options[:max_delay] || MAX_DELAY
      fallback = options[:fallback]
      context = options[:context] || {}

      attempts = 0
      last_error = nil

      begin
        attempts += 1
        ApplicationLogger.log_job_execution(
          context[:job_class] || "RetryHandler",
          context[:job_id],
          "attempt",
          { retry_count: attempts - 1 }
        )

        result = yield
        
        if attempts > 1
          ApplicationLogger.log_job_execution(
            context[:job_class] || "RetryHandler",
            context[:job_id],
            "recovered",
            { retry_count: attempts - 1 }
          )
        end
        
        return result

      rescue *TRANSIENT_ERRORS => e
        last_error = e
        
        if attempts < max_retries
          delay = calculate_delay(attempts, base_delay, max_delay)
          
          ApplicationLogger.log_job_execution(
            context[:job_class] || "RetryHandler",
            context[:job_id],
            "retry",
            { 
              retry_count: attempts,
              delay: delay,
              error: e.message 
            }
          )
          
          sleep(delay)
          retry
        end

        # Max retries reached, try fallback if available
        if fallback && fallback.respond_to?(:call)
          ApplicationLogger.log_job_execution(
            context[:job_class] || "RetryHandler",
            context[:job_id],
            "fallback",
            { error: e.message }
          )
          
          begin
            return fallback.call(e)
          rescue => fallback_error
            ApplicationLogger.log_job_execution(
              context[:job_class] || "RetryHandler",
              context[:job_id],
              "fallback_failed",
              { error: fallback_error.message }
            )
            raise fallback_error
          end
        end

        # No fallback available, raise the error
        ApplicationLogger.log_job_execution(
          context[:job_class] || "RetryHandler",
          context[:job_id],
          "failed",
          { 
            retry_count: attempts,
            error: e.message 
          }
        )
        
        raise e

      rescue => e
        # Non-transient error, don't retry
        ApplicationLogger.log_job_execution(
          context[:job_class] || "RetryHandler",
          context[:job_id],
          "permanent_failure",
          { error: e.message }
        )
        
        # Try fallback for permanent errors too
        if fallback && fallback.respond_to?(:call)
          begin
            return fallback.call(e)
          rescue => fallback_error
            raise fallback_error
          end
        end
        
        raise e
      end
    end

    def with_circuit_breaker(service_name, &block)
      circuit_key = "circuit_breaker:#{service_name}"
      failure_count_key = "#{circuit_key}:failures"
      
      # Check if circuit is open
      if Redis.current.get(circuit_key) == "open"
        raise ErrorHandler::ChritError.new(
          code: 503,
          user_message: "서비스가 일시적으로 사용할 수 없습니다.",
          internal_message: "Circuit breaker open for #{service_name}"
        )
      end

      begin
        result = yield
        
        # Reset failure count on success
        Redis.current.del(failure_count_key)
        
        result
      rescue => e
        # Increment failure count
        failures = Redis.current.incr(failure_count_key)
        Redis.current.expire(failure_count_key, 60)
        
        # Open circuit if threshold reached
        if failures >= 5
          Redis.current.setex(circuit_key, 30, "open")
          ApplicationLogger.log_performance_metric(
            "circuit_breaker_opened",
            1,
            { tags: { service: service_name }, alert: true }
          )
        end
        
        raise e
      end
    end

    private

    def calculate_delay(attempt, base_delay, max_delay)
      # Exponential backoff with jitter
      delay = [base_delay * (2 ** (attempt - 1)), max_delay].min
      jitter = delay * JITTER_FACTOR * (rand - 0.5) * 2
      (delay + jitter).round(2)
    end
  end
end