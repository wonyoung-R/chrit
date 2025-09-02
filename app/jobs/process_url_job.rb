class ProcessUrlJob < ApplicationJob
  queue_as :default

  def perform(knowledge_id)
    knowledge = Knowledge.find(knowledge_id)
    
    # Update status to processing
    knowledge.update!(status: 'processing')
    
    # Process the URL
    processor = UrlProcessorService.new(knowledge.original_url)
    result = processor.process
    
    if result[:error]
      knowledge.update!(
        status: 'failed',
        error_message: result[:error]
      )
    else
      # Update knowledge with processed data
      knowledge.update!(
        title: result[:title],
        summary: result[:summary],
        keywords: result[:keywords].to_json,
        thumbnail_url: result[:thumbnail_url] || result[:image_url],
        status: 'completed',
        processed_at: Time.current
      )
      
      # Extract and save tags
      extract_and_save_tags(knowledge, result[:keywords])
    end
  rescue StandardError => e
    knowledge.update!(
      status: 'failed',
      error_message: e.message
    )
    raise # Re-raise for job retry mechanism
  end

  private

  def extract_and_save_tags(knowledge, keywords)
    keywords.each do |keyword|
      # Remove # from keyword
      tag_name = keyword.gsub('#', '')
      
      # Find or create tag
      tag = Tag.find_or_create_by(name: tag_name)
      
      # Increment count
      tag.increment!(:count)
      
      # Create association
      knowledge.knowledge_tags.find_or_create_by(tag: tag)
    end
  end
end