module Api
  module V1
    class ProcessUrlController < ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :authenticate_api_user!

      def create
        url = params[:url]
        
        if url.blank?
          render json: { error: "URL is required" }, status: :bad_request
          return
        end

        processor = UrlProcessorService.new(url)
        result = processor.process

        if result[:error]
          render json: result, status: :unprocessable_entity
        else
          # Save to database
          knowledge = current_user.knowledges.create!(
            original_url: result[:original_url],
            content_type: result[:content_type],
            title: result[:title],
            summary: result[:summary],
            keywords: result[:keywords].to_json,
            thumbnail_url: result[:thumbnail_url] || result[:image_url],
            status: 'completed'
          )

          render json: {
            success: true,
            data: {
              id: knowledge.id,
              url: knowledge.original_url,
              content_type: knowledge.content_type,
              title: knowledge.title,
              summary: knowledge.summary,
              keywords: JSON.parse(knowledge.keywords),
              thumbnail_url: knowledge.thumbnail_url,
              created_at: knowledge.created_at
            }
          }, status: :created
        end
      rescue StandardError => e
        render json: { error: e.message }, status: :internal_server_error
      end

      private

      def authenticate_api_user!
        # Implement API authentication logic here
        # For example, using API tokens or JWT
        authenticate_user!
      end
    end
  end
end