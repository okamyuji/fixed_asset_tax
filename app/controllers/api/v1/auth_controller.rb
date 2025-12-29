module Api
  module V1
    class AuthController < ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :authenticate_user!, only: [ :me, :logout ]
      before_action :set_current_tenant, only: [ :me ]

      def register
        # テナントとユーザーをトランザクション内で作成
        ActiveRecord::Base.transaction do
          # テナント作成
          tenant = Tenant.create!(name: params[:tenant_name], plan: "free")

          # ユーザー作成
          user = User.new(
            email: params[:email],
            password: params[:password],
            password_confirmation: params[:password_confirmation],
            name: params[:user_name]
          )

          if user.save
            # メンバーシップ作成
            Membership.create!(user: user, tenant: tenant, role: "admin")

            token = generate_token(user)
            render json: { token: token, tenant_id: tenant.id.to_s }, status: :created
          else
            render json: { error: user.errors.full_messages.join(", ") }, status: :unprocessable_entity
            raise ActiveRecord::Rollback
          end
        end
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def login
        user = User.find_by(email: params[:email])

        if user&.authenticate(params[:password])
          token = generate_token(user)
          tenants = user.tenants.map { |t| tenant_response(t) }
          render json: { user: user_response(user), token: token, tenants: tenants }
        else
          render json: { error: "Invalid email or password" }, status: :unauthorized
        end
      end

      def logout
        # JWTはステートレスなので、クライアント側でトークンを削除するだけ
        head :no_content
      end

      def me
        tenants = current_user.tenants.map { |t| tenant_response(t) }
        render json: { user: user_response(current_user), tenants: tenants }
      end

      private

      def user_params
        params.require(:user).permit(:email, :password, :password_confirmation, :name)
      end

      def generate_token(user)
        payload = { user_id: user.id, exp: 24.hours.from_now.to_i }
        JWT.encode(payload, Rails.application.secret_key_base, "HS256")
      end

      def user_response(user)
        {
          id: user.id,
          email: user.email,
          name: user.name
        }
      end

      def tenant_response(tenant)
        {
          id: tenant.id,
          name: tenant.name,
          plan: tenant.plan
        }
      end

      def authenticate_user!
        token = request.headers["Authorization"]&.split(" ")&.last
        return render json: { error: "Unauthorized" }, status: :unauthorized unless token

        begin
          decoded = JWT.decode(token, Rails.application.secret_key_base, true, algorithm: "HS256")
          @current_user = User.find(decoded[0]["user_id"])
          Current.user = @current_user
        rescue JWT::DecodeError, ActiveRecord::RecordNotFound
          render json: { error: "Unauthorized" }, status: :unauthorized
        end
      end

      def set_current_tenant
        tenant_id = request.headers["X-Tenant-ID"]
        if tenant_id
          @current_tenant = @current_user.tenants.find_by(id: tenant_id)
          Current.tenant = @current_tenant if @current_tenant
        end
      end

      def current_user
        @current_user
      end
    end
  end
end
