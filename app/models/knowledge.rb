class Knowledge < ApplicationRecord
  belongs_to :user
  has_many :knowledge_tags, dependent: :destroy
  has_many :tags, through: :knowledge_tags
  
  validates :original_url, presence: true, uniqueness: { scope: :user_id, message: "이미 처리된 URL입니다." }
  
  scope :recent, -> { order(created_at: :desc) }
  scope :completed, -> { where(status: "completed") }
  scope :processing, -> { where(status: "processing") }
  
  after_save :extract_and_save_tags, if: :saved_change_to_summary?
  
  def completed?
    status == "completed"
  end
  
  def processing?
    status == "processing"
  end
  
  private
  
  def extract_and_save_tags
    return unless summary.present?
    
    # Extract keywords from the existing keywords field
    if keywords.present?
      begin
        keyword_list = JSON.parse(keywords)
        keyword_list.each do |keyword|
          tag = Tag.increment_count(keyword)
          knowledge_tags.find_or_create_by(tag: tag)
        end
      rescue JSON::ParserError
        # Handle invalid JSON
      end
    end
    
    # Also extract common Korean topic words from summary
    common_topics = %w[정치 경제 사회 문화 기술 교육 환경 건강 스포츠 과학 역사 예술 종교 법률 의료]
    summary_lower = summary.downcase
    
    common_topics.each do |topic|
      if summary_lower.include?(topic)
        tag = Tag.increment_count(topic)
        knowledge_tags.find_or_create_by(tag: tag)
      end
    end
  end
end
