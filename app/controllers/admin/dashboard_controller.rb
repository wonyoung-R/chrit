class Admin::DashboardController < ApplicationController
  before_action :authenticate_admin!
  
  def index
    # 전체 통계
    @total_users = User.count
    @total_knowledges = Knowledge.count
    @total_subscriptions = Subscription.count
    @active_subscriptions = Subscription.active.count
    
    # 오늘 통계
    @today_users = User.where(created_at: Date.current.beginning_of_day..Date.current.end_of_day).count
    @today_knowledges = Knowledge.where(created_at: Date.current.beginning_of_day..Date.current.end_of_day).count
    @today_revenue = Subscription.where(created_at: Date.current.beginning_of_day..Date.current.end_of_day, status: 'active').sum(:amount)
    
    # 이번 달 통계
    @monthly_users = User.where(created_at: Date.current.beginning_of_month..Date.current.end_of_month).count
    @monthly_knowledges = Knowledge.where(created_at: Date.current.beginning_of_month..Date.current.end_of_month).count
    @monthly_revenue = Subscription.where(created_at: Date.current.beginning_of_month..Date.current.end_of_month, status: 'active').sum(:amount)
    
    # 플랜별 사용자 분포
    @plan_distribution = {
      free: User.joins(:user_setting).where(user_settings: { plan_type: 'free' }).count,
      pro: User.joins(:user_setting).where(user_settings: { plan_type: 'pro' }).count,
      business: User.joins(:user_setting).where(user_settings: { plan_type: 'business' }).count
    }
    
    # 콘텐츠 타입별 분포
    @content_distribution = {
      youtube: Knowledge.where(content_type: 'youtube').count,
      article: Knowledge.where(content_type: 'article').count,
      thread: Knowledge.where(content_type: 'thread').count
    }
    
    # 최근 가입 사용자
    @recent_users = User.order(created_at: :desc).limit(10)
    
    # 최근 처리된 콘텐츠
    @recent_knowledges = Knowledge.includes(:user).order(created_at: :desc).limit(10)
    
    # 처리 상태별 분포
    @processing_status = {
      completed: Knowledge.where(status: 'completed').count,
      processing: Knowledge.where(status: 'processing').count,
      failed: Knowledge.where(status: 'failed').count
    }
    
    # 크레딧 사용 통계
    @total_credits_used = UserSetting.sum(:used_credits)
    @average_credits_per_user = UserSetting.average(:used_credits)&.round(2) || 0
    
    # 시간별 처리량 (최근 24시간)
    @hourly_processing = (0..23).map do |hour|
      time = hour.hours.ago
      count = Knowledge.where(created_at: time.beginning_of_hour..time.end_of_hour).count
      { hour: time.strftime('%H:00'), count: count }
    end.reverse
    
    # 일별 가입자 수 (최근 30일)
    @daily_signups = (0..29).map do |day|
      date = day.days.ago.to_date
      count = User.where(created_at: date.beginning_of_day..date.end_of_day).count
      { date: date.strftime('%m/%d'), count: count }
    end.reverse
    
    # 에러 로그 (최근 실패한 작업)
    @recent_failures = Knowledge.where(status: 'failed').order(updated_at: :desc).limit(5)
  end
  
  def users
    @users = User.includes(:user_setting, :subscriptions)
                 .page(params[:page])
                 .per(20)
    
    # 검색 기능
    if params[:search].present?
      @users = @users.where('email LIKE ?', "%#{params[:search]}%")
    end
    
    # 플랜 필터
    if params[:plan].present?
      @users = @users.joins(:user_setting).where(user_settings: { plan_type: params[:plan] })
    end
  end
  
  def knowledges
    @knowledges = Knowledge.includes(:user)
                           .order(created_at: :desc)
                           .page(params[:page])
                           .per(20)
    
    # 상태 필터
    if params[:status].present?
      @knowledges = @knowledges.where(status: params[:status])
    end
    
    # 타입 필터
    if params[:content_type].present?
      @knowledges = @knowledges.where(content_type: params[:content_type])
    end
    
    # 날짜 필터
    if params[:date_from].present? && params[:date_to].present?
      @knowledges = @knowledges.where(created_at: params[:date_from]..params[:date_to])
    end
  end
  
  def subscriptions
    @subscriptions = Subscription.includes(:user)
                                 .order(created_at: :desc)
                                 .page(params[:page])
                                 .per(20)
    
    # 상태 필터
    if params[:status].present?
      @subscriptions = @subscriptions.where(status: params[:status])
    end
    
    # 플랜 필터
    if params[:plan].present?
      @subscriptions = @subscriptions.where(plan_type: params[:plan])
    end
  end
  
  def analytics
    # 상세 분석 페이지
    @revenue_by_month = (0..11).map do |month|
      date = month.months.ago
      revenue = Subscription.where(
        created_at: date.beginning_of_month..date.end_of_month,
        status: 'active'
      ).sum(:amount)
      { month: date.strftime('%Y-%m'), revenue: revenue }
    end.reverse
    
    @user_growth = (0..11).map do |month|
      date = month.months.ago
      count = User.where(created_at: date.beginning_of_month..date.end_of_month).count
      { month: date.strftime('%Y-%m'), count: count }
    end.reverse
    
    @content_growth = (0..11).map do |month|
      date = month.months.ago
      count = Knowledge.where(created_at: date.beginning_of_month..date.end_of_month).count
      { month: date.strftime('%Y-%m'), count: count }
    end.reverse
    
    # 토큰 사용량 통계
    @token_usage = {
      total_input: Knowledge.sum(:input_tokens),
      total_output: Knowledge.sum(:output_tokens),
      average_input: Knowledge.average(:input_tokens)&.round(0) || 0,
      average_output: Knowledge.average(:output_tokens)&.round(0) || 0
    }
    
    # API 성공률
    @api_success_rate = {
      youtube: calculate_success_rate('youtube'),
      article: calculate_success_rate('article'),
      overall: calculate_success_rate(nil)
    }
  end
  
  private
  
  def authenticate_admin!
    unless user_signed_in? && current_user.admin?
      redirect_to root_path, alert: '관리자 권한이 필요합니다.'
    end
  end
  
  def calculate_success_rate(content_type = nil)
    scope = Knowledge.all
    scope = scope.where(content_type: content_type) if content_type
    
    total = scope.count
    return 0 if total == 0
    
    completed = scope.where(status: 'completed').count
    ((completed.to_f / total) * 100).round(2)
  end
end