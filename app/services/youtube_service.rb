require 'google/apis/youtube_v3'
require 'net/http'
require 'json'

class YoutubeService
  def initialize
    @youtube = Google::Apis::YoutubeV3::YouTubeService.new
    @youtube.key = Rails.application.credentials.dig(:youtube, :api_key) || ENV['YOUTUBE_API_KEY']
  end
  
  def fetch_video_data(url)
    video_id = extract_video_id(url)
    
    # YouTube API로 비디오 정보 가져오기
    response = @youtube.list_videos(
      'snippet,contentDetails,topicDetails',
      id: video_id
    )
    
    video = response.items.first
    
    {
      video_id: video_id,
      title: video.snippet.title,
      description: video.snippet.description,
      channel: video.snippet.channel_title,
      thumbnail: video.snippet.thumbnails.high.url,
      duration: parse_duration(video.content_details.duration),
      published_at: video.snippet.published_at,
      tags: video.snippet.tags || [],
      category_id: video.snippet.category_id,
      topics: extract_topics(video.topic_details)
    }
  rescue StandardError => e
    Rails.logger.error "YouTube API Error: #{e.message}"
    raise
  end
  
  def fetch_transcript(video_id)
    # 여러 방법으로 자막 가져오기 시도 (Gemini 제외 - Gemini는 URL에서 직접 콘텐츠를 가져올 수 없음)
    transcript = nil
    
    # 방법 1: YouTube API v3로 캡션 트랙 확인
    transcript = fetch_captions_via_api(video_id)
    if transcript.present?
      Rails.logger.info "Successfully fetched transcript via YouTube API v3"
      return transcript
    end
    
    # 방법 2: 직접 HTTP 요청으로 자막 추출
    transcript = fetch_transcript_via_gem(video_id)
    if transcript.present?
      Rails.logger.info "Successfully fetched transcript via HTTP request"
      return transcript
    end
    
    # 방법 3: 대체 방법 - 웹 스크래핑 (최후의 수단)
    transcript = fetch_transcript_via_scraping(video_id)
    if transcript.present?
      Rails.logger.info "Successfully fetched transcript via web scraping"
      return transcript
    end
    
    # 모든 방법 실패 시
    Rails.logger.warn "Failed to fetch transcript for video #{video_id} - all methods exhausted"
    nil  # nil 반환하여 상위에서 처리하도록 함
  rescue StandardError => e
    Rails.logger.error "Transcript fetch error: #{e.message}"
    "자막 가져오기 중 오류가 발생했습니다: #{e.message}"
  end
  
  # Public methods for transcript fetching (used by YoutubeProcessorJob)
  def fetch_captions_via_api(video_id)
    begin
      # YouTube Data API v3로 캡션 목록 가져오기
      # list_captions는 두 개의 파라미터 필요: part와 video_id
      captions = @youtube.list_captions('snippet', video_id)
      
      if captions.items.any?
        # 한국어 자막 우선, 없으면 영어, 그것도 없으면 첫 번째 자막
        caption = captions.items.find { |c| c.snippet.language == 'ko' } ||
                  captions.items.find { |c| c.snippet.language == 'en' } ||
                  captions.items.first
        
        if caption
          # 캡션 ID로 실제 자막 다운로드
          # 참고: 이 부분은 OAuth2 인증이 필요할 수 있습니다
          Rails.logger.info "Caption found: #{caption.snippet.name} (#{caption.snippet.language})"
          
          # YouTube API v3는 자막 내용 직접 다운로드를 지원하지 않음
          # 대신 캡션이 있다는 정보만 반환
          return nil
        end
      end
    rescue Google::Apis::ClientError => e
      Rails.logger.error "YouTube Caption API error: #{e.message}"
    end
    
    nil
  end
  
  def fetch_transcript_via_gem(video_id)
    # youtube-transcript gem 대신 직접 HTTP 요청으로 구현
    begin
      # YouTube 페이지에서 자막 정보 추출
      video_url = "https://www.youtube.com/watch?v=#{video_id}"
      response = HTTParty.get(video_url, headers: {
        'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept-Language' => 'ko-KR,ko;q=0.9,en;q=0.8'
      })
      
      if response.code == 200
        # 페이지에서 자막 URL 추출
        if response.body.include?('"captions"')
          # 자막 관련 데이터 파싱
          captions_match = response.body.match(/"captions":\{[^}]+\}/)
          if captions_match
            Rails.logger.info "Found captions data in YouTube page"
            # 실제 자막 내용은 별도 요청 필요
          end
        end
      end
    rescue => e
      Rails.logger.error "Direct transcript fetch error: #{e.message}"
    end
    
    nil
  end
  
  def fetch_transcript_via_scraping(video_id)
    begin
      # 대체 방법: YouTube 페이지에서 자막 데이터 추출
      # 주의: 이 방법은 YouTube 이용 약관을 위반할 수 있습니다
      
      # InnerTube API 사용 (YouTube 내부 API)
      url = "https://www.youtube.com/youtubei/v1/get_transcript"
      
      params = {
        videoId: video_id,
        key: 'AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8', # YouTube 웹 클라이언트 키
        prettyPrint: false
      }
      
      headers = {
        'Content-Type' => 'application/json',
        'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      }
      
      body = {
        context: {
          client: {
            clientName: 'WEB',
            clientVersion: '2.20240101'
          }
        },
        params: video_id
      }
      
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      
      request = Net::HTTP::Post.new(uri)
      headers.each { |key, value| request[key] = value }
      request.body = body.to_json
      
      response = http.request(request)
      
      if response.code == '200'
        data = JSON.parse(response.body)
        
        # 자막 텍스트 추출
        if data['transcriptTracks']
          track = data['transcriptTracks'].first
          if track['content']
            return track['content']
          end
        end
      end
    rescue => e
      Rails.logger.error "Scraping error: #{e.message}"
    end
    
    nil
  end
  
  private
  
  def extract_topics(topic_details)
    return [] unless topic_details&.topic_ids
    
    # YouTube의 토픽 ID를 한국어 키워드로 매핑
    topic_mapping = {
      "/m/04rlf" => "음악",
      "/m/02mscn" => "기독교",
      "/m/0kt51" => "건강",
      "/m/01k8wb" => "지식",
      "/m/019_rr" => "라이프스타일",
      "/m/098wr" => "사회",
      "/m/05qt0" => "정치",
      "/m/03tmr" => "자동차",
      "/m/07c1v" => "기술",
      "/m/06ntj" => "스포츠",
      "/m/0jm_" => "코미디",
      "/m/02jjt" => "엔터테인먼트",
      "/m/09kqc" => "유머"
    }
    
    topic_details.topic_ids.map { |id| topic_mapping[id] }.compact
  end
  
  def extract_video_id(url)
    # URL에서 비디오 ID 추출
    if url.include?('youtube.com/watch?v=')
      url.split('v=')[1].split('&')[0]
    elsif url.include?('youtu.be/')
      url.split('youtu.be/')[1].split('?')[0]
    elsif url.include?('youtube.com/shorts/')
      url.split('shorts/')[1].split('?')[0]
    else
      raise "Invalid YouTube URL"
    end
  end
  
  def parse_duration(duration_str)
    # PT1H2M3S 형식을 초로 변환
    match = duration_str.match(/PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?/)
    return 0 unless match
    
    hours = match[1].to_i
    minutes = match[2].to_i
    seconds = match[3].to_i
    
    hours * 3600 + minutes * 60 + seconds
  end
end