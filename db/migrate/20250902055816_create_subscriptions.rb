class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :plan_type, null: false, default: 'free'
      t.string :status, null: false, default: 'pending'
      t.string :payment_method
      t.string :payment_id
      t.decimal :amount, precision: 10, scale: 2
      t.datetime :started_at
      t.datetime :expires_at
      t.jsonb :payment_data, default: {}
      t.string :toss_order_id
      t.string :toss_payment_key

      t.timestamps
    end
    
    add_index :subscriptions, :status
    add_index :subscriptions, :plan_type
    add_index :subscriptions, :expires_at
    add_index :subscriptions, :toss_order_id, unique: true
    add_index :subscriptions, :toss_payment_key, unique: true
  end
end