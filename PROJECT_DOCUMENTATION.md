# Chrit - 지식 관리 서비스 개발 문서

## 📋 프로젝트 개요

### 서비스명: Chrit

### 핵심 컨셉
사용자가 YouTube 동영상이나 웹 기사의 URL을 입력하면 자동으로 콘텐츠를 저장하고 AI가 요약해주는 지식 관리 서비스

### 주요 특징
- **간단한 UX**: 로그인 후 URL만 붙여넣으면 자동으로 모든 처리 완료
- **AI 요약**: Claude API를 활용한 한국어 콘텐츠 요약
- **미니멀 디자인**: 광고 없는 깔끔한 인터페이스
- **다크 테마**: 글래스모피즘 효과를 활용한 모던한 디자인

## 🛠 기술 스택

### Backend
- **Framework**: Ruby on Rails 8.0.2
- **Database**: PostgreSQL 15
- **Authentication**: Devise
- **Background Jobs**: Sidekiq with Redis
- **Ruby Version**: 3.2.2

### Frontend
- **CSS Framework**: Tailwind CSS
- **Interactivity**: Turbo, Stimulus
- **Design Pattern**: 다크 테마 + 글래스모피즘

### External APIs
- **YouTube Data API v3**: 동영상 메타데이터 및 자막 추출
- **Anthropic Claude API**: AI 기반 콘텐츠 요약
- **HTTParty**: HTTP 요청 처리

## 🎨 디자인 시스템

### 핵심 디자인 철학
- **Dark Mode First**: 검은 배경에 섬세한 색상 포인트
- **Glassmorphism**: 반투명 요소와 백드롭 블러 효과
- **Gradient Accents**: 보라색에서 파란색으로 이어지는 그라디언트
- **Smooth Animations**: 부드러운 전환과 호버 효과
- **Minimalist Layout**: 콘텐츠에 집중할 수 있는 깔끔한 레이아웃

### 색상 팔레트
```css
/* Primary Colors */
Background: #000000 (bg-black)
Primary Gradient: from-purple-600 to-blue-600
Text Primary: text-white
Text Secondary: text-gray-400

/* Glass Effect */
Card Background: bg-gray-900/50 with backdrop-blur-sm
Border: border-gray-800
Hover Border: border-purple-500/50
```

### 주요 컴포넌트 패턴

#### Glass Card
```html
<div class="bg-gray-900/50 backdrop-blur-sm border border-gray-800 rounded-2xl p-6">
  <!-- Content -->
</div>
```

#### Primary Button
```html
<button class="px-6 py-3 bg-gradient-to-r from-purple-600 to-blue-600 text-white rounded-xl hover:from-purple-700 hover:to-blue-700">
  Button Text
</button>
```

#### Animated Background
```html
<div class="absolute inset-0 bg-gradient-to-br from-purple-900/20 via-black to-blue-900/20"></div>
<div class="absolute top-1/4 left-1/4 w-96 h-96 bg-purple-600/10 rounded-full blur-3xl animate-pulse"></div>
```

## 📁 프로젝트 구조

```
chrit/
├── app/
│   ├── controllers/
│   │   ├── application_controller.rb
│   │   ├── dashboard_controller.rb
│   │   └── knowledges_controller.rb
│   ├── models/
│   │   ├── user.rb
│   │   └── knowledge.rb
│   ├── services/
│   │   ├── youtube_processor.rb
│   │   ├── article_processor.rb
│   │   └── ai_summarizer.rb
│   ├── jobs/
│   │   └── process_knowledge_job.rb
│   └── views/
│       ├── dashboard/
│       │   └── index.html.erb (메인 대시보드)
│       ├── knowledges/
│       │   └── show.html.erb (지식 상세 페이지)
│       └── devise/
│           ├── sessions/new.html.erb (로그인)
│           └── registrations/new.html.erb (회원가입)
├── config/
│   ├── routes.rb
│   ├── credentials.yml.enc
│   └── database.yml
├── db/
│   ├── migrate/
│   └── seeds.rb
└── DESIGN_SYSTEM.md (디자인 시스템 문서)
```

## 🗄 데이터베이스 스키마

### Users 테이블
```ruby
create_table :users do |t|
  t.string :email, null: false
  t.string :encrypted_password, null: false
  t.timestamps
end
```

### Knowledges 테이블
```ruby
create_table :knowledges do |t|
  t.references :user, foreign_key: true
  t.string :original_url, null: false
  t.string :title
  t.text :content
  t.text :summary
  t.string :content_type # 'youtube' or 'article'
  t.string :thumbnail_url
  t.string :duration
  t.string :status, default: 'processing'
  t.timestamps
end
```

## 🔄 핵심 워크플로우

### URL 처리 프로세스
1. **사용자 입력**: 메인 대시보드에서 URL 입력
2. **URL 유효성 검사**: YouTube 또는 일반 웹사이트 URL 구분
3. **Knowledge 생성**: 데이터베이스에 'processing' 상태로 저장
4. **백그라운드 작업 시작**: Sidekiq을 통한 비동기 처리
5. **콘텐츠 추출**:
   - YouTube: API를 통한 메타데이터 및 자막 추출
   - Article: 웹 스크래핑을 통한 본문 추출
6. **AI 요약**: Claude API를 통한 한국어 요약 생성
7. **저장 완료**: status를 'completed'로 업데이트
8. **사용자 알림**: Turbo Streams를 통한 실시간 UI 업데이트

### 서비스 아키텍처
```
User Input → Rails Controller → Background Job
                                      ↓
                              Content Processor
                              (YouTube/Article)
                                      ↓
                                AI Summarizer
                                (Claude API)
                                      ↓
                              Database Update
                                      ↓
                              Real-time UI Update
```

## 🔑 API 설정

### YouTube Data API
- **API Key**: 환경변수 또는 Rails credentials에 저장
- **용도**: 동영상 메타데이터, 썸네일, 자막 추출

### Anthropic Claude API
- **API Key**: Rails credentials에 안전하게 저장
- **용도**: 콘텐츠 요약 생성 (한국어)
- **모델**: Claude 3 Haiku

## 🚀 개발 환경 설정

### 필수 요구사항
- Ruby 3.2.2
- Rails 8.0+
- PostgreSQL 15
- Redis (Sidekiq용)
- Node.js (Asset Pipeline)

### 설치 및 실행
```bash
# 의존성 설치
bundle install
npm install

# 데이터베이스 설정
rails db:create
rails db:migrate
rails db:seed  # 테스트 계정 생성

# Redis 시작 (별도 터미널)
redis-server

# Sidekiq 시작 (별도 터미널)
bundle exec sidekiq

# Rails 서버 시작 (포트 5050)
rails server -p 5050
```

### 테스트 계정
- Email: test@test.com
- Password: 123123

## 📊 현재 개발 상태

### ✅ 완료된 기능
- [x] Rails 애플리케이션 기본 구조
- [x] PostgreSQL 데이터베이스 설정
- [x] Devise 인증 시스템
- [x] 다크 테마 UI/UX 디자인
- [x] 글래스모피즘 효과 구현
- [x] 메인 대시보드 페이지
- [x] 로그인/회원가입 페이지
- [x] Knowledge 상세 페이지
- [x] 백그라운드 작업 구조 (Sidekiq)
- [x] YouTube/Article 프로세서 서비스
- [x] AI 요약 서비스 (Claude API)
- [x] 디자인 시스템 문서화

### 🔄 진행 중
- [ ] 실시간 처리 상태 업데이트 (Turbo Streams)
- [ ] URL 중복 체크 기능

### 📋 예정 기능
- [ ] 검색 기능
- [ ] 태그/카테고리 시스템
- [ ] 지식 공유 기능
- [ ] 팀 협업 기능
- [ ] 모바일 반응형 최적화
- [ ] PWA 지원

## 🎯 핵심 가치

1. **단순함**: 복잡한 기능보다 핵심 기능에 집중
2. **속도**: 빠른 콘텐츠 처리와 요약
3. **디자인**: 광고 없는 깔끔하고 모던한 인터페이스
4. **사용성**: 최소한의 클릭으로 원하는 결과 도출

## 📝 개발 노트

### 주요 결정 사항
1. **Rails 선택 이유**: 빠른 프로토타이핑과 안정적인 생산성
2. **다크 테마 채택**: 눈의 피로 감소와 모던한 느낌
3. **Sidekiq 사용**: 긴 처리 시간이 필요한 작업의 비동기 처리
4. **Claude API 선택**: 우수한 한국어 요약 능력

### 개선 사항
- 초기 미니멀 디자인에서 글래스모피즘 효과를 활용한 리치 디자인으로 전환
- 일본어 텍스트를 한국어로 통일
- 포트를 3000에서 5050으로 변경하여 충돌 방지

## 📞 문의 및 기여

이 프로젝트는 지속적으로 개선되고 있습니다. 
피드백과 제안은 언제나 환영합니다.

---

*Last Updated: 2025년 1월*
*Version: 1.0.0*