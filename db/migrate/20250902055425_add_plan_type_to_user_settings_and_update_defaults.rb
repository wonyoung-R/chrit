class AddPlanTypeToUserSettingsAndUpdateDefaults < ActiveRecord::Migration[8.0]
  def change
    # 플랜 타입 추가
    add_column :user_settings, :plan_type, :string, default: 'free', null: false
    add_index :user_settings, :plan_type
    
    # 기본 크레딧 한도를 10으로 변경 (신규 가입자용)
    change_column_default :user_settings, :monthly_credit_limit, from: 100, to: 10
    
    # 기존 사용자들의 플랜 타입 설정
    reversible do |dir|
      dir.up do
        UserSetting.update_all(plan_type: 'legacy')
        # 새로운 사용자는 자동으로 'free' 플랜으로 생성됨
      end
    end
  end
end