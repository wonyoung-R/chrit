class HomeController < ApplicationController
  def index
    if user_signed_in?
      @recent_knowledges = current_user.knowledges.recent.limit(5)
    else
      @recent_knowledges = []
    end
  end
end
