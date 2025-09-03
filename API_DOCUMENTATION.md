# Chrit API Documentation v1.0

## Base URL
```
Production: https://api.chrit.com
Development: http://localhost:5050
```

## Authentication
All API requests require authentication using Devise session cookies or API tokens.

### Headers
```http
Content-Type: application/json
Accept: application/json
X-CSRF-Token: [token from meta tag]
```

## API Endpoints

### Authentication Endpoints

#### POST /users/sign_in
**Description**: User login

**Request Body**:
```json
{
  "user": {
    "email": "user@example.com",
    "password": "password123"
  }
}
```

**Response** (200 OK):
```json
{
  "user": {
    "id": 1,
    "email": "user@example.com",
    "admin": false,
    "created_at": "2025-09-01T10:00:00Z"
  },
  "token": "jwt_token_here"
}
```

**Error Response** (401 Unauthorized):
```json
{
  "error": {
    "code": 1002,
    "message": "이메일 또는 비밀번호가 올바르지 않습니다."
  }
}
```

---

#### POST /users/sign_up
**Description**: User registration

**Request Body**:
```json
{
  "user": {
    "email": "newuser@example.com",
    "password": "securepassword123",
    "password_confirmation": "securepassword123"
  }
}
```

**Response** (201 Created):
```json
{
  "user": {
    "id": 2,
    "email": "newuser@example.com",
    "created_at": "2025-09-01T10:00:00Z"
  }
}
```

---

#### DELETE /users/sign_out
**Description**: User logout

**Response** (200 OK):
```json
{
  "message": "로그아웃되었습니다."
}
```

---

### Knowledge Management Endpoints

#### GET /knowledges
**Description**: Get user's knowledge list with pagination

**Query Parameters**:
- `page` (integer): Page number (default: 1)
- `per_page` (integer): Items per page (default: 20, max: 100)
- `status` (string): Filter by status (processing, completed, failed)
- `content_type` (string): Filter by type (youtube, article, thread)

**Response** (200 OK):
```json
{
  "knowledges": [
    {
      "id": 1,
      "title": "React 18 새로운 기능",
      "content_type": "youtube",
      "status": "completed",
      "summary": "React 18의 주요 기능...",
      "keywords": ["React", "JavaScript", "Frontend"],
      "original_url": "https://youtube.com/watch?v=xxx",
      "thumbnail_url": "https://i.ytimg.com/vi/xxx/maxresdefault.jpg",
      "credits_consumed": 3.5,
      "created_at": "2025-09-01T10:00:00Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 5,
    "total_count": 100,
    "per_page": 20
  }
}
```

---

#### GET /knowledges/:id
**Description**: Get detailed knowledge information

**Response** (200 OK):
```json
{
  "knowledge": {
    "id": 1,
    "title": "React 18 새로운 기능",
    "content": "Full transcript or article content...",
    "summary": "Detailed summary...",
    "keywords": ["React", "JavaScript", "Frontend"],
    "content_type": "youtube",
    "status": "completed",
    "original_url": "https://youtube.com/watch?v=xxx",
    "thumbnail_url": "https://i.ytimg.com/vi/xxx/maxresdefault.jpg",
    "metadata": {
      "channel": "React Official",
      "duration": 1234,
      "published_at": "2025-08-01T00:00:00Z"
    },
    "input_tokens": 5000,
    "output_tokens": 1500,
    "credits_consumed": 3.5,
    "created_at": "2025-09-01T10:00:00Z",
    "updated_at": "2025-09-01T10:05:00Z"
  }
}
```

---

#### POST /knowledges
**Description**: Process a new URL

**Request Body**:
```json
{
  "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
}
```

**Response** (202 Accepted):
```json
{
  "knowledge": {
    "id": 2,
    "status": "processing",
    "original_url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
    "estimated_credits": 2,
    "created_at": "2025-09-01T11:00:00Z"
  },
  "message": "URL 처리가 시작되었습니다."
}
```

**Error Response** (400 Bad Request):
```json
{
  "error": {
    "code": 3001,
    "message": "올바른 URL 형식이 아닙니다."
  }
}
```

**Error Response** (402 Payment Required):
```json
{
  "error": {
    "code": 2001,
    "message": "크레딧이 부족합니다. (필요: 2, 보유: 0.5)",
    "required_credits": 2,
    "available_credits": 0.5
  }
}
```

---

#### DELETE /knowledges/:id
**Description**: Delete a knowledge record

**Response** (200 OK):
```json
{
  "message": "삭제되었습니다."
}
```

---

### Search and Filter Endpoints

#### GET /knowledges/search
**Description**: Search knowledges by keyword

**Query Parameters**:
- `q` (string, required): Search query
- `type` (string): Filter by content type
- `status` (string): Filter by status
- `page` (integer): Page number

**Response** (200 OK):
```json
{
  "results": [
    {
      "id": 1,
      "title": "React 18 새로운 기능",
      "summary": "...",
      "content_type": "youtube",
      "score": 0.95
    }
  ],
  "meta": {
    "query": "React",
    "total_results": 15,
    "page": 1
  }
}
```

---

### Payment Endpoints

#### POST /payments/initialize
**Description**: Initialize payment process

**Request Body**:
```json
{
  "plan_type": "premium",
  "payment_method": "card"
}
```

**Response** (200 OK):
```json
{
  "order_id": "ORDER_20250901_001",
  "amount": 9900,
  "currency": "KRW",
  "payment_url": "https://pay.toss.im/..."
}
```

---

#### POST /payments/confirm
**Description**: Confirm payment completion

**Request Body**:
```json
{
  "payment_key": "PAYMENT_KEY_FROM_TOSS",
  "order_id": "ORDER_20250901_001",
  "amount": 9900
}
```

**Response** (200 OK):
```json
{
  "subscription": {
    "id": 1,
    "plan_type": "premium",
    "status": "active",
    "expires_at": "2025-10-01T00:00:00Z",
    "amount": 9900
  },
  "message": "결제가 완료되었습니다."
}
```

---

### Admin Endpoints (Requires admin: true)

#### GET /admin/dashboard
**Description**: Get admin dashboard statistics

**Response** (200 OK):
```json
{
  "stats": {
    "total_users": 1523,
    "active_users": 234,
    "total_knowledges": 45678,
    "processed_today": 567,
    "total_revenue": 1234567,
    "api_usage": {
      "gemini": {
        "calls": 12345,
        "tokens": 5678900,
        "cost_krw": 1234
      },
      "youtube": {
        "quota_used": 8500,
        "quota_limit": 10000
      }
    },
    "system_health": {
      "database": "healthy",
      "redis": "healthy",
      "sidekiq": {
        "processed": 98765,
        "failed": 23,
        "queued": 45
      }
    }
  }
}
```

---

## Error Codes Reference

| Code | Type | Description |
|------|------|-------------|
| **1xxx** | **Authentication Errors** |
| 1001 | Unauthorized | 인증되지 않은 요청 |
| 1002 | InvalidCredentials | 잘못된 인증 정보 |
| 1003 | EmailNotVerified | 이메일 미인증 |
| **2xxx** | **Credit Errors** |
| 2001 | InsufficientCredits | 크레딧 부족 |
| 2002 | CreditLimitExceeded | 월 한도 초과 |
| **3xxx** | **Processing Errors** |
| 3001 | InvalidUrl | 잘못된 URL 형식 |
| 3002 | UnsupportedDomain | 지원하지 않는 도메인 |
| 3003 | ContentNotFound | 콘텐츠 없음 |
| 3004 | TranscriptNotAvailable | 자막 없음 |
| **4xxx** | **API Errors** |
| 4001 | GeminiApiError | Gemini API 오류 |
| 4002 | ClaudeApiError | Claude API 오류 |
| 4003 | YouTubeApiError | YouTube API 오류 |
| 4004 | RateLimitExceeded | API 한도 초과 |
| **5xxx** | **System Errors** |
| 5001 | DatabaseError | DB 연결 오류 |
| 5002 | RedisConnectionError | Redis 오류 |
| 5003 | JobTimeout | 작업 시간 초과 |

## Rate Limiting

API requests are rate-limited to prevent abuse:

- **Authenticated users**: 100 requests per minute
- **URL processing**: 10 requests per minute
- **Search**: 30 requests per minute

Rate limit headers are included in responses:
```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1630454400
```

## Webhooks

Webhooks can be configured for real-time updates:

### Knowledge Processing Complete
```json
{
  "event": "knowledge.completed",
  "knowledge": {
    "id": 1,
    "status": "completed",
    "title": "...",
    "credits_consumed": 3.5
  },
  "timestamp": "2025-09-01T10:00:00Z"
}
```

### Payment Successful
```json
{
  "event": "payment.successful",
  "subscription": {
    "id": 1,
    "plan_type": "premium",
    "expires_at": "2025-10-01T00:00:00Z"
  },
  "timestamp": "2025-09-01T10:00:00Z"
}
```

## SDK Examples

### JavaScript/TypeScript
```javascript
const ChritAPI = {
  baseURL: 'https://api.chrit.com',
  
  async processURL(url) {
    const response = await fetch(`${this.baseURL}/knowledges`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': this.getCSRFToken()
      },
      credentials: 'include',
      body: JSON.stringify({ url })
    });
    
    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error.message);
    }
    
    return response.json();
  },
  
  getCSRFToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content;
  }
};
```

### Ruby
```ruby
require 'net/http'
require 'json'

class ChritClient
  BASE_URL = 'https://api.chrit.com'
  
  def initialize(api_key)
    @api_key = api_key
  end
  
  def process_url(url)
    uri = URI("#{BASE_URL}/knowledges")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Bearer #{@api_key}"
    request.body = { url: url }.to_json
    
    response = http.request(request)
    JSON.parse(response.body)
  end
end
```

## Testing

Use our sandbox environment for testing:
- Base URL: `https://sandbox.chrit.com`
- Test API Key: `test_key_xxx`
- Test Credit: 100 credits per day

---

**Version**: 1.0  
**Last Updated**: 2025-09-03  
**Contact**: api@chrit.com