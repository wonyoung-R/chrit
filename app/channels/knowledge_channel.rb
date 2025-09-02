class KnowledgeChannel < ApplicationCable::Channel
  def subscribed
    if current_user
      stream_from "knowledge_#{current_user.id}"
      Rails.logger.info "User #{current_user.id} subscribed to knowledge channel"
    else
      reject
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    Rails.logger.info "User unsubscribed from knowledge channel"
  end
end