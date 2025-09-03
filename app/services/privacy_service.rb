class PrivacyService
  class << self
    def mask_sensitive_data(user)
      return nil unless user
      
      {
        id: user.id,
        email: mask_email(user.email),
        created_at: user.created_at,
        knowledge_count: user.knowledges.count,
        plan_type: user.user_setting&.plan_type,
        last_sign_in: user.last_sign_in_at
      }
    end
    
    def delete_user_data(user)
      ActiveRecord::Base.transaction do
        ApplicationLogger.log_security_event(
          'gdpr_data_deletion_started',
          {
            user_id: user.id,
            email: mask_email(user.email)
          }
        )
        
        # Delete all user's knowledge records
        user.knowledges.find_each do |knowledge|
          knowledge.destroy
        end
        
        # Delete usage tracking records
        user.usage_trackings.destroy_all if user.respond_to?(:usage_trackings)
        
        # Cancel subscriptions
        user.subscriptions.update_all(status: 'cancelled') if user.respond_to?(:subscriptions)
        
        # Delete user settings
        user.user_setting.destroy if user.user_setting
        
        # Finally delete the user
        user.destroy
        
        ApplicationLogger.log_security_event(
          'gdpr_data_deletion_completed',
          {
            user_id: user.id
          }
        )
        
        true
      end
    rescue => e
      ApplicationLogger.log_security_event(
        'gdpr_data_deletion_failed',
        {
          user_id: user.id,
          error: e.message
        }
      )
      
      raise e
    end
    
    def export_user_data(user)
      {
        user_info: export_user_info(user),
        knowledges: export_knowledges(user),
        usage_history: export_usage_history(user),
        subscriptions: export_subscriptions(user),
        exported_at: Time.current.iso8601
      }
    end
    
    def anonymize_user_data(user)
      ActiveRecord::Base.transaction do
        # Generate anonymous identifier
        anonymous_id = "user_#{SecureRandom.hex(8)}"
        
        # Anonymize user record
        user.update!(
          email: "#{anonymous_id}@anonymized.local",
          encrypted_password: SecureRandom.hex(32)
        )
        
        # Anonymize knowledges
        user.knowledges.update_all(
          title: '[Anonymized]',
          content: '[Content removed for privacy]',
          summary: '[Summary removed for privacy]',
          keywords: '[]'
        )
        
        ApplicationLogger.log_security_event(
          'gdpr_data_anonymized',
          {
            user_id: user.id,
            anonymous_id: anonymous_id
          }
        )
        
        true
      end
    end
    
    def get_consent_status(user)
      setting = user.user_setting
      return default_consent_status unless setting
      
      {
        marketing_emails: setting.notification_preferences&.dig('marketing_emails') || false,
        product_updates: setting.notification_preferences&.dig('product_updates') || true,
        usage_analytics: setting.notification_preferences&.dig('usage_analytics') || true,
        data_processing: setting.notification_preferences&.dig('data_processing') || true,
        updated_at: setting.updated_at
      }
    end
    
    def update_consent(user, consent_params)
      setting = user.user_setting || user.create_user_setting
      
      current_preferences = setting.notification_preferences || {}
      
      updated_preferences = current_preferences.merge(
        'marketing_emails' => consent_params[:marketing_emails],
        'product_updates' => consent_params[:product_updates],
        'usage_analytics' => consent_params[:usage_analytics],
        'data_processing' => consent_params[:data_processing],
        'consent_updated_at' => Time.current.iso8601
      )
      
      setting.update!(notification_preferences: updated_preferences)
      
      ApplicationLogger.log_security_event(
        'consent_updated',
        {
          user_id: user.id,
          consent_changes: consent_params
        }
      )
      
      true
    end
    
    def data_retention_check
      # Find and flag data that should be deleted based on retention policy
      retention_period = ENV.fetch('DATA_RETENTION_DAYS', 365).to_i.days.ago
      
      old_knowledges = Knowledge.where('created_at < ?', retention_period)
      old_users = User.where('last_sign_in_at < ? OR last_sign_in_at IS NULL', retention_period)
        .where('created_at < ?', retention_period)
      
      {
        knowledges_to_delete: old_knowledges.count,
        users_to_delete: old_users.count,
        retention_period_days: ENV.fetch('DATA_RETENTION_DAYS', 365).to_i
      }
    end
    
    def apply_data_retention_policy
      retention_period = ENV.fetch('DATA_RETENTION_DAYS', 365).to_i.days.ago
      deleted_counts = {
        knowledges: 0,
        users: 0
      }
      
      ActiveRecord::Base.transaction do
        # Delete old knowledge records
        Knowledge.where('created_at < ?', retention_period).find_each do |knowledge|
          knowledge.destroy
          deleted_counts[:knowledges] += 1
        end
        
        # Delete inactive users
        User.where('last_sign_in_at < ? OR last_sign_in_at IS NULL', retention_period)
          .where('created_at < ?', retention_period)
          .find_each do |user|
            delete_user_data(user)
            deleted_counts[:users] += 1
          end
      end
      
      ApplicationLogger.log_security_event(
        'data_retention_applied',
        deleted_counts
      )
      
      deleted_counts
    end
    
    private
    
    def mask_email(email)
      return nil unless email
      
      parts = email.split('@')
      return email if parts.length != 2
      
      username = parts[0]
      domain = parts[1]
      
      masked_username = if username.length <= 2
        username[0] + '*'
      else
        username[0..1] + '***'
      end
      
      "#{masked_username}@#{domain}"
    end
    
    def export_user_info(user)
      {
        id: user.id,
        email: user.email,
        created_at: user.created_at.iso8601,
        last_sign_in_at: user.last_sign_in_at&.iso8601,
        sign_in_count: user.sign_in_count,
        admin: user.admin
      }
    end
    
    def export_knowledges(user)
      user.knowledges.map do |knowledge|
        {
          id: knowledge.id,
          title: knowledge.title,
          content_type: knowledge.content_type,
          status: knowledge.status,
          original_url: knowledge.original_url,
          created_at: knowledge.created_at.iso8601,
          credits_consumed: knowledge.credits_consumed
        }
      end
    end
    
    def export_usage_history(user)
      return [] unless user.respond_to?(:usage_trackings)
      
      user.usage_trackings.map do |tracking|
        {
          month: tracking.month,
          credits_used: tracking.credits_used,
          urls_processed: tracking.urls_processed
        }
      end
    end
    
    def export_subscriptions(user)
      return [] unless user.respond_to?(:subscriptions)
      
      user.subscriptions.map do |subscription|
        {
          plan_type: subscription.plan_type,
          status: subscription.status,
          amount: subscription.amount,
          expires_at: subscription.expires_at&.iso8601,
          created_at: subscription.created_at.iso8601
        }
      end
    end
    
    def default_consent_status
      {
        marketing_emails: false,
        product_updates: true,
        usage_analytics: true,
        data_processing: true,
        updated_at: nil
      }
    end
  end
end