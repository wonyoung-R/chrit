class ApplicationLogger
  class << self
    def log_knowledge_processing(knowledge_id, event, data = {})
      log_entry = {
        timestamp: Time.current.iso8601,
        event_type: "knowledge_processing",
        knowledge_id: knowledge_id,
        event: event,
        user_id: data[:user_id],
        url: data[:url],
        content_type: data[:content_type],
        duration_ms: data[:duration_ms],
        tokens_used: data[:tokens_used],
        credits_consumed: data[:credits_consumed],
        status: data[:status],
        error: data[:error]
      }.compact

      Rails.logger.info(log_entry.to_json)
      log_entry
    end

    def log_api_call(service, method, data = {})
      log_entry = {
        timestamp: Time.current.iso8601,
        event_type: "api_call",
        service: service,
        method: method,
        request_id: data[:request_id],
        duration_ms: data[:duration_ms],
        status_code: data[:status_code],
        tokens: data[:tokens],
        error: data[:error],
        retry_count: data[:retry_count]
      }.compact

      level = data[:error].present? ? :error : :info
      Rails.logger.send(level, log_entry.to_json)
      log_entry
    end

    def log_credit_transaction(user_id, operation, data = {})
      log_entry = {
        timestamp: Time.current.iso8601,
        event_type: "credit_transaction",
        user_id: user_id,
        operation: operation,
        amount: data[:amount],
        balance_before: data[:balance_before],
        balance_after: data[:balance_after],
        knowledge_id: data[:knowledge_id],
        reason: data[:reason]
      }.compact

      Rails.logger.info(log_entry.to_json)
      log_entry
    end

    def log_job_execution(job_class, job_id, event, data = {})
      log_entry = {
        timestamp: Time.current.iso8601,
        event_type: "job_execution",
        job_class: job_class,
        job_id: job_id,
        event: event,
        queue: data[:queue],
        args: data[:args],
        duration_ms: data[:duration_ms],
        memory_mb: data[:memory_mb],
        error: data[:error],
        retry_count: data[:retry_count]
      }.compact

      level = case event
              when "failed", "error" then :error
              when "retry" then :warn
              else :info
              end

      Rails.logger.send(level, log_entry.to_json)
      log_entry
    end

    def log_performance_metric(metric_name, value, data = {})
      log_entry = {
        timestamp: Time.current.iso8601,
        event_type: "performance_metric",
        metric: metric_name,
        value: value,
        unit: data[:unit],
        tags: data[:tags],
        percentile: data[:percentile],
        threshold: data[:threshold],
        alert: data[:alert]
      }.compact

      level = data[:alert] ? :warn : :info
      Rails.logger.send(level, log_entry.to_json)
      log_entry
    end

    def log_security_event(event_type, data = {})
      log_entry = {
        timestamp: Time.current.iso8601,
        event_type: "security",
        security_event: event_type,
        user_id: data[:user_id],
        ip_address: data[:ip_address],
        user_agent: data[:user_agent],
        action: data[:action],
        resource: data[:resource],
        result: data[:result],
        reason: data[:reason]
      }.compact

      Rails.logger.warn(log_entry.to_json)
      log_entry
    end
  end
end