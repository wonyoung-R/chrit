class Users::SessionsController < Devise::SessionsController
  # Ensure session persistence with remember me
  before_action :configure_sign_in_params, only: [:create]
  skip_before_action :verify_authenticity_token, only: [:destroy]
  
  # POST /resource/sign_in
  def create
    self.resource = warden.authenticate!(auth_options)
    set_flash_message!(:notice, :signed_in)
    
    # Always remember the user if remember_me is checked
    if params[:user].present? && params[:user][:remember_me] == "1"
      remember_me(resource)
    end
    
    sign_in(resource_name, resource)
    yield resource if block_given?
    respond_with resource, location: after_sign_in_path_for(resource)
  end

  # DELETE /resource/sign_out
  def destroy
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    set_flash_message! :notice, :signed_out if signed_out
    yield if block_given?
    respond_to_on_destroy
  end

  protected

  def configure_sign_in_params
    devise_parameter_sanitizer.permit(:sign_in, keys: [:remember_me])
  end

  def respond_to_on_destroy
    respond_to do |format|
      format.all { head :no_content }
      format.any(*navigational_formats) { redirect_to after_sign_out_path_for(resource_name), status: :see_other }
    end
  end
  
  # Extend remember period on activity
  def after_sign_in_path_for(resource)
    if resource.is_a?(User) && params[:user].present? && params[:user][:remember_me] == "1"
      resource.remember_me!
    end
    stored_location_for(resource) || dashboard_path
  end
end