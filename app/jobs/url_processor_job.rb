class UrlProcessorJob < ApplicationJob
  queue_as :default
  
  def perform(knowledge)
    # URL タイプを自動検知
    detector = UrlDetector.new(knowledge.original_url)
    
    # 処理開始時間を記録
    knowledge.update(started_at: Time.current) if knowledge.respond_to?(:started_at=)
    
    # 非同期でサブジョブを実行
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
      error_message: "URL処理エラー: #{e.message}"
    )
  end
end