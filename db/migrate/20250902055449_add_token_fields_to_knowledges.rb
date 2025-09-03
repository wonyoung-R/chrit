class AddTokenFieldsToKnowledges < ActiveRecord::Migration[8.0]
  def change
    # 토큰 사용량 추적 필드
    add_column :knowledges, :input_tokens, :integer, default: 0
    add_column :knowledges, :output_tokens, :integer, default: 0
    add_column :knowledges, :credits_consumed, :decimal, precision: 5, scale: 2, default: 0.0
    
    # 인덱스 추가
    add_index :knowledges, :credits_consumed
    add_index :knowledges, :created_at
  end
end