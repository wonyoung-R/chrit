class DebugHelper
  class << self
    def log_processing(knowledge_id)
      Rails.logger.debug "=" * 50
      Rails.logger.debug "Processing Knowledge ##{knowledge_id}"
      Rails.logger.debug "Time: #{Time.current}"
      Rails.logger.debug "Memory: #{get_memory_usage} MB"
      
      if block_given?
        result = yield
        Rails.logger.debug "Completed"
        Rails.logger.debug "=" * 50
        result
      end
    end
    
    def measure_performance(label)
      start_time = Time.current
      memory_before = get_memory_usage_bytes
      
      result = yield
      
      duration = Time.current - start_time
      memory_after = get_memory_usage_bytes
      memory_used = (memory_after - memory_before) / 1024.0 / 1024.0
      
      performance_data = {
        label: label,
        duration_seconds: duration.round(3),
        memory_used_mb: memory_used.round(2)
      }
      
      Rails.logger.info "Performance [#{label}]: #{duration.round(3)}s, #{memory_used.round(2)}MB"
      
      ApplicationLogger.log_performance_metric(
        "operation_performance",
        duration.round(3),
        {
          unit: "seconds",
          tags: { operation: label, memory_mb: memory_used.round(2) }
        }
      )
      
      result
    end
    
    def track_api_usage(service, method, &block)
      start_time = Time.current
      request_id = SecureRandom.uuid
      
      begin
        result = yield
        
        duration_ms = ((Time.current - start_time) * 1000).round
        
        ApplicationLogger.log_api_call(
          service,
          method,
          {
            request_id: request_id,
            duration_ms: duration_ms,
            status_code: 200
          }
        )
        
        result
      rescue => e
        duration_ms = ((Time.current - start_time) * 1000).round
        
        ApplicationLogger.log_api_call(
          service,
          method,
          {
            request_id: request_id,
            duration_ms: duration_ms,
            error: e.message
          }
        )
        
        raise e
      end
    end
    
    def monitor_job_execution(job_instance, &block)
      job_class = job_instance.class.name
      job_id = job_instance.job_id rescue SecureRandom.uuid
      start_time = Time.current
      memory_before = get_memory_usage_bytes
      
      ApplicationLogger.log_job_execution(
        job_class,
        job_id,
        "started",
        { queue: job_instance.queue_name rescue "default" }
      )
      
      begin
        result = yield
        
        duration_ms = ((Time.current - start_time) * 1000).round
        memory_mb = ((get_memory_usage_bytes - memory_before) / 1024.0 / 1024.0).round(2)
        
        ApplicationLogger.log_job_execution(
          job_class,
          job_id,
          "completed",
          {
            duration_ms: duration_ms,
            memory_mb: memory_mb
          }
        )
        
        result
      rescue => e
        duration_ms = ((Time.current - start_time) * 1000).round
        
        ApplicationLogger.log_job_execution(
          job_class,
          job_id,
          "failed",
          {
            duration_ms: duration_ms,
            error: e.message
          }
        )
        
        raise e
      end
    end
    
    def check_system_health
      {
        database: check_database_connection,
        redis: check_redis_connection,
        sidekiq: check_sidekiq_status,
        memory: check_memory_usage,
        disk: check_disk_usage
      }
    end
    
    private
    
    def get_memory_usage
      `ps -o rss= -p #{Process.pid}`.to_i / 1024
    end
    
    def get_memory_usage_bytes
      `ps -o rss= -p #{Process.pid}`.to_i * 1024
    end
    
    def check_database_connection
      ActiveRecord::Base.connection.active?
      { status: 'healthy', latency_ms: measure_db_latency }
    rescue => e
      { status: 'unhealthy', error: e.message }
    end
    
    def check_redis_connection
      Redis.current.ping == 'PONG'
      { status: 'healthy', latency_ms: measure_redis_latency }
    rescue => e
      { status: 'unhealthy', error: e.message }
    end
    
    def check_sidekiq_status
      stats = Sidekiq::Stats.new
      {
        status: 'healthy',
        processed: stats.processed,
        failed: stats.failed,
        busy: stats.workers_size,
        enqueued: stats.enqueued,
        scheduled: stats.scheduled_size,
        retry: stats.retry_size,
        dead: stats.dead_size
      }
    rescue => e
      { status: 'unhealthy', error: e.message }
    end
    
    def check_memory_usage
      usage_mb = get_memory_usage
      max_mb = ENV.fetch('MAX_MEMORY_MB', 512).to_i
      percentage = (usage_mb.to_f / max_mb * 100).round(2)
      
      {
        used_mb: usage_mb,
        max_mb: max_mb,
        percentage: percentage,
        status: percentage > 90 ? 'critical' : (percentage > 75 ? 'warning' : 'healthy')
      }
    end
    
    def check_disk_usage
      stat = Sys::Filesystem.stat("/")
      used_bytes = stat.blocks * stat.block_size - stat.blocks_available * stat.block_size
      total_bytes = stat.blocks * stat.block_size
      percentage = (used_bytes.to_f / total_bytes * 100).round(2)
      
      {
        used_gb: (used_bytes / 1024.0 / 1024.0 / 1024.0).round(2),
        total_gb: (total_bytes / 1024.0 / 1024.0 / 1024.0).round(2),
        percentage: percentage,
        status: percentage > 90 ? 'critical' : (percentage > 80 ? 'warning' : 'healthy')
      }
    rescue => e
      { status: 'unknown', error: e.message }
    end
    
    def measure_db_latency
      start = Time.current
      ActiveRecord::Base.connection.execute("SELECT 1")
      ((Time.current - start) * 1000).round(2)
    end
    
    def measure_redis_latency
      start = Time.current
      Redis.current.ping
      ((Time.current - start) * 1000).round(2)
    end
  end
end