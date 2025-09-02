class AddTimingColumnsToKnowledges < ActiveRecord::Migration[8.0]
  def change
    add_column :knowledges, :started_at, :datetime
    add_column :knowledges, :completed_at, :datetime
  end
end
