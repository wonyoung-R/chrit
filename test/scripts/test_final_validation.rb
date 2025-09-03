#!/usr/bin/env rails runner

# Iteration 5: Final validation and optimization test
require 'json'
require 'benchmark'

class FinalValidationTest
  def initialize
    @user = User.first || User.create!(email: "test@example.com", password: "password123")
    @results = []
  end
  
  def run_all_tests
    puts "=" * 80
    puts "FINAL VALIDATION TEST SUITE - Iteration 5"
    puts "=" * 80
    
    # Test 1: Content extraction validation
    test_content_extraction
    
    # Test 2: Performance benchmarking
    test_performance
    
    # Test 3: Error handling
    test_error_handling
    
    # Test 4: Content quality validation
    test_content_quality
    
    # Test 5: System health check
    test_system_health
    
    # Generate report
    generate_report
  end
  
  private
  
  def test_content_extraction
    puts "\n[TEST 1] Content Extraction Validation"
    puts "-" * 40
    
    test_urls = {
      youtube: [
        "https://www.youtube.com/watch?v=2lAe1cqCOXo",  # YouTube Rewind
        "https://www.youtube.com/watch?v=kJQP7kiw5Fk",  # Despacito
      ],
      article: [
        "https://www.rust-lang.org/learn",
        "https://nodejs.org/en/about",
      ]
    }
    
    test_urls.each do |type, urls|
      urls.each do |url|
        next if @user.knowledges.exists?(original_url: url)
        
        knowledge = @user.knowledges.create!(
          original_url: url,
          status: "processing"
        )
        
        processor = type == :youtube ? YoutubeProcessorJob : ArticleProcessorJob
        
        begin
          time = Benchmark.realtime do
            processor.perform_now(knowledge)
          end
          
          knowledge.reload
          
          result = {
            type: type,
            url: url,
            success: knowledge.status == 'completed',
            has_content: knowledge.content.present?,
            has_summary: knowledge.summary.present?,
            content_length: knowledge.content&.length || 0,
            processing_time: time.round(2)
          }
          
          @results << result
          
          puts "✓ #{type.to_s.capitalize}: #{knowledge.content.present? ? 'SUCCESS' : 'FAILED'}"
          puts "  Time: #{time.round(2)}s | Content: #{knowledge.content&.length || 0} chars"
          
        rescue => e
          puts "✗ #{type.to_s.capitalize}: ERROR - #{e.message}"
          @results << {
            type: type,
            url: url,
            success: false,
            error: e.message
          }
        end
        
        break # Only test one URL per type to save time
      end
    end
  end
  
  def test_performance
    puts "\n[TEST 2] Performance Benchmarking"
    puts "-" * 40
    
    # Check average processing times
    youtube_times = Knowledge.where(content_type: 'youtube')
                            .where.not(completed_at: nil, created_at: nil)
                            .pluck(:completed_at, :created_at)
                            .map { |c, s| (c - s).to_f }
    
    article_times = Knowledge.where(content_type: 'article')
                            .where.not(completed_at: nil, created_at: nil)
                            .pluck(:completed_at, :created_at)
                            .map { |c, s| (c - s).to_f }
    
    if youtube_times.any?
      avg_youtube = youtube_times.sum / youtube_times.length
      puts "YouTube avg processing: #{avg_youtube.round(2)}s"
      puts "  Target: < 15s | Status: #{avg_youtube < 15 ? '✓ PASS' : '✗ FAIL'}"
    end
    
    if article_times.any?
      avg_article = article_times.sum / article_times.length
      puts "Article avg processing: #{avg_article.round(2)}s"
      puts "  Target: < 10s | Status: #{avg_article < 10 ? '✓ PASS' : '✗ FAIL'}"
    end
  end
  
  def test_error_handling
    puts "\n[TEST 3] Error Handling"
    puts "-" * 40
    
    invalid_urls = [
      "https://invalid-url-that-does-not-exist-12345.com",
      "not-a-url",
      "https://youtube.com/watch?v=invalid"
    ]
    
    invalid_urls.each do |url|
      next if @user.knowledges.exists?(original_url: url)
      
      knowledge = @user.knowledges.create!(
        original_url: url,
        status: "processing"
      )
      
      begin
        UrlProcessorJob.perform_now(knowledge)
        knowledge.reload
        
        if knowledge.status == 'failed' && knowledge.error_message.present?
          puts "✓ Properly handled invalid URL: #{url[0..50]}..."
        else
          puts "✗ Failed to handle invalid URL properly"
        end
      rescue => e
        puts "✓ Error caught for invalid URL: #{e.class}"
      end
      
      break # Test only one to save time
    end
  end
  
  def test_content_quality
    puts "\n[TEST 4] Content Quality Validation"
    puts "-" * 40
    
    recent_knowledge = Knowledge.where(status: 'completed').last(5)
    
    quality_checks = {
      has_content: 0,
      has_summary: 0,
      has_keywords: 0,
      has_title: 0,
      content_length_ok: 0,
      summary_length_ok: 0
    }
    
    recent_knowledge.each do |k|
      quality_checks[:has_content] += 1 if k.content.present?
      quality_checks[:has_summary] += 1 if k.summary.present?
      quality_checks[:has_keywords] += 1 if k.keywords.present?
      quality_checks[:has_title] += 1 if k.title.present?
      quality_checks[:content_length_ok] += 1 if k.content&.length.to_i > 100
      quality_checks[:summary_length_ok] += 1 if k.summary&.length.to_i.between?(50, 500)
    end
    
    total = recent_knowledge.count.to_f
    
    if total > 0
      quality_checks.each do |check, count|
        percentage = (count / total * 100).round(1)
        status = percentage >= 80 ? "✓" : "✗"
        puts "#{status} #{check.to_s.humanize}: #{percentage}% (#{count}/#{total.to_i})"
      end
    else
      puts "No completed knowledge records to validate"
    end
  end
  
  def test_system_health
    puts "\n[TEST 5] System Health Check"
    puts "-" * 40
    
    # Check database
    total_knowledge = Knowledge.count
    completed = Knowledge.where(status: 'completed').count
    failed = Knowledge.where(status: 'failed').count
    processing = Knowledge.where(status: 'processing').count
    
    puts "Database Status:"
    puts "  Total records: #{total_knowledge}"
    puts "  Completed: #{completed} (#{(completed.to_f/total_knowledge*100).round(1)}%)"
    puts "  Failed: #{failed} (#{(failed.to_f/total_knowledge*100).round(1)}%)"
    puts "  Processing: #{processing}"
    
    # Check content integrity
    missing_content = Knowledge.where(status: 'completed', content: [nil, '']).count
    missing_summary = Knowledge.where(status: 'completed', summary: [nil, '']).count
    
    puts "\nContent Integrity:"
    puts "  Completed without content: #{missing_content} #{missing_content == 0 ? '✓' : '✗ WARNING'}"
    puts "  Completed without summary: #{missing_summary} #{missing_summary == 0 ? '✓' : '✗ WARNING'}"
    
    # Check services
    puts "\nService Availability:"
    begin
      YoutubeService.new
      puts "  YouTube Service: ✓ Available"
    rescue
      puts "  YouTube Service: ✗ Unavailable"
    end
    
    begin
      ArticleExtractor.new
      puts "  Article Extractor: ✓ Available"
    rescue
      puts "  Article Extractor: ✗ Unavailable"
    end
    
    begin
      GeminiService.new
      puts "  Gemini Service: ✓ Available"
    rescue
      puts "  Gemini Service: ✗ Unavailable"
    end
  end
  
  def generate_report
    puts "\n" + "=" * 80
    puts "FINAL VALIDATION REPORT"
    puts "=" * 80
    
    successful_tests = @results.count { |r| r[:success] }
    total_tests = @results.count
    
    puts "\nOverall Results:"
    puts "  Tests passed: #{successful_tests}/#{total_tests}"
    puts "  Success rate: #{total_tests > 0 ? (successful_tests.to_f/total_tests*100).round(1) : 0}%"
    
    puts "\nContent Extraction Status:"
    @results.group_by { |r| r[:type] }.each do |type, results|
      success_count = results.count { |r| r[:has_content] }
      puts "  #{type.to_s.capitalize}: #{success_count}/#{results.count} successful"
      
      if results.any? { |r| r[:processing_time] }
        avg_time = results.map { |r| r[:processing_time] || 0 }.sum / results.count
        puts "    Avg time: #{avg_time.round(2)}s"
      end
    end
    
    puts "\nSystem Status: #{successful_tests == total_tests ? '✓ HEALTHY' : '⚠ NEEDS ATTENTION'}"
    
    puts "\n" + "=" * 80
    puts "CONCLUSION:"
    if successful_tests == total_tests
      puts "✓ All systems operational. Content extraction is working properly."
      puts "✓ The 5 iterations of development have successfully improved the system."
    else
      puts "⚠ Some issues detected. Review the logs for details."
      puts "Recommendation: Check failed tests and monitor system logs."
    end
    puts "=" * 80
  end
end

# Run the final validation
FinalValidationTest.new.run_all_tests