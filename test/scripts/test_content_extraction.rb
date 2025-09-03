#!/usr/bin/env rails runner

# Test script to verify URL content extraction
require 'json'

def test_youtube_url
  puts "\n=== Testing YouTube URL Processing ==="
  url = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
  puts "Testing URL: #{url}"
  
  user = User.first
  unless user
    puts "No user found. Creating test user..."
    user = User.create!(email: "test@example.com", password: "password123")
  end
  
  # Create Knowledge record
  knowledge = user.knowledges.create!(
    original_url: url,
    status: "processing"
  )
  
  puts "Created Knowledge ##{knowledge.id}"
  
  # Process directly (synchronously for testing)
  begin
    YoutubeProcessorJob.perform_now(knowledge)
    
    # Reload to get updated data
    knowledge.reload
    
    puts "\n--- Results ---"
    puts "Status: #{knowledge.status}"
    puts "Title: #{knowledge.title}"
    puts "Content length: #{knowledge.content&.length || 0} characters"
    puts "Content preview: #{knowledge.content&.first(200)}..." if knowledge.content
    puts "Summary length: #{knowledge.summary&.length || 0} characters"
    puts "Summary: #{knowledge.summary&.first(200)}..." if knowledge.summary
    puts "Keywords: #{knowledge.keywords}"
    puts "Error: #{knowledge.error_message}" if knowledge.error_message
    
    return knowledge.content.present?
  rescue => e
    puts "Error: #{e.message}"
    puts e.backtrace.first(5).join("\n")
    return false
  end
end

def test_article_url
  puts "\n=== Testing Article URL Processing ==="
  url = "https://medium.com/@evgeniy.lebedev/rust-made-easy-a-simple-guide-for-beginners-1fb1e38f8c77"
  puts "Testing URL: #{url}"
  
  user = User.first
  
  # Create Knowledge record
  knowledge = user.knowledges.create!(
    original_url: url,
    status: "processing"
  )
  
  puts "Created Knowledge ##{knowledge.id}"
  
  # Process directly
  begin
    ArticleProcessorJob.perform_now(knowledge)
    
    # Reload to get updated data
    knowledge.reload
    
    puts "\n--- Results ---"
    puts "Status: #{knowledge.status}"
    puts "Title: #{knowledge.title}"
    puts "Content length: #{knowledge.content&.length || 0} characters"
    puts "Content preview: #{knowledge.content&.first(200)}..." if knowledge.content
    puts "Summary length: #{knowledge.summary&.length || 0} characters"
    puts "Summary: #{knowledge.summary&.first(200)}..." if knowledge.summary
    puts "Keywords: #{knowledge.keywords}"
    puts "Error: #{knowledge.error_message}" if knowledge.error_message
    
    return knowledge.content.present?
  rescue => e
    puts "Error: #{e.message}"
    puts e.backtrace.first(5).join("\n")
    return false
  end
end

def check_existing_knowledge
  puts "\n=== Checking Existing Knowledge Records ==="
  
  Knowledge.last(5).each do |k|
    puts "\n##{k.id} - #{k.content_type} - Status: #{k.status}"
    puts "  Title: #{k.title || 'N/A'}"
    puts "  URL: #{k.original_url}"
    puts "  Content: #{k.content.present? ? "✓ (#{k.content.length} chars)" : "✗ MISSING"}"
    puts "  Summary: #{k.summary.present? ? "✓ (#{k.summary.length} chars)" : "✗ MISSING"}"
    puts "  Error: #{k.error_message}" if k.error_message
  end
end

# Run tests
puts "=" * 60
puts "Content Extraction Test Suite"
puts "=" * 60

# Check existing records first
check_existing_knowledge

# Test YouTube
youtube_success = test_youtube_url

# Test Article
article_success = test_article_url

# Summary
puts "\n" + "=" * 60
puts "Test Results Summary"
puts "=" * 60
puts "YouTube content extraction: #{youtube_success ? '✓ PASSED' : '✗ FAILED'}"
puts "Article content extraction: #{article_success ? '✓ PASSED' : '✗ FAILED'}"

if youtube_success && article_success
  puts "\n✓ All tests passed! Content is being properly extracted and saved."
else
  puts "\n✗ Some tests failed. Content extraction may have issues."
end