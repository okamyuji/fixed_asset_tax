module Api
  module V1
    class BaseController < ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :authenticate_user!
      before_action :set_current_tenant

      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
      rescue_from ActionController::ParameterMissing, with: :bad_request

      private

      def authenticate_user!
        token = request.headers["Authorization"]&.split(" ")&.last
        return render_unauthorized unless token

        begin
          decoded = JWT.decode(token, Rails.application.secret_key_base, true, algorithm: "HS256")
          @current_user = User.find(decoded[0]["user_id"])
          Current.user = @current_user
        rescue JWT::DecodeError, ActiveRecord::RecordNotFound
          render_unauthorized
        end
      end

      def set_current_tenant
        tenant_id = request.headers["X-Tenant-ID"] || params[:tenant_id]
        return render_unauthorized("Tenant ID required") unless tenant_id

        @current_tenant = @current_user.tenants.find_by(id: tenant_id)
        return render_unauthorized("Tenant not found or access denied") unless @current_tenant

        Current.tenant = @current_tenant
      end

      def current_user
        @current_user
      end

      def current_tenant
        @current_tenant
      end

      def render_unauthorized(message = "Unauthorized")
        render json: { error: message }, status: :unauthorized
      end

      def not_found(exception)
        render json: { error: exception.message }, status: :not_found
      end

      def unprocessable_entity(exception)
        render json: { error: exception.message, details: exception.record&.errors }, status: :unprocessable_entity
      end

      def bad_request(exception)
        render json: { error: exception.message }, status: :bad_request
      end
    end
  end
end
