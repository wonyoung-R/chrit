class CreateUserSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :user_settings do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.boolean :email_notifications, default: true
      t.string :privacy_mode, default: 'private' # private, friends, public
      t.string :language, default: 'ko'
      t.string :timezone, default: 'Asia/Seoul'
      t.integer :monthly_credit_limit, default: 100
      t.integer :used_credits, default: 0
      t.string :theme, default: 'dark'
      t.boolean :email_verified, default: false
      t.datetime :email_verified_at
      t.string :verification_token
      t.datetime :last_credit_reset_at
      t.jsonb :preferences, default: {}

      t.timestamps
    end
    
    add_index :user_settings, :verification_token, unique: true
    add_index :user_settings, :email_verified
  end
end
