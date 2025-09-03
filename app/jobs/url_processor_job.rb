class UrlProcessorJob < ApplicationJob
  queue_as :default
  
  # 재시도 설정: 지수 백오프로 최대 3회 재시도
  retry_on StandardError, wait: :exponentially_longer, attempts: 3 do |job, error|
    knowledge = job.arguments.first
    knowledge.update(
      status: "failed",
      error_message: "처리 실패: #{error.message}"
    )
  end
  
  def perform(knowledge)
    # URL 타입을 자동 감지
    detector = UrlDetector.new(knowledge.original_url)
    
    # 처리 시작 시간을 기록
    knowledge.update(started_at: Time.current) if knowledge.respond_to?(:started_at=)
    
    # 비동기로 서브 작업을 실행
    if detector.youtube?
      YoutubeProcessorJob.perform_later(knowledge)
    else
      ArticleProcessorJob.perform_later(knowledge)
    end
    
    Rails.logger.info "Dispatched processing job for knowledge ##{knowledge.id}"
  rescue StandardError => e
    Rails.logger.error "UrlProcessorJob Error: #{e.message}"
    knowledge.update(
      status: "failed",
      error_message: "URL 처리 오류: #{e.message}"
    )
  end
end