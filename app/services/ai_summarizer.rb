require 'anthropic'

class AiSummarizer
  def initialize
    @client = Anthropic::Client.new(
      api_key: ENV['ANTHROPIC_API_KEY']
    )
  end
  
  def summarize(content:, type:, metadata: {})
    prompt = build_prompt(content, type, metadata)
    
    response = @client.messages(
      model: "claude-3-haiku-20240307",
      max_tokens: 800,
      temperature: 0.7,
      system: "당신은 뛰어난 콘텐츠 분석 전문가입니다. 한국어로 응답해주세요.",
      messages: [
        {
          role: "user",
          content: prompt
        }
      ]
    )
    
    parse_response(response.dig("content", 0, "text"))
  rescue StandardError => e
    Rails.logger.error "AI Summarizer Error: #{e.message}"
    { summary: "요약 생성에 실패했습니다.", keywords: [] }
  end
  
  def extract_keywords(content:, type:, metadata: {})
    prompt = build_keyword_prompt(content, type, metadata)
    
    response = @client.messages(
      model: "claude-3-haiku-20240307",
      max_tokens: 200,
      temperature: 0.3,
      system: "당신은 콘텐츠에서 핵심 키워드를 추출하는 전문가입니다.",
      messages: [
        {
          role: "user",
          content: prompt
        }
      ]
    )
    
    keywords = response.dig("content", 0, "text").split(",").map(&:strip)
    keywords.first(5)
  rescue StandardError => e
    Rails.logger.error "Keyword Extraction Error: #{e.message}"
    []
  end
  
  private
  
  def build_prompt(content, type, metadata = {})
    case type
    when "youtube_video"
      <<~PROMPT
        다음 YouTube 동영상의 내용을 분석해주세요.
        
        제목: #{metadata[:title]}
        채널: #{metadata[:channel]}
        설명: #{metadata[:description]}
        태그: #{metadata[:tags]&.join(", ")}
        
        내용:
        #{content[0..3000]}
        
        다음 형식으로 응답해주세요:
        
        [요약]
        (3-5문장으로 핵심 내용 요약)
        
        [키워드]
        (콤마로 구분된 5개의 핵심 키워드. 예: 정치, 경제, 기술, 사회, 문화)
      PROMPT
    when "article"
      <<~PROMPT
        다음 기사의 내용을 분석해주세요.
        
        기사 본문:
        #{content[0..3000]}
        
        다음 형식으로 응답해주세요:
        
        [요약]
        (3-5문장으로 핵심 내용 요약)
        
        [키워드]
        (콤마로 구분된 5개의 핵심 키워드)
      PROMPT
    else
      <<~PROMPT
        다음 내용을 분석해주세요:
        #{content[0..3000]}
        
        다음 형식으로 응답해주세요:
        
        [요약]
        (3-5문장으로 핵심 내용 요약)
        
        [키워드]
        (콤마로 구분된 5개의 핵심 키워드)
      PROMPT
    end
  end
  
  def build_keyword_prompt(content, type, metadata = {})
    case type
    when "youtube_video"
      "제목: #{metadata[:title]}\n채널: #{metadata[:channel]}\n설명: #{metadata[:description]}\n\n이 YouTube 동영상의 핵심 키워드를 5개 추출해주세요. 콤마로 구분해주세요."
    when "article"
      "다음 기사에서 핵심 키워드를 5개 추출해주세요. 콤마로 구분해주세요:\n\n#{content[0..1000]}"
    else
      "다음 내용에서 핵심 키워드를 5개 추출해주세요. 콤마로 구분해주세요:\n\n#{content[0..1000]}"
    end
  end
  
  def parse_response(response_text)
    return { summary: response_text, keywords: [] } unless response_text
    
    summary = ""
    keywords = []
    
    if response_text.include?("[요약]") && response_text.include?("[키워드]")
      parts = response_text.split(/\[요약\]|\[키워드\]/)
      summary = parts[1]&.strip || ""
      keywords_text = parts[2]&.strip || ""
      keywords = keywords_text.split(",").map(&:strip).first(5)
    else
      summary = response_text
    end
    
    { summary: summary, keywords: keywords }
  end
end