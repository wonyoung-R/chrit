module ApplicationHelper
  def format_duration(seconds)
    return nil unless seconds
    
    hours = seconds / 3600
    minutes = (seconds % 3600) / 60
    seconds = seconds % 60
    
    if hours > 0
      "#{hours}시간 #{minutes}분"
    elsif minutes > 0
      "#{minutes}분 #{seconds}초"
    else
      "#{seconds}초"
    end
  end
  
  def time_ago_in_words(from_time, include_seconds = false)
    distance_in_minutes = (((Time.current - from_time).abs) / 60).round
    
    case distance_in_minutes
    when 0..1
      "1분"
    when 2..59
      "#{distance_in_minutes}분"
    when 60..119
      "1시간"
    when 120..1439
      "#{(distance_in_minutes / 60).round}시간"
    when 1440..2879
      "1일"
    else
      "#{(distance_in_minutes / 1440).round}일"
    end
  end
end
