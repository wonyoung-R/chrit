class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  before_action :configure_permitted_parameters, if: :devise_controller?
  
  rescue_from ErrorHandler::ChritError do |error|
    handle_chrit_error(error)
  end
  
  rescue_from ActiveRecord::RecordNotFound do |error|
    handle_not_found_error(error)
  end
  
  rescue_from StandardError do |error|
    handle_standard_error(error)
  end
  
  protected
  
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end
  
  # 로그인 후 대시보드로 리다이렉션
  def after_sign_in_path_for(resource)
    dashboard_path
  end
  
  # 로그아웃 후 홈으로 리다이렉션
  def after_sign_out_path_for(resource_or_scope)
    root_path
  end
  
  private
  
  def handle_chrit_error(error)
    ApplicationLogger.log_security_event(
      'error_handled',
      {
        error_code: error.code,
        user_id: current_user&.id,
        ip_address: request.remote_ip
      }
    )
    
    respond_to do |format|
      format.html do
        flash[:alert] = error.user_message
        redirect_back(fallback_location: root_path)
      end
      format.json do
        render json: {
          error: {
            code: error.code,
            message: error.user_message
          }
        }, status: error_status_code(error.code)
      end
    end
  end
  
  def handle_not_found_error(error)
    respond_to do |format|
      format.html do
        flash[:alert] = "요청한 리소스를 찾을 수 없습니다."
        redirect_to root_path
      end
      format.json do
        render json: {
          error: {
            code: 404,
            message: "리소스를 찾을 수 없습니다."
          }
        }, status: :not_found
      end
    end
  end
  
  def handle_standard_error(error)
    ApplicationLogger.log_security_event(
      'unhandled_error',
      {
        error_class: error.class.name,
        error_message: error.message,
        user_id: current_user&.id,
        ip_address: request.remote_ip,
        backtrace: error.backtrace&.first(5)
      }
    )
    
    respond_to do |format|
      format.html do
        flash[:alert] = "예기치 않은 오류가 발생했습니다."
        redirect_back(fallback_location: root_path)
      end
      format.json do
        render json: {
          error: {
            code: 500,
            message: "서버 오류가 발생했습니다."
          }
        }, status: :internal_server_error
      end
    end
  end
  
  def error_status_code(code)
    case code
    when 1001..1003 then :unauthorized
    when 2001..2002 then :payment_required
    when 3001..3004 then :bad_request
    when 4001..4004 then :service_unavailable
    when 5001..5003 then :internal_server_error
    else :bad_request
    end
  end
end
