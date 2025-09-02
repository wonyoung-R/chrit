class CreateKnowledges < ActiveRecord::Migration[8.0]
  def change
    create_table :knowledges do |t|
      t.references :user, null: false, foreign_key: true
      t.string :original_url, null: false
      t.string :title
      t.text :content
      t.text :summary
      t.string :content_type
      t.string :status, default: "processing"
      t.string :thumbnail_url
      t.integer :duration
      t.jsonb :metadata, default: {}

      t.timestamps
    end
    
    add_index :knowledges, :status
    add_index :knowledges, [:user_id, :created_at]
  end
end
