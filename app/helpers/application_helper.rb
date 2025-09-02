module ApplicationHelper
  def format_duration(seconds)
    return nil unless seconds
    
    hours = seconds / 3600
    minutes = (seconds % 3600) / 60
    seconds = seconds % 60
    
    if hours > 0
      "#{hours}時間#{minutes}分"
    elsif minutes > 0
      "#{minutes}分#{seconds}秒"
    else
      "#{seconds}秒"
    end
  end
  
  def time_ago_in_words(from_time, include_seconds = false)
    distance_in_minutes = (((Time.current - from_time).abs) / 60).round
    
    case distance_in_minutes
    when 0..1
      "1分"
    when 2..59
      "#{distance_in_minutes}分"
    when 60..119
      "1時間"
    when 120..1439
      "#{(distance_in_minutes / 60).round}時間"
    when 1440..2879
      "1日"
    else
      "#{(distance_in_minutes / 1440).round}日"
    end
  end
end
