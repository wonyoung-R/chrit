class Tag < ApplicationRecord
  has_many :knowledge_tags, dependent: :destroy
  has_many :knowledges, through: :knowledge_tags
  
  validates :name, presence: true, uniqueness: true
  
  scope :popular, -> { order(count: :desc).limit(10) }
  
  def self.increment_count(tag_name)
    tag = find_or_create_by(name: tag_name.downcase)
    tag.increment!(:count)
    tag
  end
end
