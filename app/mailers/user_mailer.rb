class UserMailer < ApplicationMailer
  default from: 'noreply@chrit.app'

  def email_verification(user)
    @user = user
    @user_setting = user.user_setting || user.create_user_setting!
    
    # 인증 토큰 생성
    if @user_setting.verification_token.blank?
      @user_setting.update(verification_token: SecureRandom.urlsafe_base64(32))
    end
    
    @verification_url = verify_email_user_settings_url(token: @user_setting.verification_token)
    
    mail(
      to: @user.email,
      subject: '[Chrit] 이메일 인증을 완료해주세요'
    )
  end

  def monthly_credit_reset(user)
    @user = user
    @user_setting = user.user_setting
    
    mail(
      to: @user.email,
      subject: '[Chrit] 월간 크레딧이 리셋되었습니다'
    )
  end

  def credit_limit_warning(user)
    @user = user
    @user_setting = user.user_setting
    @credits_remaining = @user_setting.monthly_credit_limit - @user_setting.used_credits
    
    mail(
      to: @user.email,
      subject: '[Chrit] 크레딧 사용량 경고'
    )
  end
end