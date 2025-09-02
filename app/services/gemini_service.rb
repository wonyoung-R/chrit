require 'gemini-ai'

class GeminiService
  def initialize
    @client = Gemini.new(
      credentials: {
        service: 'generative-language-api',
        api_key: ENV['GEMINI_API_KEY'] || 'AIzaSyAHC6AnNs5KEgChvZ6aTDHcOtG1NbTPnQ0'
      },
      options: {
        model: 'gemini-1.5-flash',
        server_sent_events: true
      }
    )
  end
  
  # 텍스트 콘텐츠를 받아서 요약하는 메서드 (YouTube/Article 공통)
  def summarize_content(content, options = {})
    content_type = options[:type] || 'article'
    language = options[:language] || 'ko'
    
    prompt = build_summarization_prompt(content, content_type, language, options)
    
    response = @client.generate_content({
      contents: {
        role: 'user',
        parts: [
          { text: prompt }
        ]
      },
      generation_config: {
        temperature: 0.7,
        max_output_tokens: 3000,
        top_p: 0.9
      }
    })
    
    parse_summarization_response(response, content_type)
  rescue StandardError => e
    Rails.logger.error "Gemini Summarization Error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    nil
  end
  
  # YouTube 트랜스크립트를 분석하는 메서드
  def analyze_youtube_transcript(transcript, metadata = {})
    return nil if transcript.blank?
    
    prompt = <<~PROMPT
      다음은 YouTube 비디오의 자막입니다. 이를 분석해주세요.
      
      비디오 정보:
      - 제목: #{metadata[:title]}
      - 채널: #{metadata[:channel]}
      - 길이: #{format_duration(metadata[:duration])}
      
      자막 내용:
      #{transcript[0..10000]} #{transcript.length > 10000 ? '...(중략)' : ''}
      
      한국어로 응답해주세요. 다음 형식으로 응답해주세요:
      
      [주요 내용]
      (비디오의 주요 내용을 상세히 설명 - 최소 500자 이상)
      
      [핵심 요약]
      (3-5문장으로 가장 중요한 내용만 요약)
      
      [키워드]
      (콤마로 구분된 5-7개의 핵심 키워드)
      
      [주요 포인트]
      • 중요한 포인트 1
      • 중요한 포인트 2
      • 중요한 포인트 3
      (최대 5개까지)
      
      [추천 대상]
      (이 비디오를 시청하면 좋을 사람들)
    PROMPT
    
    response = @client.generate_content({
      contents: {
        role: 'user',
        parts: [
          { text: prompt }
        ]
      },
      generation_config: {
        temperature: 0.7,
        max_output_tokens: 3000,
        top_p: 0.9
      }
    })
    
    parse_youtube_analysis(response)
  rescue StandardError => e
    Rails.logger.error "Gemini YouTube Analysis Error: #{e.message}"
    nil
  end
  
  # Article 콘텐츠를 분석하는 메서드
  def analyze_article_content(content, metadata = {})
    return nil if content.blank?
    
    # 콘텐츠가 너무 길면 앞부분만 사용
    truncated_content = content[0..15000]
    is_truncated = content.length > 15000
    
    prompt = <<~PROMPT
      다음 웹 문서를 분석하고 요약해주세요.
      
      문서 정보:
      - URL: #{metadata[:url]}
      - 제목: #{metadata[:title]}
      - 작성자: #{metadata[:author]}
      - 게시일: #{metadata[:published_date]}
      
      문서 내용:
      #{truncated_content}#{is_truncated ? "\n...(이하 생략)" : ""}
      
      한국어로 응답해주세요. 다음 형식으로 응답해주세요:
      
      [주제]
      (문서의 주요 주제를 한 문장으로)
      
      [요약]
      (문서의 핵심 내용을 5-7문장으로 요약)
      
      [핵심 포인트]
      • 주요 포인트 1
      • 주요 포인트 2
      • 주요 포인트 3
      (최대 5개까지)
      
      [키워드]
      (콤마로 구분된 5-7개의 핵심 키워드)
      
      [유용성]
      (이 문서가 어떤 사람에게 유용한지)
    PROMPT
    
    response = @client.generate_content({
      contents: {
        role: 'user',
        parts: [
          { text: prompt }
        ]
      },
      generation_config: {
        temperature: 0.7,
        max_output_tokens: 2500,
        top_p: 0.9
      }
    })
    
    parse_article_analysis(response)
  rescue StandardError => e
    Rails.logger.error "Gemini Article Analysis Error: #{e.message}"
    nil
  end
  
  private
  
  def build_summarization_prompt(content, content_type, language, options)
    lang_instruction = language == 'ko' ? '한국어로' : 'in English'
    
    base_prompt = <<~PROMPT
      다음 #{content_type == 'youtube' ? 'YouTube 비디오 자막' : '문서'}을 #{lang_instruction} 요약해주세요.
      
      #{options[:metadata] ? format_metadata(options[:metadata]) : ''}
      
      내용:
      #{content[0..10000]}#{content.length > 10000 ? "\n...(중략)" : ""}
      
      다음 형식으로 응답해주세요:
      
      [요약]
      (핵심 내용을 3-5문장으로 요약)
      
      [키워드]
      (콤마로 구분된 5개의 핵심 키워드)
      
      [주요 포인트]
      • 포인트 1
      • 포인트 2
      • 포인트 3
    PROMPT
    
    base_prompt
  end
  
  def format_metadata(metadata)
    lines = []
    lines << "제목: #{metadata[:title]}" if metadata[:title]
    lines << "작성자: #{metadata[:author]}" if metadata[:author]
    lines << "출처: #{metadata[:source]}" if metadata[:source]
    lines.join("\n")
  end
  
  def format_duration(seconds)
    return nil unless seconds
    
    hours = seconds / 3600
    minutes = (seconds % 3600) / 60
    secs = seconds % 60
    
    if hours > 0
      "#{hours}시간 #{minutes}분"
    elsif minutes > 0
      "#{minutes}분 #{secs}초"
    else
      "#{secs}초"
    end
  end
  
  def parse_summarization_response(response, content_type)
    return nil unless response && response.dig('candidates', 0, 'content', 'parts', 0, 'text')
    
    text = response.dig('candidates', 0, 'content', 'parts', 0, 'text')
    
    {
      summary: extract_section(text, '[요약]') || extract_section(text, '[핵심 요약]'),
      keywords: extract_keywords(text),
      main_points: extract_section(text, '[주요 포인트]'),
      raw_response: text
    }
  end
  
  def parse_youtube_analysis(response)
    return nil unless response && response.dig('candidates', 0, 'content', 'parts', 0, 'text')
    
    text = response.dig('candidates', 0, 'content', 'parts', 0, 'text')
    
    {
      content: extract_section(text, '[주요 내용]'),
      summary: extract_section(text, '[핵심 요약]'),
      keywords: extract_keywords(text),
      main_points: extract_bullet_points(text, '[주요 포인트]'),
      target_audience: extract_section(text, '[추천 대상]'),
      raw_response: text
    }
  end
  
  def parse_article_analysis(response)
    return nil unless response && response.dig('candidates', 0, 'content', 'parts', 0, 'text')
    
    text = response.dig('candidates', 0, 'content', 'parts', 0, 'text')
    
    {
      topic: extract_section(text, '[주제]'),
      summary: extract_section(text, '[요약]'),
      main_points: extract_bullet_points(text, '[핵심 포인트]'),
      keywords: extract_keywords(text),
      usefulness: extract_section(text, '[유용성]'),
      raw_response: text
    }
  end
  
  def extract_section(text, section_name)
    return nil unless text && section_name
    
    # 섹션 이름 다음부터 다음 섹션 시작 전까지 추출
    pattern = /#{Regexp.escape(section_name)}\s*\n(.*?)(?:\n\[|\z)/m
    match = text.match(pattern)
    
    match ? match[1].strip : nil
  end
  
  def extract_keywords(text)
    keywords_text = extract_section(text, '[키워드]')
    return [] unless keywords_text
    
    keywords_text.split(',').map(&:strip).reject(&:empty?)
  end
  
  def extract_bullet_points(text, section_name)
    section_text = extract_section(text, section_name)
    return [] unless section_text
    
    # 불릿 포인트 추출 (•, -, *, 숫자. 등)
    points = section_text.scan(/[•\-\*\d+\.]\s*(.+)/).flatten
    points.map(&:strip).reject(&:empty?)
  end
end