class HomeController < ApplicationController
  def index
    render file: Rails.root.join("public", "chrit-game", "index.html"), layout: false
  end
end
