class KnowledgesController < ApplicationController
  before_action :authenticate_user!
  
  def create
    Rails.logger.info "=== KnowledgesController#create called ==="
    Rails.logger.info "Params: #{params.inspect}"
    Rails.logger.info "Current user: #{current_user.id} - #{current_user.email}"
    
    # 크레딧 사용 가능 여부 체크
    unless current_user.can_use_credit?
      redirect_to root_path, alert: "이번 달 크레딧을 모두 사용하셨습니다. 다음 달에 다시 이용해주세요."
      return
    end
    
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
        # 실패한 경우 재시도 (크레딧 차감)
        current_user.use_credit!
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
    
    Rails.logger.info "Building knowledge: #{@knowledge.inspect}"
    
    if @knowledge.save
      Rails.logger.info "Knowledge saved successfully with ID: #{@knowledge.id}"
      
      # 크레딧 차감
      current_user.use_credit!
      
      UrlProcessorJob.perform_later(@knowledge)
      
      # Always redirect to dashboard after save
      redirect_to dashboard_path, notice: "지식이 저장되었습니다. 처리 중입니다..."
    else
      Rails.logger.error "Failed to save knowledge: #{@knowledge.errors.full_messages.join(', ')}"
      redirect_to root_path, alert: @knowledge.errors.full_messages.join(", ")
    end
  end

  def show
    @knowledge = current_user.knowledges.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to dashboard_path, alert: "요청하신 항목을 찾을 수 없습니다."
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
  
  def destroy
    @knowledge = current_user.knowledges.find(params[:id])
    @knowledge.destroy
    redirect_to dashboard_path, notice: "항목이 삭제되었습니다."
  rescue ActiveRecord::RecordNotFound
    redirect_to dashboard_path, alert: "삭제할 항목을 찾을 수 없습니다."
  end
end
