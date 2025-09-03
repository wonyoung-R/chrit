class DashboardController < ApplicationController
  before_action :authenticate_user!, except: [:index]
  
  def index
    if user_signed_in?
      @recent_knowledges = current_user.knowledges.includes(:tags, :knowledge_tags).recent.limit(10)
      @total_knowledges = current_user.knowledges.count
      @youtube_count = current_user.knowledges.where(content_type: 'youtube').count
      @article_count = current_user.knowledges.where(content_type: 'article').count
      @thread_count = current_user.knowledges.where(content_type: 'thread').count
      @this_month_count = current_user.knowledges.where(created_at: Time.current.beginning_of_month..Time.current).count
      @popular_tags = Tag.popular
      
      # 이메일 기반 사용량 추적
      @user_setting = current_user.user_setting || current_user.create_user_setting!
      @current_usage = current_user.current_month_usage
      @credits_remaining = @user_setting.monthly_credit_limit - @user_setting.used_credits
      @email_verified = current_user.email_verified?
      
      # 구독 정보
      @active_subscription = current_user.subscriptions.active.first
      @plan_type = @user_setting.plan_type || 'free'
    else
      @recent_knowledges = []
      @popular_tags = Tag.popular
    end
  end
end
