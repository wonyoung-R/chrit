# CHRIT / 찌릿

DB 없이 동작하는 정적 미니게임 허브입니다. 라이브 사이트 점검에서 확인한 문제를 반영해 다음을 우선 구현했습니다.

- 모바일/데스크톱에서 스크롤 가능한 게임 허브
- 24개 게임 카드와 게임별 해시 링크
- 결과 화면의 공유/광고 CTA
- 로컬 기록 저장(localStorage)
- SEO/OG/Twitter 메타, favicon, manifest, 구조화 데이터
- DB 없이 브라우저 이벤트만 발생시키는 분석 훅

## 실행

정적 파일이라 `index.html`을 바로 열어도 됩니다. 로컬 서버로 확인하려면:

```bash
python3 -m http.server 4173
```

그리고 브라우저에서 `http://localhost:4173`을 엽니다.

## 분석 이벤트

서버 전송은 하지 않고, 아래 커스텀 이벤트만 발생합니다.

- `game_start`
- `game_result`
- `share_copy`
- `ad_click`

필요하면 추후 광고/분석 도구에서 이 이벤트를 받아 연결하면 됩니다.
