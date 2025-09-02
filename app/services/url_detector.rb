class UrlDetector
  def initialize(url)
    @url = url
  end
  
  def youtube?
    @url.include?("youtube.com/watch") || 
    @url.include?("youtu.be/") ||
    @url.include?("youtube.com/shorts/")
  end
  
  def article?
    !youtube?
  end
end