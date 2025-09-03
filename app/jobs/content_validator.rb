# Iteration 3: Content validation module for enhanced reliability
module ContentValidator
  extend ActiveSupport::Concern
  
  # Validate that extracted content is meaningful
  def validate_content(content, min_length: 100)
    return false if content.blank?
    return false if content.length < min_length
    
    # Check if content is not just repeated characters or garbage
    unique_chars = content.chars.uniq.length
    return false if unique_chars < 10
    
    # Check if content has some structure (words)
    words = content.split(/\s+/)
    return false if words.length < 10
    
    # Check for common extraction failures
    error_patterns = [
      /^\s*error/i,
      /^\s*404/,
      /^\s*not found/i,
      /^\s*access denied/i,
      /^\s*forbidden/i,
      /^\s*please enable javascript/i,
      /^\s*cookies must be enabled/i
    ]
    
    error_patterns.each do |pattern|
      return false if content.match?(pattern)
    end
    
    true
  end
  
  # Validate summary quality
  def validate_summary(summary, content)
    return false if summary.blank?
    return false if summary.length < 50
    return false if summary.length > content.length # Summary shouldn't be longer than content
    
    # Check if summary is not just a copy of the beginning
    return false if content.start_with?(summary)
    
    true
  end
  
  # Log validation results for debugging
  def log_validation_result(knowledge, content, summary)
    Rails.logger.info "Content Validation for Knowledge ##{knowledge.id}:"
    Rails.logger.info "  URL: #{knowledge.original_url}"
    Rails.logger.info "  Content present: #{content.present?}"
    Rails.logger.info "  Content length: #{content&.length || 0}"
    Rails.logger.info "  Content valid: #{validate_content(content)}"
    Rails.logger.info "  Summary present: #{summary.present?}"
    Rails.logger.info "  Summary length: #{summary&.length || 0}"
    Rails.logger.info "  Summary valid: #{validate_summary(summary, content || '')}"
  end
  
  # Enhanced content saving with validation
  def save_with_validation(knowledge, content, summary, additional_fields = {})
    # Validate content
    unless validate_content(content)
      Rails.logger.warn "Invalid content detected for Knowledge ##{knowledge.id}"
      
      # Try to use fallback content if available
      if additional_fields[:fallback_content].present?
        content = additional_fields[:fallback_content]
        Rails.logger.info "Using fallback content for Knowledge ##{knowledge.id}"
      else
        raise "Content validation failed and no fallback available"
      end
    end
    
    # Validate summary
    unless validate_summary(summary, content)
      Rails.logger.warn "Invalid summary detected for Knowledge ##{knowledge.id}"
      summary = "요약 생성 중 문제가 발생했습니다. 콘텐츠를 직접 확인해주세요."
    end
    
    # Log validation results
    log_validation_result(knowledge, content, summary)
    
    # Save with all fields
    knowledge.update!(
      content: content,
      summary: summary,
      status: "completed",
      completed_at: Time.current,
      error_message: nil,
      **additional_fields.except(:fallback_content)
    )
    
    Rails.logger.info "Successfully saved validated content for Knowledge ##{knowledge.id}"
  end
end