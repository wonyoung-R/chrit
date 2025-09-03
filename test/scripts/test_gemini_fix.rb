#!/usr/bin/env ruby
# Test script for Gemini API integration fixes

require_relative 'config/environment'

puts "=" * 60
puts "Testing Gemini API Integration Fixes"
puts "=" * 60

# Test 1: GeminiService with text content
puts "\n[TEST 1] GeminiService - Text Analysis"
puts "-" * 40

begin
  gemini = GeminiService.new
  
  sample_text = <<~TEXT
    인공지능(AI)은 현대 기술의 핵심이 되었습니다. 
    머신러닝과 딥러닝의 발전으로 AI는 이미지 인식, 자연어 처리, 
    예측 분석 등 다양한 분야에서 놀라운 성과를 보이고 있습니다.
    특히 최근 등장한 대규모 언어 모델(LLM)은 인간과 유사한 수준의 
    텍스트 생성과 이해 능력을 보여주고 있어 많은 주목을 받고 있습니다.
  TEXT
  
  result = gemini.summarize_content(sample_text, type: 'article')
  
  if result
    puts "✅ Success! Summary generated:"
    puts "  Summary: #{result[:summary]&.first(100)}..."
    puts "  Keywords: #{result[:keywords]&.join(', ')}"
  else
    puts "❌ Failed to generate summary"
  end
rescue => e
  puts "❌ Error: #{e.message}"
end

# Test 2: YouTube transcript analysis
puts "\n[TEST 2] YouTube Transcript Analysis"
puts "-" * 40

begin
  gemini = GeminiService.new
  
  sample_transcript = <<~TEXT
    안녕하세요, 오늘은 Ruby on Rails 8.0의 새로운 기능에 대해 알아보겠습니다.
    Rails 8.0은 성능 개선과 개발자 경험 향상에 중점을 두었습니다.
    특히 Solid Queue와 Solid Cache가 기본으로 포함되어 
    Redis 없이도 백그라운드 작업과 캐싱을 처리할 수 있게 되었습니다.
  TEXT
  
  metadata = {
    title: "Rails 8.0 새로운 기능 소개",
    channel: "Ruby Korea",
    duration: 600
  }
  
  result = gemini.analyze_youtube_transcript(sample_transcript, metadata)
  
  if result
    puts "✅ Success! YouTube analysis completed:"
    puts "  Summary: #{result[:summary]&.first(100)}..."
    puts "  Keywords: #{result[:keywords]&.join(', ')}"
    puts "  Target Audience: #{result[:target_audience]&.first(50)}..."
  else
    puts "❌ Failed to analyze transcript"
  end
rescue => e
  puts "❌ Error: #{e.message}"
end

# Test 3: Article content analysis
puts "\n[TEST 3] Article Content Analysis"
puts "-" * 40

begin
  gemini = GeminiService.new
  
  sample_article = <<~TEXT
    # Understanding Microservices Architecture
    
    Microservices architecture has become increasingly popular in recent years.
    This architectural style structures an application as a collection of 
    loosely coupled services, which implement business capabilities.
    
    ## Benefits
    - Independent deployment
    - Technology diversity
    - Fault isolation
    - Easy scaling
    
    ## Challenges
    - Distributed system complexity
    - Network latency
    - Data consistency
  TEXT
  
  metadata = {
    url: "https://example.com/microservices",
    title: "Understanding Microservices",
    author: "John Doe",
    published_date: "2024-09-01"
  }
  
  result = gemini.analyze_article_content(sample_article, metadata)
  
  if result
    puts "✅ Success! Article analysis completed:"
    puts "  Topic: #{result[:topic]}"
    puts "  Summary: #{result[:summary]&.first(100)}..."
    puts "  Keywords: #{result[:keywords]&.join(', ')}"
    puts "  Usefulness: #{result[:usefulness]&.first(50)}..."
  else
    puts "❌ Failed to analyze article"
  end
rescue => e
  puts "❌ Error: #{e.message}"
end

puts "\n" + "=" * 60
puts "Test Complete!"
puts "=" * 60

# Check if Gemini API key is set
if ENV['GEMINI_API_KEY'].present?
  puts "✅ Gemini API key is configured"
else
  puts "⚠️  Warning: GEMINI_API_KEY not found in environment"
end