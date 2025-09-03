require_relative 'content_validator'
require_relative 'processing_logger'

class ArticleProcessorJob < ApplicationJob
  include ContentValidator
  include ProcessingLogger
  queue_as :default
  
  # 재시도 설정 - 5초 간격으로 재시도
  retry_on StandardError, wait: 5.seconds, attempts: 3 do |job, error|
    knowledge = job.arguments.first
    knowledge.update(
      status: "failed",
      error_message: "처리 실패: #{error.message}"
    )
  end
  
  def perform(knowledge)
    Rails.logger.info "Starting article processing for knowledge ##{knowledge.id}"
    
    # 처리 시작 시간 기록
    knowledge.update(started_at: Time.current) if knowledge.respond_to?(:started_at=)
    
    # Step 1: 기사 내용 추출 (특수 추출기 포함)
    article_data = ArticleExtractor.new.extract(knowledge.original_url)
    
    unless article_data[:content].present?
      raise "Failed to extract article content from #{knowledge.original_url}"
    end
    
    Rails.logger.info "Extracted article content: #{article_data[:title]} (#{article_data[:content].length} characters)"
    
    # Step 2: AI로 요약 및 키워드 추출 (Gemini 우선, Anthropic 폴백)
    ai_result = analyze_article_with_ai(article_data)
    
    # Step 3: 결과 저장
    save_article_knowledge(knowledge, article_data, ai_result)
    
    Rails.logger.info "Successfully processed article knowledge ##{knowledge.id} in #{processing_time(knowledge)} seconds"
    
    # 처리 완료 알림
    broadcast_completion(knowledge)
    
  rescue StandardError => e
    Rails.logger.error "ArticleProcessorJob Error for knowledge ##{knowledge.id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    # 에러 정보 저장
    knowledge.update(
      status: "failed",
      error_message: "기사 처리 중 오류: #{e.message}",
      completed_at: Time.current
    )
    
    raise # 재시도를 위해 에러를 다시 발생
  end
  
  private
  
  def analyze_article_with_ai(article_data)
    content = article_data[:content]
    metadata = article_data[:metadata] || {}
    
    # Gemini로 먼저 시도
    begin
      gemini_service = GeminiService.new
      
      # Article 콘텐츠 분석
      result = gemini_service.analyze_article_content(
        content,
        {
          url: metadata[:url],
          title: article_data[:title],
          author: metadata[:author],
          published_date: metadata[:published_date]
        }
      )
      
      if result
        Rails.logger.info "Article analyzed with Gemini successfully"
        return {
          summary: result[:summary],
          keywords: result[:keywords],
          main_points: result[:main_points],
          topic: result[:topic],
          usefulness: result[:usefulness],
          ai_service: 'gemini'
        }
      end
    rescue => e
      Rails.logger.warn "Gemini analysis failed: #{e.message}"
    end
    
    # Anthropic으로 폴백
    Rails.logger.info "Falling back to Anthropic for article analysis"
    ai_result = AiSummarizer.new.summarize(
      content: content,
      type: "article",
      metadata: metadata
    )
    
    {
      summary: ai_result[:summary],
      keywords: ai_result[:keywords],
      main_points: ai_result[:main_points],
      ai_service: 'anthropic'
    }
  end
  
  def save_article_knowledge(knowledge, article_data, ai_result)
    # 메타데이터에서 추출한 키워드와 AI 키워드 병합
    metadata_keywords = extract_metadata_keywords(article_data[:metadata])
    ai_keywords = ai_result[:keywords] || []
    combined_keywords = (metadata_keywords + ai_keywords).uniq.first(7)
    
    # 메타데이터 업데이트
    enhanced_metadata = (article_data[:metadata] || {}).merge(
      ai_service: ai_result[:ai_service],
      topic: ai_result[:topic],
      usefulness: ai_result[:usefulness],
      main_points: ai_result[:main_points],
      extraction_type: detect_extraction_type(article_data[:metadata])
    )
    
    knowledge.update!(
      title: article_data[:title] || "제목 없음",
      content: article_data[:content],
      summary: ai_result[:summary] || "요약 생성 실패",
      keywords: combined_keywords.to_json,
      content_type: "article",
      metadata: enhanced_metadata,
      thumbnail_url: article_data[:image],
      published_at: extract_published_date(article_data[:metadata]),
      status: "completed",
      completed_at: Time.current,
      error_message: nil,
      # 토큰 정보 저장
      input_tokens: ai_result[:input_tokens] || 0,
      output_tokens: ai_result[:output_tokens] || 0
    )
    
    # 크레딧 계산 및 차감
    if knowledge.user
      credits_used = knowledge.user.use_credit!(knowledge)
      Rails.logger.info "Article processing used #{credits_used} credits (#{knowledge.input_tokens} input, #{knowledge.output_tokens} output tokens)"
    end
  end
  
  def extract_metadata_keywords(metadata)
    return [] unless metadata
    
    keywords = []
    
    # metadata[:keywords]에서 추출
    if metadata[:keywords].present?
      keywords += metadata[:keywords].split(',').map(&:strip)
    end
    
    # metadata[:tags]에서 추출
    if metadata[:tags].present? && metadata[:tags].is_a?(Array)
      keywords += metadata[:tags]
    end
    
    keywords.uniq.first(3)
  end
  
  def detect_extraction_type(metadata)
    return 'unknown' unless metadata
    
    case metadata[:type]
    when 'documentation'
      'documentation'
    when 'github_repository', 'github_file', 'github_issue', 'github_pull_request', 'github_gist'
      'github'
    else
      case metadata[:platform]
      when 'Medium', 'Dev.to', 'Hashnode', 'WordPress', 'Ghost', 'Substack', 'Blogger'
        'blog'
      else
        'article'
      end
    end
  end
  
  def extract_published_date(metadata)
    return nil unless metadata
    
    date = metadata[:published_date] || metadata[:created_at] || metadata[:updated_at]
    
    case date
    when String
      Date.parse(date) rescue nil
    when Date, DateTime, Time
      date
    else
      nil
    end
  end
  
  def processing_time(knowledge)
    return 0 unless knowledge.respond_to?(:started_at) && knowledge.started_at
    
    completed_at = knowledge.respond_to?(:completed_at) ? knowledge.completed_at : Time.current
    (completed_at - knowledge.started_at).round(2)
  end
  
  def broadcast_completion(knowledge)
    # Action Cable로 실시간 업데이트 전송
    ActionCable.server.broadcast(
      "knowledge_#{knowledge.user_id}",
      {
        type: 'knowledge_completed',
        knowledge_id: knowledge.id,
        title: knowledge.title,
        summary: knowledge.summary,
        content_type: 'article',
        processing_time: processing_time(knowledge)
      }
    ) if defined?(ActionCable)
  rescue => e
    Rails.logger.error "Failed to broadcast completion: #{e.message}"
  end
end