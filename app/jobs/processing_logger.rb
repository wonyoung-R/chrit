# Iteration 4: Comprehensive logging for content processing
module ProcessingLogger
  extend ActiveSupport::Concern
  
  def log_processing_start(knowledge)
    Rails.logger.info "=" * 60
    Rails.logger.info "Starting content processing for Knowledge ##{knowledge.id}"
    Rails.logger.info "URL: #{knowledge.original_url}"
    Rails.logger.info "User: #{knowledge.user.email}"
    Rails.logger.info "Type: #{detect_content_type(knowledge.original_url)}"
    Rails.logger.info "Started at: #{Time.current}"
    Rails.logger.info "=" * 60
  end
  
  def log_extraction_result(stage, success, data = {})
    status = success ? "✓ SUCCESS" : "✗ FAILED"
    Rails.logger.info "[#{stage}] #{status}"
    
    data.each do |key, value|
      if value.is_a?(String) && value.length > 100
        Rails.logger.info "  #{key}: #{value.length} characters"
      else
        Rails.logger.info "  #{key}: #{value}"
      end
    end
  end
  
  def log_ai_processing(service, input_length, output_length, success)
    Rails.logger.info "[AI Processing - #{service}]"
    Rails.logger.info "  Input: #{input_length} characters"
    Rails.logger.info "  Output: #{output_length} characters"
    Rails.logger.info "  Status: #{success ? '✓ SUCCESS' : '✗ FAILED'}"
  end
  
  def log_processing_complete(knowledge, processing_time)
    Rails.logger.info "=" * 60
    Rails.logger.info "Processing complete for Knowledge ##{knowledge.id}"
    Rails.logger.info "Status: #{knowledge.status}"
    Rails.logger.info "Processing time: #{processing_time} seconds"
    
    if knowledge.content.present?
      Rails.logger.info "Content saved: ✓ (#{knowledge.content.length} characters)"
    else
      Rails.logger.error "Content saved: ✗ NO CONTENT"
    end
    
    if knowledge.summary.present?
      Rails.logger.info "Summary saved: ✓ (#{knowledge.summary.length} characters)"
    else
      Rails.logger.error "Summary saved: ✗ NO SUMMARY"
    end
    
    Rails.logger.info "=" * 60
  end
  
  def log_error(knowledge, error)
    Rails.logger.error "!" * 60
    Rails.logger.error "ERROR processing Knowledge ##{knowledge.id}"
    Rails.logger.error "URL: #{knowledge.original_url}"
    Rails.logger.error "Error: #{error.class} - #{error.message}"
    Rails.logger.error "Backtrace:"
    Rails.logger.error error.backtrace.first(10).join("\n")
    Rails.logger.error "!" * 60
  end
  
  private
  
  def detect_content_type(url)
    case url
    when /youtube\.com|youtu\.be/i
      "YouTube Video"
    when /medium\.com/i
      "Medium Article"
    when /dev\.to/i
      "Dev.to Article"
    when /github\.com/i
      "GitHub Content"
    else
      "Web Article"
    end
  end
end