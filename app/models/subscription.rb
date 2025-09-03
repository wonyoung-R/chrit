class Subscription < ApplicationRecord
  belongs_to :user
  
  # 상태
  STATUSES = {
    pending: 'pending',      # 결제 대기
    active: 'active',        # 활성 구독
    expired: 'expired',      # 만료됨
    cancelled: 'cancelled',  # 취소됨
    failed: 'failed'         # 결제 실패
  }.freeze
  
  # 플랜 타입
  PLAN_TYPES = {
    free: { name: 'Free', credits: 10, price: 0 },
    pro: { name: 'Pro', credits: 100, price: 7900 },
    business: { name: 'Business', credits: 500, price: 29900 }
  }.freeze
  
  # 스코프
  scope :active, -> { where(status: 'active') }
  scope :expired, -> { where('expires_at < ?', Time.current) }
  
  # 유효성 검사
  validates :plan_type, presence: true, inclusion: { in: PLAN_TYPES.keys.map(&:to_s) }
  validates :status, presence: true, inclusion: { in: STATUSES.values }
  
  # 콜백
  after_create :apply_subscription_benefits
  
  # 활성 구독인지 확인
  def active?
    status == 'active' && (expires_at.nil? || expires_at > Time.current)
  end
  
  # 구독 활성화
  def activate!
    ActiveRecord::Base.transaction do
      update!(
        status: 'active',
        started_at: Time.current,
        expires_at: 1.month.from_now
      )
      apply_subscription_benefits
    end
  end
  
  # 구독 취소
  def cancel!
    update!(status: 'cancelled')
  end
  
  # 구독 갱신
  def renew!
    update!(
      expires_at: expires_at + 1.month,
      status: 'active'
    )
  end
  
  private
  
  # 구독 혜택 적용
  def apply_subscription_benefits
    return unless active?
    
    plan_info = PLAN_TYPES[plan_type.to_sym]
    return unless plan_info
    
    # 사용자 설정 업데이트
    user.user_setting.update!(
      monthly_credit_limit: plan_info[:credits],
      plan_type: plan_type
    )
    
    Rails.logger.info "Applied #{plan_type} subscription benefits to user #{user.id}"
  end
end