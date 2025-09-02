class KnowledgesController < ApplicationController
  before_action :authenticate_user!
  
  def create
    # 기존 URL 체크
    existing_knowledge = current_user.knowledges.find_by(original_url: params[:url])
    
    if existing_knowledge
      # 이미 처리된 URL인 경우
      if existing_knowledge.completed?
        # 완료된 경우 해당 knowledge 보여주기
        redirect_to knowledge_path(existing_knowledge), notice: "이미 처리된 URL입니다."
        return
      elsif existing_knowledge.processing?
        # 처리 중인 경우 알림
        redirect_to root_path, alert: "해당 URL은 현재 처리 중입니다."
        return
      elsif existing_knowledge.status == "failed"
        # 실패한 경우 재시도
        existing_knowledge.update(status: "processing")
        UrlProcessorJob.perform_later(existing_knowledge)
        redirect_to root_path, notice: "처리를 재시도합니다."
        return
      end
    end
    
    @knowledge = current_user.knowledges.build(
      original_url: params[:url],
      status: "processing"
    )
    
    if @knowledge.save
      UrlProcessorJob.perform_later(@knowledge)
      
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.prepend("recent-knowledges", 
              partial: "knowledges/card", 
              locals: { knowledge: @knowledge }),
            turbo_stream.replace("processing-status",
              partial: "shared/processing_alert")
          ]
        end
        format.html { redirect_to root_path }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "form-errors",
            partial: "shared/errors",
            locals: { errors: @knowledge.errors.full_messages }
          )
        end
        format.html { redirect_to root_path, alert: "エラーが発生しました" }
      end
    end
  end

  def show
    @knowledge = current_user.knowledges.find(params[:id])
  end
  
  def retry
    @knowledge = current_user.knowledges.find(params[:id])
    
    if @knowledge.status == "failed"
      @knowledge.update(status: "processing", error_message: nil)
      UrlProcessorJob.perform_later(@knowledge)
      redirect_to knowledge_path(@knowledge), notice: "처리를 재시도합니다."
    else
      redirect_to knowledge_path(@knowledge), alert: "재시도할 수 없는 상태입니다."
    end
  end
end
