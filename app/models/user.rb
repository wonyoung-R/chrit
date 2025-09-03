class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  
  # 이메일 중심 개인 데이터 관계
  has_many :knowledges, dependent: :destroy
  has_one :user_setting, dependent: :destroy
  has_many :usage_trackings, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  
  # 사용자 생성 시 자동으로 설정 생성
  after_create :create_default_settings
  
  # 관리자 여부 확인
  def admin?
    admin == true
  end
  
  # 이메일 인증 상태 확인
  def email_verified?
    user_setting&.email_verified || false
  end
  
  # 이번 달 사용량 확인
  def current_month_usage
    current_date = Date.current
    usage_trackings.find_or_create_by(
      year: current_date.year,
      month: current_date.month
    )
  end
  
  # 크레딧 사용 가능 여부
  def can_use_credit?
    setting = user_setting || create_default_settings
    setting.used_credits < setting.monthly_credit_limit
  end
  
  # 크레딧 사용 (토큰 기반 계산)
  def use_credit!(knowledge)
    setting = user_setting || create_default_settings
    usage = current_month_usage
    
    # CreditCalculator를 사용하여 실제 크레딧 계산
    calculator = CreditCalculator.new(knowledge)
    amount = calculator.calculate
    
    ActiveRecord::Base.transaction do
      setting.increment!(:used_credits, amount)
      usage.increment!(:credits_used, amount)
      usage.increment!(:urls_processed)
      
      # Knowledge에 소비된 크레딧 저장
      knowledge.update!(credits_consumed: amount)
    end
    
    amount
  end
  
  # 월별 크레딧 리셋 (스케줄러에서 실행)
  def reset_monthly_credits!
    user_setting&.update(used_credits: 0, last_credit_reset_at: Time.current)
  end
  
  private
  
  def create_default_settings
    create_user_setting! unless user_setting
    user_setting
  end
end
