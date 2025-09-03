class AddIndexesToKnowledges < ActiveRecord::Migration[8.0]
  def change
    # 성능 향상을 위한 인덱스 추가
    add_index :knowledges, :content_type unless index_exists?(:knowledges, :content_type)
    add_index :knowledges, [:user_id, :status] unless index_exists?(:knowledges, [:user_id, :status])
    add_index :knowledges, [:user_id, :content_type] unless index_exists?(:knowledges, [:user_id, :content_type])
    add_index :knowledges, :original_url unless index_exists?(:knowledges, :original_url)
    
    # Tags 테이블 인덱스
    add_index :tags, :name unless index_exists?(:tags, :name)
    add_index :tags, :count unless index_exists?(:tags, :count)
    
    # Knowledge_tags 복합 인덱스 (중복 방지)
    unless index_exists?(:knowledge_tags, [:knowledge_id, :tag_id])
      add_index :knowledge_tags, [:knowledge_id, :tag_id], unique: true
    end
  end
end
