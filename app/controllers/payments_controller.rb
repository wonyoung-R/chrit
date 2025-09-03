class PaymentsController < ApplicationController
  before_action :authenticate_user!
  
  # 결제 페이지
  def new
    @subscription = current_user.subscriptions.build
    @plan = params[:plan] || 'pro'
    @plan_info = Subscription::PLAN_TYPES[@plan.to_sym]
    
    unless @plan_info
      redirect_to dashboard_path, alert: '잘못된 플랜입니다.'
      return
    end
  end
  
  # 토스 페이먼츠 결제 초기화
  def create
    plan = params[:plan] || 'pro'
    plan_info = Subscription::PLAN_TYPES[plan.to_sym]
    
    unless plan_info
      render json: { error: '잘못된 플랜입니다.' }, status: :bad_request
      return
    end
    
    # 중복 구독 체크
    if current_user.subscriptions.active.exists?
      render json: { error: '이미 활성 구독이 있습니다.' }, status: :bad_request
      return
    end
    
    # 구독 생성
    subscription = current_user.subscriptions.create!(
      plan_type: plan,
      amount: plan_info[:price],
      status: 'pending',
      toss_order_id: "ORDER_#{current_user.id}_#{Time.now.to_i}"
    )
    
    # 토스 페이먼츠 결제 정보 반환
    render json: {
      success: true,
      orderId: subscription.toss_order_id,
      orderName: "#{plan_info[:name]} 플랜 구독",
      amount: plan_info[:price],
      customerEmail: current_user.email,
      customerName: current_user.email.split('@').first,
      successUrl: payment_success_url,
      failUrl: payment_fail_url
    }
  rescue => e
    Rails.logger.error "Payment creation error: #{e.message}"
    render json: { error: '결제 초기화 중 오류가 발생했습니다.' }, status: :internal_server_error
  end
  
  # 결제 성공 콜백
  def success
    payment_key = params[:paymentKey]
    order_id = params[:orderId]
    amount = params[:amount].to_i
    
    # 구독 찾기
    subscription = current_user.subscriptions.find_by(toss_order_id: order_id)
    
    unless subscription
      redirect_to dashboard_path, alert: '구독을 찾을 수 없습니다.'
      return
    end
    
    # 토스 페이먼츠 결제 확인 API 호출
    if confirm_payment(payment_key, order_id, amount)
      # 구독 활성화
      subscription.update!(
        toss_payment_key: payment_key,
        payment_method: 'card'
      )
      subscription.activate!
      
      redirect_to dashboard_path, notice: "#{subscription.plan_type.capitalize} 플랜 구독이 완료되었습니다!"
    else
      subscription.update!(status: 'failed')
      redirect_to dashboard_path, alert: '결제 확인 중 오류가 발생했습니다.'
    end
  rescue => e
    Rails.logger.error "Payment success error: #{e.message}"
    redirect_to dashboard_path, alert: '결제 처리 중 오류가 발생했습니다.'
  end
  
  # 결제 실패 콜백
  def fail
    code = params[:code]
    message = params[:message]
    order_id = params[:orderId]
    
    # 구독 상태 업데이트
    if order_id
      subscription = current_user.subscriptions.find_by(toss_order_id: order_id)
      subscription&.update!(status: 'failed', error_message: "#{code}: #{message}")
    end
    
    redirect_to dashboard_path, alert: "결제가 실패했습니다: #{message}"
  end
  
  # 구독 취소
  def cancel
    subscription = current_user.subscriptions.active.first
    
    unless subscription
      redirect_to dashboard_path, alert: '활성 구독이 없습니다.'
      return
    end
    
    subscription.cancel!
    redirect_to dashboard_path, notice: '구독이 취소되었습니다.'
  end
  
  private
  
  # 토스 페이먼츠 결제 확인 API
  def confirm_payment(payment_key, order_id, amount)
    require 'net/http'
    require 'json'
    require 'base64'
    
    # 테스트 시크릿 키 (실제 운영시 환경변수로 관리)
    secret_key = ENV['TOSS_SECRET_KEY'] || 'test_sk_test_secret_key_placeholder'
    
    uri = URI('https://api.tosspayments.com/v1/payments/confirm')
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(uri.path)
    request['Authorization'] = "Basic #{Base64.strict_encode64(secret_key + ':')}"
    request['Content-Type'] = 'application/json'
    
    request.body = {
      paymentKey: payment_key,
      orderId: order_id,
      amount: amount
    }.to_json
    
    response = http.request(request)
    
    if response.code == '200'
      payment_data = JSON.parse(response.body)
      Rails.logger.info "Payment confirmed: #{payment_data}"
      return true
    else
      Rails.logger.error "Payment confirmation failed: #{response.body}"
      return false
    end
  rescue => e
    Rails.logger.error "Payment confirmation error: #{e.message}"
    return false
  end
end