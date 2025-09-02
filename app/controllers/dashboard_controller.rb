class DashboardController < ApplicationController
  before_action :authenticate_user!, except: [:index]
  
  def index
    if user_signed_in?
      @recent_knowledges = current_user.knowledges.recent.limit(10)
      @total_knowledges = current_user.knowledges.count
      @youtube_count = current_user.knowledges.where(content_type: 'youtube').count
      @article_count = current_user.knowledges.where(content_type: 'article').count
      @thread_count = current_user.knowledges.where(content_type: 'thread').count
      @this_month_count = current_user.knowledges.where(created_at: Time.current.beginning_of_month..Time.current).count
      @popular_tags = Tag.popular
    else
      @recent_knowledges = []
      @popular_tags = Tag.popular
    end
  end
end
