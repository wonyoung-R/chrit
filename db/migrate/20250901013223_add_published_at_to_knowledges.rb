class AddPublishedAtToKnowledges < ActiveRecord::Migration[8.0]
  def change
    add_column :knowledges, :published_at, :datetime
  end
end
