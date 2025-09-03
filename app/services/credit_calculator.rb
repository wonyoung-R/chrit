class CreditCalculator
  # Credit calculation rates as per specification
  CREDIT_RATES = {
    input_tokens: 1.0 / 2000,   # 1 credit per 2000 input tokens
    output_tokens: 1.0 / 667,   # 1 credit per 667 output tokens
    youtube_base: 2.0,          # YouTube base: 2 credits
    article_base: 1.0,          # Article base: 1 credit
    thread_base: 1.5            # Thread base: 1.5 credits
  }.freeze
  
  # 최대 크레딧 한도
  MAX_CREDITS = 10
  
  def initialize(knowledge)
    @knowledge = knowledge
  end
  
  def calculate
    base = base_credit
    token_cost = token_credit
    complexity = complexity_bonus
    
    total = base + token_cost + complexity
    
    # 최대 10 크레딧으로 제한
    [total.ceil, MAX_CREDITS].min
  end
  
  def detailed_breakdown
    {
      base_credit: base_credit,
      token_credit: token_credit,
      complexity_bonus: complexity_bonus,
      total: calculate,
      input_tokens: @knowledge.input_tokens || 0,
      output_tokens: @knowledge.output_tokens || 0
    }
  end
  
  private
  
  def base_credit
    case @knowledge.content_type
    when 'youtube'
      CREDIT_RATES[:youtube_base]
    when 'thread'
      CREDIT_RATES[:thread_base]
    else
      CREDIT_RATES[:article_base]
    end
  end
  
  def token_credit
    input_tokens = @knowledge.input_tokens || 0
    output_tokens = @knowledge.output_tokens || 0
    
    input_credit = input_tokens * CREDIT_RATES[:input_tokens]
    output_credit = output_tokens * CREDIT_RATES[:output_tokens]
    
    (input_credit + output_credit).round(2)
  end
  
  def complexity_bonus
    bonus = 0
    
    # 코드 블록 포함 시 +1
    if @knowledge.content&.include?('```')
      bonus += 1
    end
    
    # 키워드가 10개 이상이면 +1
    if @knowledge.keywords.present?
      keywords_count = begin
        JSON.parse(@knowledge.keywords).size
      rescue
        0
      end
      bonus += 1 if keywords_count >= 10
    end
    
    # 긴 콘텐츠 (10,000자 이상) +1
    if @knowledge.content&.length.to_i > 10000
      bonus += 1
    end
    
    # YouTube 비디오가 10분 이상이면 +1
    if @knowledge.content_type == 'youtube' && @knowledge.duration.to_i > 600
      bonus += 1
    end
    
    bonus
  end
  
  # API 비용 계산 (원화 기준)
  def api_cost_in_won
    input_tokens = @knowledge.input_tokens || 0
    output_tokens = @knowledge.output_tokens || 0
    
    # Gemini 1.5 Flash 요금 (₩ 기준)
    # Input: ₩100 per 1M tokens
    # Output: ₩400 per 1M tokens
    
    input_cost = (input_tokens / 1_000_000.0) * 100
    output_cost = (output_tokens / 1_000_000.0) * 400
    
    (input_cost + output_cost).round(2)
  end
end