#!/bin/bash

# Chrit Server Startup Script

echo "Starting Chrit server..."
echo ""

# Check Redis
echo "Checking Redis..."
if ! pgrep -x "redis-server" > /dev/null
then
    echo "   Starting Redis..."
    redis-server &
    sleep 2
else
    echo "   Redis is already running."
fi

# Start Sidekiq
echo ""
echo "Starting Sidekiq..."
bundle exec sidekiq &
SIDEKIQ_PID=$!
echo "   Sidekiq started (PID: $SIDEKIQ_PID)"

# Start Rails server
echo ""
echo "Starting Rails server..."
echo "   Server address: http://localhost:5050"
echo ""
echo "Press Ctrl+C to stop"
echo "----------------------------------------"
echo ""

rails server -p 5050

# Cleanup on exit
kill $SIDEKIQ_PID 2>/dev/null