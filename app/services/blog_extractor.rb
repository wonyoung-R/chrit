require 'httparty'
require 'nokogiri'

class BlogExtractor
  USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
  
  def extract(url)
    Rails.logger.info "BlogExtractor: Processing #{url}"
    
    response = fetch_page(url)
    doc = Nokogiri::HTML(response.body)
    
    # 블로그별 특화 처리
    title = extract_title(doc, url)
    content = extract_blog_content(doc, url)
    author = extract_author(doc, url)
    published_date = extract_date(doc, url)
    tags = extract_tags(doc)
    
    {
      title: title,
      content: content,
      image: extract_feature_image(doc, url),
      metadata: {
        url: url,
        author: author,
        published_date: published_date,
        tags: tags,
        platform: detect_platform(url),
        extracted_at: Time.current
      }
    }
  rescue StandardError => e
    Rails.logger.error "BlogExtractor Error: #{e.message}"
    raise
  end
  
  private
  
  def fetch_page(url)
    HTTParty.get(url, 
      headers: {
        'User-Agent' => USER_AGENT,
        'Accept' => 'text/html,application/xhtml+xml',
        'Accept-Language' => 'ko-KR,ko;q=0.9,en;q=0.8'
      },
      follow_redirects: true,
      timeout: 15
    )
  end
  
  def detect_platform(url)
    case url
    when /medium\.com/
      'Medium'
    when /dev\.to/
      'Dev.to'
    when /hashnode/
      'Hashnode'
    when /wordpress/
      'WordPress'
    when /ghost/
      'Ghost'
    when /substack/
      'Substack'
    when /blogger/, /blogspot/
      'Blogger'
    else
      'Blog'
    end
  end
  
  def extract_title(doc, url)
    case detect_platform(url)
    when 'Medium'
      doc.at('h1')&.text&.strip ||
      doc.at('meta[property="og:title"]')&.[]('content')
    when 'Dev.to'
      doc.at('h1.crayons-article__header__meta')&.text&.strip ||
      doc.at('h1')&.text&.strip
    when 'Hashnode'
      doc.at('h1.post-title')&.text&.strip ||
      doc.at('h1')&.text&.strip
    else
      doc.at('h1.entry-title, h1.post-title, h1')&.text&.strip ||
      doc.at('meta[property="og:title"]')&.[]('content') ||
      doc.at('title')&.text&.strip
    end
  end
  
  def extract_blog_content(doc, url)
    # 플랫폼별 콘텐츠 선택자
    content_element = case detect_platform(url)
    when 'Medium'
      doc.at('article section') || doc.at('article')
    when 'Dev.to'
      doc.at('.crayons-article__body') || doc.at('#article-body')
    when 'Hashnode'
      doc.at('.post-content-wrapper') || doc.at('.post-content')
    when 'WordPress'
      doc.at('.entry-content, .post-content, article')
    when 'Ghost'
      doc.at('.post-content, .gh-content')
    when 'Substack'
      doc.at('.post-content, .body')
    else
      doc.at('article, .post-content, .entry-content, .content, main')
    end
    
    return "" unless content_element
    
    # 복사본 생성
    content_element = content_element.dup
    
    # 블로그 특화 노이즈 제거
    remove_blog_noise(content_element, url)
    
    # 구조 보존 텍스트 추출
    extract_blog_text(content_element, url)
  end
  
  def extract_blog_text(element, url)
    output = []
    
    element.children.each do |child|
      case child.name.downcase
      when 'h1', 'h2', 'h3', 'h4', 'h5', 'h6'
        # 헤딩
        level = child.name[1].to_i
        prefix = '#' * level
        output << "\n#{prefix} #{child.text.strip}\n"
        
      when 'p'
        # 단락
        text = child.text.strip
        
        # Medium의 하이라이트 처리
        if child['class']&.include?('graf--pullquote')
          output << "\n> #{text}\n"
        elsif !text.empty?
          output << "#{text}\n"
        end
        
      when 'ul', 'ol'
        # 리스트
        child.css('li').each_with_index do |li, idx|
          prefix = child.name == 'ol' ? "#{idx + 1}." : "•"
          output << "#{prefix} #{extract_list_text(li)}\n"
        end
        output << ""
        
      when 'pre'
        # 코드 블록
        code = child.at('code') || child
        language = detect_code_language(code)
        output << "\n```#{language}\n#{code.text}\n```\n"
        
      when 'blockquote'
        # 인용문
        quote_text = extract_blog_text(child, url)
        quote_text.split("\n").each do |line|
          output << "> #{line}\n" unless line.empty?
        end
        
      when 'figure'
        # 이미지/미디어 처리
        caption = child.at('figcaption')
        img = child.at('img')
        
        if img
          alt_text = img['alt'] || 'Image'
          output << "\n[#{alt_text}]\n"
        end
        
        if caption
          output << "_#{caption.text.strip}_\n"
        end
        
      when 'iframe'
        # 임베드 콘텐츠 (YouTube, CodePen 등)
        src = child['src']
        if src
          if src.include?('youtube')
            output << "\n[YouTube Video]\n"
          elsif src.include?('codepen')
            output << "\n[CodePen Embed]\n"
          else
            output << "\n[Embedded Content]\n"
          end
        end
        
      when 'div', 'section', 'article'
        # 재귀 처리
        result = extract_blog_text(child, url)
        output << result unless result.empty?
        
      when 'text'
        text = child.text.strip
        output << text unless text.empty?
      end
    end
    
    output.join("\n").gsub(/\n{3,}/, "\n\n").strip
  end
  
  def extract_list_text(li)
    text = ""
    li.children.each do |child|
      if child.text?
        text += child.text.strip + " "
      elsif child.name != 'ul' && child.name != 'ol'
        text += child.text.strip + " "
      end
    end
    text.strip
  end
  
  def extract_author(doc, url)
    case detect_platform(url)
    when 'Medium'
      doc.at('a[rel="author"]')&.text&.strip ||
      doc.at('meta[name="author"]')&.[]('content')
    when 'Dev.to'
      doc.at('.crayons-article__header__meta__author')&.text&.strip ||
      doc.at('meta[name="author"]')&.[]('content')
    when 'Hashnode'
      doc.at('.author-name')&.text&.strip ||
      doc.at('meta[name="author"]')&.[]('content')
    else
      doc.at('meta[name="author"]')&.[]('content') ||
      doc.at('.author, .by-author, .author-name, [rel="author"]')&.text&.strip
    end
  end
  
  def extract_date(doc, url)
    date_string = case detect_platform(url)
    when 'Medium'
      doc.at('time')&.[]('datetime') ||
      doc.at('meta[property="article:published_time"]')&.[]('content')
    when 'Dev.to'
      doc.at('time[datetime]')&.[]('datetime') ||
      doc.at('meta[name="published_at"]')&.[]('content')
    when 'Hashnode'
      doc.at('time[datetime]')&.[]('datetime') ||
      doc.at('meta[property="article:published_time"]')&.[]('content')
    else
      doc.at('time[datetime]')&.[]('datetime') ||
      doc.at('meta[property="article:published_time"]')&.[]('content') ||
      doc.at('meta[name="publish_date"]')&.[]('content')
    end
    
    Date.parse(date_string) rescue nil
  end
  
  def extract_tags(doc)
    tags = []
    
    # Meta 태그에서 추출
    meta_keywords = doc.at('meta[name="keywords"]')&.[]('content')
    if meta_keywords
      tags += meta_keywords.split(',').map(&:strip)
    end
    
    # 플랫폼별 태그 추출
    tag_selectors = [
      '.tag', '.tags a', '.post-tag',           # 일반적인 태그
      '.crayons-tag',                           # Dev.to
      '.tag-name',                               # Hashnode
      'a[rel="tag"]',                           # WordPress
      '.post-card-tags a'                       # Ghost
    ]
    
    tag_selectors.each do |selector|
      doc.css(selector).each do |tag_element|
        tag_text = tag_element.text.strip.gsub(/^#/, '')
        tags << tag_text unless tag_text.empty?
      end
    end
    
    tags.uniq.take(10) # 최대 10개 태그
  end
  
  def extract_feature_image(doc, url)
    # OG 이미지 우선
    og_image = doc.at('meta[property="og:image"]')&.[]('content')
    return normalize_url(og_image, url) if og_image
    
    # 플랫폼별 대표 이미지
    feature_image = case detect_platform(url)
    when 'Medium'
      doc.at('article img')&.[]('src')
    when 'Dev.to'
      doc.at('.crayons-article__cover img')&.[]('src') ||
      doc.at('.crayons-article__body img')&.[]('src')
    when 'Hashnode'
      doc.at('.post-cover-image img')&.[]('src') ||
      doc.at('.post-content img')&.[]('src')
    else
      doc.at('.featured-image img, .post-thumbnail img, article img')&.[]('src')
    end
    
    normalize_url(feature_image, url) if feature_image
  end
  
  def detect_code_language(element)
    # 클래스명에서 언어 감지
    classes = element['class']&.to_s || element.parent['class']&.to_s || ""
    
    # 일반적인 언어 패턴
    languages = %w[javascript typescript python ruby go rust java cpp c bash sql html css json yaml xml jsx tsx]
    
    languages.each do |lang|
      return lang if classes.downcase.include?(lang)
    end
    
    # data 속성 확인
    element['data-language'] || element.parent['data-language'] || 'plaintext'
  end
  
  def remove_blog_noise(element, url)
    # 블로그 플랫폼별 노이즈 제거
    noise_selectors = [
      # 일반적인 노이즈
      '.social-share', '.share-buttons',
      '.author-bio', '.author-card',
      '.related-posts', '.recommended',
      '.comments', '#comments',
      '.newsletter', '.subscribe',
      '.advertisement', '.ads',
      
      # Medium 특화
      '.js-postMetaLockup',
      '.js-postPromotionWrapper',
      
      # Dev.to 특화
      '.crayons-article__actions',
      '.crayons-article__reactions',
      
      # 기타
      'script', 'style', 'noscript',
      '.navigation', 'nav',
      'footer', '.footer'
    ]
    
    element.css(noise_selectors.join(', ')).remove
  end
  
  def normalize_url(url_str, base_url)
    return nil if url_str.nil? || url_str.empty?
    return url_str if url_str.start_with?('http://', 'https://')
    
    uri = URI.parse(base_url)
    
    if url_str.start_with?('//')
      "#{uri.scheme}:#{url_str}"
    elsif url_str.start_with?('/')
      "#{uri.scheme}://#{uri.host}#{url_str}"
    else
      base_path = File.dirname(uri.path)
      "#{uri.scheme}://#{uri.host}#{base_path}/#{url_str}"
    end
  rescue
    nil
  end
end