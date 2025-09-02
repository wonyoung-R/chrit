class AddKeywordsToKnowledges < ActiveRecord::Migration[8.0]
  def change
    add_column :knowledges, :keywords, :text
  end
end
