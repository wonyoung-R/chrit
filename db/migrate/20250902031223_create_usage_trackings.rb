class CreateUsageTrackings < ActiveRecord::Migration[8.0]
  def change
    create_table :usage_trackings do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :year, null: false
      t.integer :month, null: false
      t.integer :credits_used, default: 0
      t.integer :urls_processed, default: 0
      t.integer :youtube_count, default: 0
      t.integer :article_count, default: 0

      t.timestamps
    end
    
    # 사용자별 연/월 조합은 유니크해야 함
    add_index :usage_trackings, [:user_id, :year, :month], unique: true
    add_index :usage_trackings, [:year, :month]
  end
end
