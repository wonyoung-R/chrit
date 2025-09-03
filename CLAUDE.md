# Chrit - AI 기반 지식 관리 서비스

## 프로젝트 개요
Rails 8.0.2.1 기반의 AI 지식 관리 서비스로, YouTube 비디오와 웹 문서를 자동으로 요약하고 저장합니다.

## 주요 기능

### 1. 사용자 인증 및 관리
- **Devise 기반 인증**: 이메일/비밀번호 로그인
- **이메일 중심 아키텍처**: 각 사용자의 데이터는 이메일별로 완전히 격리
- **크레딧 시스템**: 월별 사용량 추적 및 제한
- **이메일 인증**: 선택적 이메일 인증 기능

### 2. 콘텐츠 처리
- **YouTube 비디오**: YouTube Data API v3를 통한 메타데이터 및 자막 추출
- **웹 문서**: 웹 페이지 스크래핑 및 콘텐츠 추출
- **AI 요약**: Gemini API (primary) / Anthropic Claude (fallback)를 통한 자동 요약
- **백그라운드 처리**: Sidekiq을 통한 비동기 작업 처리

### 3. UI/UX 특징
- **한국어 UI**: 완전한 한국어 지원
- **AI 처리 애니메이션**: 10초 동안 표시되는 한국어 AI 애니메이션
- **다크 테마**: 검정색 배경의 모던한 디자인
- **실시간 피드백**: Turbo/Stimulus를 통한 반응형 인터페이스

### 4. 대시보드 기능
- **통계 표시**: 전체 저장, YouTube/기사 개수, 이번 달 사용량
- **크레딧 상태**: 남은 크레딧 시각화
- **검색 및 필터링**: 콘텐츠 타입별 필터링
- **복사 기능**: 요약 및 URL 원클릭 복사
- **삭제 기능**: 확인 다이얼로그와 함께 안전한 삭제

## 기술 스택

### Backend
- Ruby on Rails 8.0.2.1
- PostgreSQL (JSONB 필드 활용)
- Sidekiq (백그라운드 작업)
- Redis (Sidekiq 큐)

### Frontend
- Turbo 8 (SPA-like 경험)
- Stimulus.js (JavaScript 프레임워크)
- Tailwind CSS (스타일링)
- Propshaft (애셋 파이프라인)

### AI/API 통합
- Google Gemini API (주요 AI 엔진)
- Anthropic Claude API (백업)
- YouTube Data API v3
- HTTParty (HTTP 요청)
- Nokogiri (HTML 파싱)

## 데이터베이스 구조

### 주요 모델
```ruby
# User (Devise)
- email
- encrypted_password
- has_one :user_setting
- has_many :knowledges
- has_many :usage_trackings

# Knowledge
- user_id
- title
- content (text)
- summary (text)
- keywords (json)
- original_url
- content_type (youtube/article/thread)
- status (processing/completed/failed)
- metadata (jsonb)
- thumbnail_url
- duration (integer)
- published_at

# UserSetting
- user_id
- monthly_credit_limit (default: 50)
- used_credits (default: 0)
- email_verified (boolean)
- privacy_mode (enum)
- notification_preferences (jsonb)

# UsageTracking
- user_id
- month (date)
- credits_used
- urls_processed
```

## 주요 서비스 클래스

### YoutubeService
- YouTube 비디오 메타데이터 추출
- 자막/트랜스크립트 가져오기 (3단계 폴백)
- 비디오 정보 파싱

### DocumentationExtractor
- 웹 페이지 콘텐츠 추출
- 구조화된 문서 파싱
- 코드 예제 추출

### GeminiService
- Gemini API 통합
- YouTube 트랜스크립트 분석
- 웹 콘텐츠 요약

### AiSummarizer
- Anthropic Claude API 통합 (폴백)
- 콘텐츠 요약 생성

## 백그라운드 작업

### UrlProcessorJob
- URL 타입 판별
- 적절한 프로세서로 라우팅

### YoutubeProcessorJob
- YouTube 비디오 처리
- 메타데이터 및 자막 추출
- AI 요약 생성
- 재시도 로직 (5초 간격, 3회)

### DocumentProcessorJob
- 웹 문서 처리
- 콘텐츠 추출 및 요약

## 보안 및 성능

### 보안
- CSRF 보호
- 이메일별 데이터 격리
- API 키 환경 변수 관리
- SQL 인젝션 방지 (Rails ORM)

### 성능 최적화
- 백그라운드 작업 처리
- Redis 캐싱
- 데이터베이스 인덱싱
- JSONB 필드 활용

## 설정 및 환경변수

### 필수 환경변수
```bash
YOUTUBE_API_KEY=your_youtube_api_key
GEMINI_API_KEY=your_gemini_api_key
ANTHROPIC_API_KEY=your_anthropic_api_key (optional)
REDIS_URL=redis://localhost:6379/1
```

### 서버 실행
```bash
# Rails 서버 (포트 5050)
bundle exec rails server -b 0.0.0.0 -p 5050

# Sidekiq 워커
bundle exec sidekiq

# Redis 서버
redis-server
```

## 최근 수정 사항

### 2025-09-02
1. **YouTube 처리 개선**
   - `list_captions` API 호출 오류 수정
   - 재시도 로직 개선 (exponentially_longer → 5초 고정)
   - 트랜스크립트 메서드 접근성 수정 (private → public)

2. **UI 애니메이션**
   - AI 처리 애니메이션 시간 연장 (4초 → 10초)
   - 한국어 메시지 추가

3. **대시보드 기능 추가**
   - 삭제 기능 구현
   - 요약/URL 복사 버튼 추가
   - Clipboard Stimulus 컨트롤러 생성

4. **에러 처리**
   - RecordNotFound 예외 처리
   - 삭제된 Knowledge 접근 시 리다이렉트

## 개발 노트

### 처리 시간
- YouTube 비디오: 약 8-10초
- 웹 문서: 약 3-5초
- AI 요약: 5-10초 추가

### 크레딧 시스템
- 기본 월 한도: 50 크레딧
- URL 하나당: 1 크레딧 소비
- 매월 초기화

## 최근 구현 사항 (2025-09-02)

### 1. 크레딧 시스템 개선
- **가입 시 10 크레딧 제공**: 기본 플랜 사용자에게 10 크레딧 제공
- **토큰 기반 크레딧 계산**: 하이브리드 방식 (기본 크레딧 + 토큰 사용량)
  - YouTube: 기본 2 크레딧 + 토큰 비용
  - Article: 기본 1 크레딧 + 토큰 비용
  - 입력 토큰: 2000 토큰당 1 크레딧
  - 출력 토큰: 667 토큰당 1 크레딧

### 2. 토스 페이먼츠 결제 시스템
- **구독 모델**: Subscription 모델 구현
- **플랜 타입**: Free (10), Pro (100), Business (500) 크레딧
- **결제 프로세스**: 
  - 토스 페이먼츠 SDK 통합
  - 결제 초기화 → 결제창 → 성공/실패 콜백
- **구독 관리**: 활성화, 취소, 갱신 기능

### 3. 관리자 대시보드
- **통계 개요**: 사용자, 콘텐츠, 구독, 수익 통계
- **실시간 모니터링**: 
  - 최근 가입 사용자
  - 최근 처리된 콘텐츠
  - 처리 상태 분포
  - 에러 로그
- **상세 관리 페이지**:
  - 사용자 관리 (플랜별 필터, 검색)
  - 콘텐츠 관리 (상태/타입별 필터)
  - 구독 관리 (상태/플랜별 필터)
  - 분석 페이지 (월별 추세, 토큰 사용량)
- **디자인**: shadcn 디자인 패턴 적용

### 4. 데이터베이스 스키마 업데이트
```ruby
# Subscription 모델 추가
- plan_type (free/pro/business)
- status (pending/active/expired/cancelled/failed)
- payment_method
- toss_order_id, toss_payment_key
- amount, expires_at

# Knowledge 모델 확장
- input_tokens, output_tokens
- credits_consumed

# UserSetting 모델 확장
- plan_type (free/pro/business)
- monthly_credit_limit (10/100/500)

# User 모델 확장
- admin (boolean) - 관리자 권한
```

### 향후 개선 사항
- [ ] 실시간 결제 검증 개선
- [ ] 자동 구독 갱신 기능
- [ ] 사용량 알림 기능
- [ ] API 제공
- [ ] 팀 계정 기능
- [ ] 대량 처리 기능
- [ ] 웹훅 통합