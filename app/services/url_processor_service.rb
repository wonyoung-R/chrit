require 'net/http'
require 'json'
require 'uri'

class UrlProcessorService
  attr_reader :url, :content_type

  def initialize(url)
    @url = url
    @content_type = identify_content_type
  end

  def process
    result = case @content_type
    when :youtube
      process_youtube_content
    when :thread
      process_thread_content
    when :article
      process_article_content
    else
      { error: "Unsupported URL type" }
    end
    
    result.merge(
      original_url: @url,
      content_type: @content_type.to_s,
      processed_at: Time.current
    )
  end

  private

  def identify_content_type
    case @url
    when /youtube\.com\/watch|youtu\.be/
      :youtube
    when /twitter\.com|x\.com|reddit\.com/
      :thread
    else
      :article
    end
  end

  def process_youtube_content
    video_id = extract_youtube_id
    return { error: "Invalid YouTube URL" } unless video_id

    {
      title: fetch_youtube_title(video_id),
      summary: generate_youtube_summary(video_id),
      keywords: extract_youtube_keywords(video_id),
      thumbnail_url: "https://img.youtube.com/vi/#{video_id}/maxresdefault.jpg"
    }
  end

  def process_thread_content
    {
      title: "Thread Discussion",
      summary: "Thread content processing - implement scraping logic",
      keywords: ["#discussion", "#thread"],
      author: extract_thread_author
    }
  end

  def process_article_content
    {
      title: "Article Title",
      summary: "Article content processing - implement scraping logic",
      keywords: ["#article", "#news"],
      image_url: nil
    }
  end

  def extract_youtube_id
    match = @url.match(/(?:youtube\.com\/watch\?v=|youtu\.be\/)([^&\n?#]+)/)
    match ? match[1] : nil
  end

  def fetch_youtube_title(video_id)
    # This would use YouTube API with credentials from ENV
    # api_key = ENV['YOUTUBE_API_KEY']
    # Make API call to get video details
    "YouTube Video Title"
  end

  def generate_youtube_summary(video_id)
    # This would:
    # 1. Fetch captions using YouTube API
    # 2. Process with AI (Claude/OpenAI) using ENV credentials
    # 3. Return concise summary
    "Video summary will be generated here"
  end

  def extract_youtube_keywords(video_id)
    # Analyze content and extract relevant keywords
    ["#technology", "#tutorial", "#education"]
  end

  def extract_thread_author
    # Extract author from thread URL
    "thread_author"
  end

  def extract_keywords_from_content(content)
    # Common keyword extraction logic
    keywords = []
    
    # Define keyword categories
    categories = {
      politics: /정치|선거|정부|대통령|국회/i,
      economy: /경제|주식|투자|금융|시장/i,
      technology: /기술|AI|인공지능|IT|소프트웨어|프로그래밍/i,
      science: /과학|연구|실험|발견/i,
      sports: /스포츠|축구|야구|농구|운동/i,
      entertainment: /연예|영화|드라마|음악|K-pop/i,
      health: /건강|의료|질병|치료|운동/i,
      education: /교육|학교|대학|학습/i,
      business: /비즈니스|기업|창업|경영/i,
      culture: /문화|예술|전통|역사/i
    }
    
    categories.each do |category, pattern|
      if content.match?(pattern)
        keywords << "##{category}"
      end
    end
    
    keywords.take(7) # Return maximum 7 keywords
  end
end