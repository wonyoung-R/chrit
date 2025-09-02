class CreateTags < ActiveRecord::Migration[8.0]
  def change
    create_table :tags do |t|
      t.string :name
      t.integer :count

      t.timestamps
    end
    add_index :tags, :count
  end
end
