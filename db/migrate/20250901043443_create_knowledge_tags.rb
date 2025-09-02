class CreateKnowledgeTags < ActiveRecord::Migration[8.0]
  def change
    create_table :knowledge_tags do |t|
      t.references :knowledge, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end
  end
end
