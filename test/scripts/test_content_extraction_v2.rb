#!/usr/bin/env rails runner

# Iteration 2: Improved test script with better handling
require 'json'

def test_youtube_url
  puts "\n=== Testing YouTube URL Processing ==="
  urls = [
    "https://www.youtube.com/watch?v=jNQXAC9IVRw", # Me at the zoo
    "https://www.youtube.com/watch?v=dQw4w9WgXcQ", # Rick Roll
    "https://www.youtube.com/watch?v=9bZkp7q19f0"  # Gangnam Style
  ]
  
  user = User.first
  unless user
    puts "No user found. Creating test user..."
    user = User.create!(email: "test@example.com", password: "password123")
  end
  
  # Find an unprocessed URL
  url = urls.find { |u| !user.knowledges.exists?(original_url: u) }
  
  if url.nil?
    puts "All test URLs already processed. Using the first one to check data."
    knowledge = user.knowledges.find_by(original_url: urls.first)
    
    if knowledge
      puts "\n--- Existing Knowledge ---"
      puts "Status: #{knowledge.status}"
      puts "Title: #{knowledge.title}"
      puts "Content: #{knowledge.content.present? ? "✓ (#{knowledge.content.length} chars)" : "✗ MISSING"}"
      puts "Summary: #{knowledge.summary.present? ? "✓ (#{knowledge.summary.length} chars)" : "✗ MISSING"}"
      return knowledge.content.present?
    end
    return false
  end
  
  puts "Testing URL: #{url}"
  
  # Create Knowledge record
  knowledge = user.knowledges.create!(
    original_url: url,
    status: "processing"
  )
  
  puts "Created Knowledge ##{knowledge.id}"
  
  # Process directly
  begin
    YoutubeProcessorJob.perform_now(knowledge)
    knowledge.reload
    
    puts "\n--- Results ---"
    puts "Status: #{knowledge.status}"
    puts "Title: #{knowledge.title}"
    puts "Content: #{knowledge.content.present? ? "✓ (#{knowledge.content.length} chars)" : "✗ MISSING"}"
    puts "Summary: #{knowledge.summary.present? ? "✓ (#{knowledge.summary.length} chars)" : "✗ MISSING"}"
    
    return knowledge.content.present?
  rescue => e
    puts "Error: #{e.message}"
    return false
  end
end

def test_article_url
  puts "\n=== Testing Article URL Processing ==="
  urls = [
    "https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/overview",
    "https://medium.com/@evgeniy.lebedev/rust-made-easy-a-simple-guide-for-beginners-1fb1e38f8c77",
    "https://dev.to/ben/why-dev-is-the-best-place-to-blog-47ie"
  ]
  
  user = User.first
  
  # Find an unprocessed URL
  url = urls.find { |u| !user.knowledges.exists?(original_url: u) }
  
  if url.nil?
    puts "All test URLs already processed. Checking Knowledge #15 for fix verification."
    knowledge = Knowledge.find(15) rescue nil
    
    if knowledge
      puts "\n--- Checking Previously Failed Article ---"
      puts "Retrying processing for Knowledge ##{knowledge.id}"
      
      begin
        ArticleProcessorJob.perform_now(knowledge)
        knowledge.reload
        
        puts "Status: #{knowledge.status}"
        puts "Content: #{knowledge.content.present? ? "✓ (#{knowledge.content.length} chars)" : "✗ MISSING"}"
        puts "Summary: #{knowledge.summary.present? ? "✓ (#{knowledge.summary.length} chars)" : "✗ MISSING"}"
        
        return knowledge.content.present?
      rescue => e
        puts "Error: #{e.message}"
        return false
      end
    end
    return false
  end
  
  puts "Testing URL: #{url}"
  
  # Create Knowledge record
  knowledge = user.knowledges.create!(
    original_url: url,
    status: "processing"
  )
  
  puts "Created Knowledge ##{knowledge.id}"
  
  # Process directly
  begin
    ArticleProcessorJob.perform_now(knowledge)
    knowledge.reload
    
    puts "\n--- Results ---"
    puts "Status: #{knowledge.status}"
    puts "Title: #{knowledge.title}"
    puts "Content: #{knowledge.content.present? ? "✓ (#{knowledge.content.length} chars)" : "✗ MISSING"}"
    puts "Summary: #{knowledge.summary.present? ? "✓ (#{knowledge.summary.length} chars)" : "✗ MISSING"}"
    
    return knowledge.content.present?
  rescue => e
    puts "Error: #{e.message}"
    puts e.backtrace.first(3).join("\n")
    return false
  end
end

def check_processing_statistics
  puts "\n=== Processing Statistics ==="
  
  total = Knowledge.count
  completed = Knowledge.where(status: 'completed').count
  failed = Knowledge.where(status: 'failed').count
  processing = Knowledge.where(status: 'processing').count
  
  youtube_with_content = Knowledge.where(content_type: 'youtube').where.not(content: [nil, '']).count
  youtube_total = Knowledge.where(content_type: 'youtube').count
  
  article_with_content = Knowledge.where(content_type: 'article').where.not(content: [nil, '']).count
  article_total = Knowledge.where(content_type: 'article').count
  
  puts "Total Knowledge records: #{total}"
  puts "  Completed: #{completed} (#{(completed.to_f/total*100).round(1)}%)"
  puts "  Failed: #{failed} (#{(failed.to_f/total*100).round(1)}%)"
  puts "  Processing: #{processing} (#{(processing.to_f/total*100).round(1)}%)"
  puts ""
  puts "YouTube videos:"
  puts "  With content: #{youtube_with_content}/#{youtube_total} (#{youtube_total > 0 ? (youtube_with_content.to_f/youtube_total*100).round(1) : 0}%)"
  puts "Articles:"
  puts "  With content: #{article_with_content}/#{article_total} (#{article_total > 0 ? (article_with_content.to_f/article_total*100).round(1) : 0}%)"
end

# Run tests
puts "=" * 60
puts "Content Extraction Test Suite - Iteration 2"
puts "=" * 60

# Check statistics
check_processing_statistics

# Test YouTube
youtube_success = test_youtube_url

# Test Article
article_success = test_article_url

# Summary
puts "\n" + "=" * 60
puts "Test Results Summary - Iteration 2"
puts "=" * 60
puts "YouTube content extraction: #{youtube_success ? '✓ PASSED' : '✗ FAILED'}"
puts "Article content extraction: #{article_success ? '✓ PASSED' : '✗ FAILED'}"

if youtube_success && article_success
  puts "\n✓ All tests passed! Content is being properly extracted and saved."
  puts "The retry configuration fix was successful."
else
  puts "\n✗ Some tests failed. Continuing to iteration 3 for improvements."
end