require 'httparty'
require 'nokogiri'

class ArticleExtractor
  USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
  
  def extract(url)
    Rails.logger.info "Extracting content from: #{url}"
    
    # 특수 사이트용 전용 추출기 확인
    if specialized_extractor = get_specialized_extractor(url)
      Rails.logger.info "Using specialized extractor: #{specialized_extractor.class.name}"
      return specialized_extractor.extract(url)
    end
    
    # HTTP 요청으로 페이지 가져오기
    response = fetch_page(url)
    
    # HTML 파싱
    doc = Nokogiri::HTML(response.body)
    
    # 각종 데이터 추출
    title = extract_title(doc)
    content = extract_content(doc, url)
    image = extract_image(doc, url)
    metadata = extract_metadata(doc, url)
    
    {
      title: title,
      content: content,
      image: image,
      metadata: metadata
    }
  rescue StandardError => e
    Rails.logger.error "Article Extraction Error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    # 폴백: 기본 정보만이라도 반환
    {
      title: "콘텐츠 추출 실패",
      content: "URL: #{url}\n\n오류: #{e.message}",
      image: nil,
      metadata: { url: url, error: e.message, extracted_at: Time.current }
    }
  end
  
  private
  
  def get_specialized_extractor(url)
    case url
    when /docs\.anthropic\.com/
      DocumentationExtractor.new
    when /openai\.com\/docs/
      DocumentationExtractor.new
    when /medium\.com/, /dev\.to/, /hashnode/
      BlogExtractor.new
    when /github\.com/
      GithubExtractor.new
    else
      nil
    end
  end
  
  def fetch_page(url, max_retries = 3)
    retries = 0
    begin
      response = HTTParty.get(url, 
        headers: {
          'User-Agent' => USER_AGENT,
          'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language' => 'ko-KR,ko;q=0.9,en;q=0.8',
          'Accept-Encoding' => 'gzip, deflate',
          'Connection' => 'keep-alive',
          'Upgrade-Insecure-Requests' => '1'
        },
        follow_redirects: true,
        timeout: 15
      )
      
      raise "HTTP Error: #{response.code}" unless response.success?
      response
    rescue => e
      retries += 1
      if retries < max_retries
        Rails.logger.warn "Retry #{retries}/#{max_retries} for #{url}: #{e.message}"
        sleep(retries * 2) # 지수 백오프
        retry
      else
        raise
      end
    end
  end
  
  def extract_title(doc)
    # 우선순위: Open Graph > Twitter Card > H1 > Title
    doc.at('meta[property="og:title"]')&.[]('content') ||
    doc.at('meta[name="twitter:title"]')&.[]('content') ||
    doc.at('h1')&.text&.strip ||
    doc.at('title')&.text&.strip ||
    "제목 없음"
  end
  
  def extract_content(doc, url)
    # 콘텐츠 추출 전략
    content = nil
    
    # 1. Article 태그 우선
    article = doc.at('article, [role="article"], .article, #article')
    
    # 2. Main 콘텐츠 영역
    article ||= doc.at('main, [role="main"], .main-content, #main-content, .content, #content')
    
    # 3. 특정 클래스/ID 패턴
    article ||= doc.at('.post-content, .entry-content, .article-body, .story-body, .markdown-body')
    
    # 4. 최후의 수단: body
    article ||= doc.at('body')
    
    if article
      # 복사본 생성하여 원본 보존
      article = article.dup
      
      # 불필요한 요소 제거
      remove_unwanted_elements(article)
      
      # 콘텐츠 추출 및 정제
      content = extract_text_with_structure(article)
    end
    
    # 최소 길이 체크
    if content.nil? || content.length < 100
      # 메타 설명 + 본문 일부
      meta_desc = doc.at('meta[name="description"]')&.[]('content') || ""
      paragraphs = doc.css('p').map(&:text).join("\n\n")
      content = "#{meta_desc}\n\n#{paragraphs}"
    end
    
    # 길이 제한 (약 10000자)
    content[0..9999]
  end
  
  def extract_text_with_structure(element)
    output = []
    
    element.children.each do |child|
      case child.name.downcase
      when 'h1', 'h2', 'h3', 'h4', 'h5', 'h6'
        # 헤딩은 구조 유지
        level = child.name[1].to_i
        prefix = '#' * level
        output << "\n#{prefix} #{child.text.strip}\n"
      when 'p'
        # 단락
        text = child.text.strip
        output << "#{text}\n" unless text.empty?
      when 'ul', 'ol'
        # 리스트
        child.css('li').each do |li|
          output << "• #{li.text.strip}"
        end
        output << ""
      when 'pre', 'code'
        # 코드 블록 보존
        output << "\n```\n#{child.text}\n```\n"
      when 'blockquote'
        # 인용문
        output << "> #{child.text.strip}\n"
      when 'div', 'section', 'article'
        # 재귀적으로 처리
        output << extract_text_with_structure(child)
      when 'text'
        # 텍스트 노드
        text = child.text.strip
        output << text unless text.empty?
      end
    end
    
    output.join("\n").gsub(/\n{3,}/, "\n\n").strip
  end
  
  def remove_unwanted_elements(doc)
    # 제거할 요소들
    selectors = [
      'script', 'style', 'noscript', 'iframe',
      'nav', 'header', 'footer', 'aside',
      '.navigation', '.nav', '.menu', '.sidebar',
      '.advertisement', '.ads', '.ad', '.banner',
      '.social-share', '.share-buttons', '.comments',
      '.related-posts', '.related-articles',
      '[aria-hidden="true"]', '[hidden]',
      '.cookie-notice', '.popup', '.modal'
    ]
    
    doc.css(selectors.join(', ')).remove
  end
  
  def extract_image(doc, url)
    # Open Graph 이미지 우선
    og_image = doc.at('meta[property="og:image"]')&.[]('content')
    
    # Twitter Card 이미지
    og_image ||= doc.at('meta[name="twitter:image"]')&.[]('content')
    
    # 첫 번째 큰 이미지
    if og_image.nil?
      img = doc.at('article img, main img, .content img')
      og_image = img&.[]('src') || img&.[]('data-src')
    end
    
    # URL 정규화
    normalize_url(og_image, url) if og_image
  end
  
  def extract_metadata(doc, url)
    {
      url: url,
      author: extract_author(doc),
      published_date: extract_date(doc),
      description: doc.at('meta[name="description"]')&.[]('content'),
      keywords: doc.at('meta[name="keywords"]')&.[]('content'),
      language: doc.at('html')&.[]('lang') || 'ko',
      extracted_at: Time.current
    }
  end
  
  def extract_author(doc)
    doc.at('meta[name="author"]')&.[]('content') ||
    doc.at('meta[property="article:author"]')&.[]('content') ||
    doc.at('[rel="author"]')&.text&.strip ||
    doc.at('.author, .by-author, .article-author')&.text&.strip
  end
  
  def extract_date(doc)
    date_string = doc.at('meta[property="article:published_time"]')&.[]('content') ||
                  doc.at('time[datetime]')&.[]('datetime') ||
                  doc.at('meta[name="publish_date"]')&.[]('content')
    
    Date.parse(date_string) rescue nil
  end
  
  def normalize_url(url_str, base_url)
    return nil if url_str.nil? || url_str.empty?
    
    # 이미 절대 URL인 경우
    return url_str if url_str.start_with?('http://', 'https://')
    
    # 상대 URL 처리
    uri = URI.parse(base_url)
    
    if url_str.start_with?('//')
      # 프로토콜 상대 URL
      "#{uri.scheme}:#{url_str}"
    elsif url_str.start_with?('/')
      # 절대 경로
      "#{uri.scheme}://#{uri.host}#{url_str}"
    else
      # 상대 경로
      base_path = File.dirname(uri.path)
      "#{uri.scheme}://#{uri.host}#{base_path}/#{url_str}"
    end
  rescue
    nil
  end
end