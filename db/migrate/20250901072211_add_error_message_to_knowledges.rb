class AddErrorMessageToKnowledges < ActiveRecord::Migration[8.0]
  def change
    add_column :knowledges, :error_message, :text
  end
end
