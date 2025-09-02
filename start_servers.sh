#!/bin/bash

# Chrit 서버 시작 스크립트

echo "🚀 Chrit 서버를 시작합니다..."
echo ""

# Redis 시작 (이미 실행 중이면 무시)
echo "1️⃣ Redis 확인 중..."
if ! pgrep -x "redis-server" > /dev/null
then
    echo "   Redis를 시작합니다..."
    redis-server &
    sleep 2
else
    echo "   ✅ Redis가 이미 실행 중입니다."
fi

# Sidekiq 시작
echo ""
echo "2️⃣ Sidekiq 시작..."
bundle exec sidekiq &
SIDEKIQ_PID=$!
echo "   ✅ Sidekiq 시작됨 (PID: $SIDEKIQ_PID)"

# Rails 서버 시작
echo ""
echo "3️⃣ Rails 서버 시작..."
echo "   서버 주소: http://localhost:5050"
echo ""
echo "📌 종료하려면 Ctrl+C를 누르세요"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

rails server -p 5050

# 종료 시 Sidekiq도 종료
kill $SIDEKIQ_PID 2>/dev/null