class UserSettingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user_setting

  def show
    # 사용자 설정 페이지 표시
  end

  def edit
    # 설정 편집 페이지
  end

  def update
    if @user_setting.update(user_setting_params)
      redirect_to user_settings_path, notice: "설정이 성공적으로 업데이트되었습니다."
    else
      render :edit
    end
  end

  def send_verification_email
    if current_user.email_verified?
      redirect_to user_settings_path, alert: "이미 이메일이 인증되었습니다."
    else
      UserMailer.email_verification(current_user).deliver_later
      redirect_to user_settings_path, notice: "인증 이메일이 발송되었습니다. 이메일을 확인해주세요."
    end
  end

  def verify_email
    token = params[:token]
    user_setting = UserSetting.find_by(verification_token: token)
    
    if user_setting && !user_setting.email_verified
      user_setting.update(
        email_verified: true,
        email_verified_at: Time.current,
        verification_token: nil
      )
      redirect_to root_path, notice: "이메일이 성공적으로 인증되었습니다!"
    else
      redirect_to root_path, alert: "유효하지 않은 인증 토큰입니다."
    end
  end

  private

  def set_user_setting
    @user_setting = current_user.user_setting || current_user.create_user_setting!
  end

  def user_setting_params
    params.require(:user_setting).permit(
      :email_notifications,
      :privacy_mode,
      :language,
      :timezone,
      :theme,
      :monthly_credit_limit
    )
  end
end