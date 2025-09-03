class ErrorHandler
  class ChritError < StandardError
    attr_reader :code, :user_message, :internal_message, :metadata

    def initialize(code:, user_message:, internal_message: nil, metadata: {})
      @code = code
      @user_message = user_message
      @internal_message = internal_message || user_message
      @metadata = metadata
      super(@internal_message)
    end
  end

  # Authentication Errors (1xxx)
  class UnauthorizedError < ChritError
    def initialize(metadata = {})
      super(
        code: 1001,
        user_message: "인증되지 않은 요청입니다. 로그인이 필요합니다.",
        internal_message: "Unauthorized request",
        metadata: metadata
      )
    end
  end

  class InvalidCredentialsError < ChritError
    def initialize(metadata = {})
      super(
        code: 1002,
        user_message: "이메일 또는 비밀번호가 올바르지 않습니다.",
        internal_message: "Invalid credentials",
        metadata: metadata
      )
    end
  end

  class EmailNotVerifiedError < ChritError
    def initialize(metadata = {})
      super(
        code: 1003,
        user_message: "이메일 인증이 필요합니다.",
        internal_message: "Email not verified",
        metadata: metadata
      )
    end
  end

  # Credit Errors (2xxx)
  class InsufficientCreditsError < ChritError
    def initialize(required:, available:, metadata: {})
      super(
        code: 2001,
        user_message: "크레딧이 부족합니다. (필요: #{required}, 보유: #{available})",
        internal_message: "Insufficient credits",
        metadata: metadata.merge(required: required, available: available)
      )
    end
  end

  class CreditLimitExceededError < ChritError
    def initialize(limit:, used:, metadata: {})
      super(
        code: 2002,
        user_message: "월 한도를 초과했습니다. 플랜 업그레이드를 고려해주세요.",
        internal_message: "Monthly credit limit exceeded",
        metadata: metadata.merge(limit: limit, used: used)
      )
    end
  end

  # Processing Errors (3xxx)
  class InvalidUrlError < ChritError
    def initialize(url:, metadata: {})
      super(
        code: 3001,
        user_message: "올바른 URL 형식이 아닙니다.",
        internal_message: "Invalid URL format: #{url}",
        metadata: metadata.merge(url: url)
      )
    end
  end

  class UnsupportedDomainError < ChritError
    def initialize(domain:, metadata: {})
      super(
        code: 3002,
        user_message: "지원하지 않는 도메인입니다: #{domain}",
        internal_message: "Unsupported domain: #{domain}",
        metadata: metadata.merge(domain: domain)
      )
    end
  end

  class ContentNotFoundError < ChritError
    def initialize(url:, metadata: {})
      super(
        code: 3003,
        user_message: "콘텐츠를 찾을 수 없습니다.",
        internal_message: "Content not found for URL: #{url}",
        metadata: metadata.merge(url: url)
      )
    end
  end

  class TranscriptNotAvailableError < ChritError
    def initialize(video_id:, metadata: {})
      super(
        code: 3004,
        user_message: "자막을 사용할 수 없습니다.",
        internal_message: "Transcript not available for video: #{video_id}",
        metadata: metadata.merge(video_id: video_id)
      )
    end
  end

  # API Errors (4xxx)
  class GeminiApiError < ChritError
    def initialize(error:, metadata: {})
      super(
        code: 4001,
        user_message: "AI 처리 중 오류가 발생했습니다. 다시 시도합니다.",
        internal_message: "Gemini API error: #{error}",
        metadata: metadata.merge(original_error: error)
      )
    end
  end

  class ClaudeApiError < ChritError
    def initialize(error:, metadata: {})
      super(
        code: 4002,
        user_message: "백업 AI 처리 중 오류가 발생했습니다.",
        internal_message: "Claude API error: #{error}",
        metadata: metadata.merge(original_error: error)
      )
    end
  end

  class YouTubeApiError < ChritError
    def initialize(error:, metadata: {})
      super(
        code: 4003,
        user_message: "YouTube 데이터를 가져오는 중 오류가 발생했습니다.",
        internal_message: "YouTube API error: #{error}",
        metadata: metadata.merge(original_error: error)
      )
    end
  end

  class RateLimitExceededError < ChritError
    def initialize(service:, retry_after: nil, metadata: {})
      super(
        code: 4004,
        user_message: "일시적으로 API 한도에 도달했습니다. 잠시 후 다시 시도해주세요.",
        internal_message: "Rate limit exceeded for #{service}",
        metadata: metadata.merge(service: service, retry_after: retry_after)
      )
    end
  end

  # System Errors (5xxx)
  class DatabaseError < ChritError
    def initialize(error:, metadata: {})
      super(
        code: 5001,
        user_message: "시스템 오류가 발생했습니다. 잠시 후 다시 시도해주세요.",
        internal_message: "Database error: #{error}",
        metadata: metadata.merge(original_error: error)
      )
    end
  end

  class RedisConnectionError < ChritError
    def initialize(error:, metadata: {})
      super(
        code: 5002,
        user_message: "캐시 서버 연결 오류가 발생했습니다.",
        internal_message: "Redis connection error: #{error}",
        metadata: metadata.merge(original_error: error)
      )
    end
  end

  class JobTimeoutError < ChritError
    def initialize(job_class:, timeout:, metadata: {})
      super(
        code: 5003,
        user_message: "처리 시간이 초과되었습니다. 작업을 다시 시도합니다.",
        internal_message: "Job timeout: #{job_class} after #{timeout}s",
        metadata: metadata.merge(job_class: job_class, timeout: timeout)
      )
    end
  end

  class << self
    def handle_error(error, context = {})
      case error
      when ChritError
        log_error(error, context)
        error
      when ActiveRecord::RecordNotFound
        not_found_error = ChritError.new(
          code: 404,
          user_message: "요청한 리소스를 찾을 수 없습니다.",
          internal_message: error.message
        )
        log_error(not_found_error, context)
        not_found_error
      else
        generic_error = ChritError.new(
          code: 500,
          user_message: "예기치 않은 오류가 발생했습니다.",
          internal_message: error.message
        )
        log_error(generic_error, context)
        generic_error
      end
    end

    private

    def log_error(error, context)
      Rails.logger.error({
        error_code: error.code,
        error_message: error.internal_message,
        user_message: error.user_message,
        metadata: error.metadata,
        context: context,
        backtrace: error.backtrace&.first(10)
      }.to_json)
    end
  end
end