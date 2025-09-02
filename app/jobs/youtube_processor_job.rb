require 'concurrent'

class YoutubeProcessorJob < ApplicationJob
  queue_as :default
  
  # 재시도 설정
  retry_on StandardError, wait: :exponentially_longer, attempts: 3 do |job, error|
    knowledge = job.arguments.first
    knowledge.update(
      status: "failed",
      error_message: "처리 실패: #{error.message}"
    )
  end
  
  def perform(knowledge)
    Rails.logger.info "Starting YouTube processing for knowledge ##{knowledge.id}"
    
    # 처리 시작 시간 기록
    knowledge.update(started_at: Time.current) if knowledge.respond_to?(:started_at=)
    
    # Step 1: YouTube 메타데이터 가져오기
    youtube_service = YoutubeService.new
    video_data = youtube_service.fetch_video_data(knowledge.original_url)
    
    unless video_data[:video_id]
      raise "Invalid YouTube URL or video not found"
    end
    
    Rails.logger.info "Fetched YouTube metadata for video: #{video_data[:title]}"
    
    # Step 2: 자막/트랜스크립트 가져오기 (Gemini 사용하지 않음)
    transcript = fetch_transcript_improved(video_data[:video_id])
    
    # Step 3: 콘텐츠 분석 (Gemini 또는 Anthropic)
    analysis_result = if transcript.present? && transcript.length > 100
      Rails.logger.info "Analyzing transcript (#{transcript.length} characters)"
      analyze_with_ai(transcript, video_data)
    else
      Rails.logger.info "Using fallback content for analysis"
      fallback_content = build_fallback_content(video_data)
      analyze_with_ai(fallback_content, video_data)
    end
    
    # Step 4: 결과 저장
    save_knowledge(knowledge, video_data, transcript, analysis_result)
    
    Rails.logger.info "Successfully processed knowledge ##{knowledge.id} in #{processing_time(knowledge)} seconds"
    
    # 처리 완료 알림
    broadcast_completion(knowledge)
    
  rescue StandardError => e
    Rails.logger.error "YoutubeProcessorJob Error for knowledge ##{knowledge.id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    # 에러 정보 저장
    knowledge.update(
      status: "failed",
      error_message: "YouTube 처리 중 오류: #{e.message}",
      completed_at: Time.current
    )
    
    raise # 재시도를 위해 에러를 다시 발생
  end
  
  private
  
  # 개선된 자막 추출 (Gemini 제외)
  def fetch_transcript_improved(video_id)
    youtube_service = YoutubeService.new
    
    # 방법 1: YouTube API v3로 캡션 트랙 확인
    transcript = youtube_service.fetch_captions_via_api(video_id)
    if transcript.present? && transcript != "이 비디오의 자막을 가져올 수 없습니다."
      Rails.logger.info "Successfully fetched transcript via YouTube API"
      return transcript
    end
    
    # 방법 2: HTTP 요청으로 자막 추출
    transcript = youtube_service.fetch_transcript_via_gem(video_id)
    if transcript.present?
      Rails.logger.info "Successfully fetched transcript via HTTP"
      return transcript
    end
    
    # 방법 3: 웹 스크래핑 (최후의 수단)
    transcript = youtube_service.fetch_transcript_via_scraping(video_id)
    if transcript.present?
      Rails.logger.info "Successfully fetched transcript via scraping"
      return transcript
    end
    
    Rails.logger.warn "Failed to fetch transcript for video #{video_id}"
    nil
  end
  
  # AI로 콘텐츠 분석 (Gemini 우선, Anthropic 폴백)
  def analyze_with_ai(content, video_data)
    # Gemini로 먼저 시도
    begin
      gemini_service = GeminiService.new
      
      # 트랜스크립트와 메타데이터를 함께 전달
      result = gemini_service.analyze_youtube_transcript(
        content,
        {
          title: video_data[:title],
          channel: video_data[:channel],
          duration: video_data[:duration],
          description: video_data[:description]
        }
      )
      
      if result
        Rails.logger.info "Content analyzed with Gemini successfully"
        return {
          summary: result[:summary],
          keywords: result[:keywords],
          main_points: result[:main_points],
          content: result[:content],
          target_audience: result[:target_audience],
          ai_service: 'gemini'
        }
      end
    rescue => e
      Rails.logger.warn "Gemini analysis failed: #{e.message}"
    end
    
    # Anthropic으로 폴백
    Rails.logger.info "Falling back to Anthropic for analysis"
    ai_result = AiSummarizer.new.summarize(
      content: content,
      type: "youtube_video",
      metadata: video_data
    )
    
    {
      summary: ai_result[:summary],
      keywords: ai_result[:keywords],
      main_points: ai_result[:main_points],
      content: content,
      ai_service: 'anthropic'
    }
  end
  
  # 결과 저장
  def save_knowledge(knowledge, video_data, transcript, analysis_result)
    # YouTube 태그와 AI 키워드 병합
    youtube_keywords = (video_data[:tags] || []).first(3) + (video_data[:topics] || [])
    ai_keywords = analysis_result[:keywords] || []
    combined_keywords = (youtube_keywords + ai_keywords).uniq.first(7)
    
    knowledge.update!(
      title: video_data[:title],
      content: analysis_result[:content] || transcript || build_fallback_content(video_data),
      summary: analysis_result[:summary] || "요약 생성 실패",
      keywords: combined_keywords.to_json,
      content_type: "youtube",
      metadata: video_data.merge(
        ai_service: analysis_result[:ai_service],
        target_audience: analysis_result[:target_audience],
        main_points: analysis_result[:main_points],
        transcript_available: transcript.present?
      ),
      thumbnail_url: video_data[:thumbnail],
      duration: video_data[:duration],
      published_at: video_data[:published_at],
      status: "completed",
      completed_at: Time.current,
      error_message: nil
    )
  end
  
  def build_fallback_content(video_data)
    content = []
    
    content << "제목: #{video_data[:title]}" if video_data[:title].present?
    content << "채널: #{video_data[:channel]}" if video_data[:channel].present?
    content << "설명: #{video_data[:description]}" if video_data[:description].present?
    
    if video_data[:tags].present? && video_data[:tags].any?
      content << "태그: #{video_data[:tags].join(', ')}"
    end
    
    if video_data[:topics].present? && video_data[:topics].any?
      content << "주제: #{video_data[:topics].join(', ')}"
    end
    
    content << "게시일: #{video_data[:published_at]}" if video_data[:published_at].present?
    
    # 비디오 길이 정보
    if video_data[:duration].present?
      duration_min = video_data[:duration] / 60
      content << "재생 시간: #{duration_min}분"
    end
    
    content.join("\n\n")
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
        processing_time: processing_time(knowledge)
      }
    ) if defined?(ActionCable)
  rescue => e
    Rails.logger.error "Failed to broadcast completion: #{e.message}"
  end
end