class KnowledgeTag < ApplicationRecord
  belongs_to :knowledge
  belongs_to :tag
end