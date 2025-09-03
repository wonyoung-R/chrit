require 'httparty'
require 'nokogiri'

class DocumentationExtractor
  USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
  
  def extract(url)
    Rails.logger.info "DocumentationExtractor: Processing #{url}"
    
    response = fetch_page(url)
    doc = Nokogiri::HTML(response.body)
    
    # 문서 사이트별 특화 처리
    title = extract_title(doc, url)
    content = extract_documentation_content(doc, url)
    navigation = extract_navigation(doc)
    code_examples = extract_code_examples(doc)
    
    # 구조화된 콘텐츠 생성
    structured_content = build_structured_content(content, navigation, code_examples)
    
    {
      title: title,
      content: structured_content,
      image: extract_image(doc, url),
      metadata: extract_metadata(doc, url)
    }
  rescue StandardError => e
    Rails.logger.error "DocumentationExtractor Error: #{e.message}"
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
  
  def extract_title(doc, url)
    # 문서 사이트 특화 제목 추출
    case url
    when /docs\.anthropic\.com/
      doc.at('h1.text-4xl, h1.text-3xl, h1')&.text&.strip
    when /openai\.com\/docs/
      doc.at('h1.docs-title, h1')&.text&.strip
    when /docs\.github\.com/
      doc.at('h1.heading-1, h1')&.text&.strip
    else
      doc.at('h1, .page-title, .doc-title')&.text&.strip ||
      doc.at('title')&.text&.strip
    end
  end
  
  def extract_documentation_content(doc, url)
    # 사이트별 콘텐츠 영역 선택
    content_selector = case url
    when /docs\.anthropic\.com/
      '.prose, .markdown-body, article, main'
    when /openai\.com\/docs/
      '.docs-content, .content-wrapper, main'
    when /docs\.github\.com/
      '.markdown-body, article, main'
    when /developer\.mozilla\.org/
      '.main-page-content, article'
    when /docs\.microsoft\.com/
      '.content, main[role="main"]'
    else
      'article, main, .content, .documentation'
    end
    
    content_element = doc.at(content_selector)
    return "" unless content_element
    
    # 불필요한 요소 제거
    remove_documentation_noise(content_element)
    
    # 구조 보존하며 텍스트 추출
    extract_with_structure(content_element)
  end
  
  def extract_navigation(doc)
    # 문서 네비게이션 구조 추출
    nav = {}
    
    # 사이드바 네비게이션
    sidebar = doc.at('.sidebar, .nav-sidebar, .docs-sidebar, aside nav')
    if sidebar
      nav[:sections] = sidebar.css('a').map do |link|
        {
          title: link.text.strip,
          href: link['href'],
          level: detect_nav_level(link)
        }
      end.select { |item| item[:title].present? }
    end
    
    # 브레드크럼
    breadcrumb = doc.at('.breadcrumb, nav[aria-label="breadcrumb"]')
    if breadcrumb
      nav[:breadcrumb] = breadcrumb.css('a, span').map(&:text).map(&:strip)
    end
    
    # 페이지 내 목차
    toc = doc.at('.toc, .table-of-contents, [id*="table-of-contents"]')
    if toc
      nav[:table_of_contents] = toc.css('a').map do |link|
        {
          title: link.text.strip,
          anchor: link['href']&.gsub(/^#/, '')
        }
      end
    end
    
    nav
  end
  
  def extract_code_examples(doc)
    # 코드 예제 추출 및 언어 감지
    examples = []
    
    doc.css('pre code, pre.highlight, .code-block, .hljs').each do |code_block|
      language = detect_code_language(code_block)
      content = code_block.text.strip
      
      next if content.empty?
      
      examples << {
        language: language,
        content: content,
        context: extract_code_context(code_block)
      }
    end
    
    # 인라인 코드도 추출
    inline_codes = doc.css('code').select { |code| code.parent.name != 'pre' }.map(&:text).map(&:strip).uniq
    
    {
      blocks: examples,
      inline: inline_codes
    }
  end
  
  def detect_code_language(element)
    # 클래스명에서 언어 감지
    classes = element['class']&.to_s || element.parent['class']&.to_s || ""
    
    # 일반적인 언어 패턴
    languages = %w[javascript typescript python ruby go rust java cpp c bash sql html css json yaml xml]
    
    languages.each do |lang|
      return lang if classes.include?(lang)
    end
    
    # data 속성 확인
    element['data-language'] || element.parent['data-language'] || 'plaintext'
  end
  
  def extract_code_context(code_block)
    # 코드 블록 주변 컨텍스트 추출
    context = {}
    
    # 바로 위 헤딩
    prev = code_block.previous_element
    while prev
      if prev.name =~ /^h[1-6]$/
        context[:heading] = prev.text.strip
        break
      end
      prev = prev.previous_element
    end
    
    # 코드 블록 설명
    next_elem = code_block.next_element
    if next_elem && next_elem.name == 'p'
      context[:description] = next_elem.text.strip[0..200]
    end
    
    context
  end
  
  def build_structured_content(content, navigation, code_examples)
    output = []
    
    # 네비게이션 정보 포함
    if navigation[:breadcrumb].present?
      output << "📍 #{navigation[:breadcrumb].join(' > ')}\n\n"
    end
    
    # 목차가 있으면 포함
    if navigation[:table_of_contents].present?
      output << "## 목차\n"
      navigation[:table_of_contents].each do |item|
        output << "• #{item[:title]}\n"
      end
      output << "\n"
    end
    
    # 메인 콘텐츠
    output << content
    
    # 코드 예제 섹션
    if code_examples[:blocks].present?
      output << "\n\n## 코드 예제\n\n"
      code_examples[:blocks].each_with_index do |example, idx|
        output << "### 예제 #{idx + 1}"
        output << " (#{example[:language]})" if example[:language] != 'plaintext'
        output << "\n```#{example[:language]}\n"
        output << example[:content]
        output << "\n```\n\n"
      end
    end
    
    output.join
  end
  
  def extract_with_structure(element)
    output = []
    
    element.children.each do |child|
      case child.name.downcase
      when 'h1', 'h2', 'h3', 'h4', 'h5', 'h6'
        level = child.name[1].to_i
        prefix = '#' * level
        output << "\n#{prefix} #{child.text.strip}\n"
      when 'p'
        text = child.text.strip
        output << "#{text}\n" unless text.empty?
      when 'ul', 'ol'
        child.css('li').each do |li|
          # 중첩 리스트 처리
          text = extract_list_item_text(li)
          output << "• #{text}\n"
        end
        output << ""
      when 'pre', 'code'
        if child.name == 'code' && child.parent.name != 'pre'
          # 인라인 코드
          output << "`#{child.text.strip}`"
        else
          # 코드 블록
          language = detect_code_language(child)
          output << "\n```#{language}\n#{child.text}\n```\n"
        end
      when 'blockquote'
        child.css('p').each do |p|
          output << "> #{p.text.strip}\n"
        end
      when 'table'
        output << extract_table(child)
      when 'dl'
        # 정의 리스트
        child.css('dt').each do |dt|
          dd = dt.next_element
          output << "**#{dt.text.strip}**: #{dd&.text&.strip}\n"
        end
      when 'details'
        # 접을 수 있는 섹션
        summary = child.at('summary')
        if summary
          output << "\n📦 #{summary.text.strip}\n"
          output << extract_with_structure(child)
        end
      when 'div', 'section', 'article'
        # 재귀적 처리
        result = extract_with_structure(child)
        output << result unless result.empty?
      when 'text'
        text = child.text.strip
        output << text unless text.empty?
      end
    end
    
    output.join("\n").gsub(/\n{3,}/, "\n\n").strip
  end
  
  def extract_list_item_text(li)
    # 중첩 리스트 제외한 텍스트만 추출
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
  
  def extract_table(table)
    output = ["\n"]
    
    # 헤더 추출
    headers = table.css('thead th, thead td').map(&:text).map(&:strip)
    if headers.empty?
      # tbody 첫 행을 헤더로 간주
      first_row = table.at('tbody tr')
      headers = first_row&.css('th, td')&.map(&:text)&.map(&:strip) || []
    end
    
    if headers.present?
      output << "| " + headers.join(" | ") + " |"
      output << "|" + (" --- |" * headers.length)
    end
    
    # 데이터 행 추출
    table.css('tbody tr').each do |row|
      cells = row.css('td').map(&:text).map(&:strip)
      next if cells.empty?
      output << "| " + cells.join(" | ") + " |"
    end
    
    output << "\n"
    output.join("\n")
  end
  
  def remove_documentation_noise(element)
    # 문서 사이트의 불필요한 요소 제거
    noise_selectors = [
      '.edit-link', '.edit-page',           # 편집 링크
      '.feedback', '.rating',               # 피드백 위젯
      '.advertisement', '.ads',             # 광고
      '.social-share', '.share',            # 공유 버튼
      '.navigation', '.pagination',         # 페이지 네비게이션
      '.footer', 'footer',                  # 푸터
      '.sidebar', 'aside',                  # 사이드바 (메인 콘텐츠가 아닌 경우)
      '.banner', '.alert',                  # 배너/알림
      '.cookie-notice',                     # 쿠키 안내
      'script', 'style', 'noscript'        # 스크립트/스타일
    ]
    
    element.css(noise_selectors.join(', ')).remove
  end
  
  def extract_image(doc, url)
    # OG 이미지 또는 문서 대표 이미지
    og_image = doc.at('meta[property="og:image"]')&.[]('content')
    return normalize_url(og_image, url) if og_image
    
    # 문서 내 첫 번째 의미있는 이미지
    img = doc.at('article img[src*="diagram"], article img[src*="architecture"], article img.hero')
    return normalize_url(img['src'], url) if img
    
    nil
  end
  
  def extract_metadata(doc, url)
    {
      url: url,
      type: 'documentation',
      last_modified: doc.at('meta[name="last-modified"]')&.[]('content'),
      version: extract_version(doc),
      language: doc.at('html')&.[]('lang') || 'en',
      description: doc.at('meta[name="description"]')&.[]('content'),
      keywords: doc.at('meta[name="keywords"]')&.[]('content'),
      extracted_at: Time.current
    }
  end
  
  def extract_version(doc)
    # 버전 정보 추출 시도
    version_element = doc.at('.version, .doc-version, [class*="version"]')
    return version_element.text.strip if version_element
    
    # URL에서 버전 추출
    doc.at('link[rel="canonical"]')&.[]('href')&.match(/v(\d+\.?\d*\.?\d*)/)&.[](1)
  end
  
  def detect_nav_level(element)
    # 네비게이션 레벨 감지 (들여쓰기 등)
    classes = element.parent['class']&.to_s || ""
    return 2 if classes.include?('sub') || classes.include?('child')
    return 3 if classes.include?('subsub') || classes.include?('grandchild')
    1
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