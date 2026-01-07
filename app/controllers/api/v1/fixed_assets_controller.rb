module Api
  module V1
    class FixedAssetsController < BaseController
      before_action :set_property, only: [ :index, :create ]
      before_action :set_fixed_asset, only: [ :update, :destroy, :calculate_depreciation ]

      def index
        fixed_assets = @property.fixed_assets.includes(:depreciation_policy)
        render json: fixed_assets.map { |fa| fixed_asset_response(fa) }
      end

      def create
        fixed_asset = @property.fixed_assets.build(fixed_asset_params)
        fixed_asset.tenant = current_tenant

        if fixed_asset.save
          # 減価償却ポリシーも作成
          if params[:depreciation_policy].present?
            policy = fixed_asset.build_depreciation_policy(depreciation_policy_params)
            policy.tenant = current_tenant
            policy.save
          end

          render json: fixed_asset_response(fixed_asset), status: :created
        else
          render json: { errors: fixed_asset.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @fixed_asset.update(fixed_asset_params)
          # 減価償却ポリシーも更新
          if params[:depreciation_policy].present? && @fixed_asset.depreciation_policy
            @fixed_asset.depreciation_policy.update(depreciation_policy_params)
          end

          render json: fixed_asset_response(@fixed_asset)
        else
          render json: { errors: @fixed_asset.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @fixed_asset.destroy
        head :no_content
      end

      def calculate_depreciation
        fiscal_year = FiscalYear.find(params[:fiscal_year_id])

        result = Tax::DepreciationCalculator.new(
          fixed_asset: @fixed_asset,
          fiscal_year: fiscal_year
        ).call

        if result[:success]
          depreciation_year = DepreciationYear.find_or_initialize_by(
            tenant: current_tenant,
            fixed_asset: @fixed_asset,
            fiscal_year: fiscal_year
          )

          depreciation_year.assign_attributes(
            opening_book_value: result[:opening_book_value],
            depreciation_amount: result[:depreciation_amount],
            closing_book_value: result[:closing_book_value]
          )

          if depreciation_year.save
            render json: depreciation_year_response(depreciation_year)
          else
            render json: { errors: depreciation_year.errors.full_messages }, status: :unprocessable_entity
          end
        else
          render json: { error: result[:error] }, status: :unprocessable_entity
        end
      end

      private

      def set_property
        @property = current_tenant.properties.find(params[:property_id])
      end

      def set_fixed_asset
        @fixed_asset = current_tenant.fixed_assets.find(params[:id])
      end

      def fixed_asset_params
        params.require(:fixed_asset).permit(
          :name,
          :acquired_on,
          :acquisition_cost,
          :asset_type,
          :account_item,
          :asset_classification,
          :business_use_ratio,
          :acquisition_type,
          :service_start_date,
          :quantity,
          :unit,
          :location,
          :description
        )
      end

      def depreciation_policy_params
        params.require(:depreciation_policy).permit(
          :method,
          :useful_life_years,
          :residual_rate,
          :depreciation_type,
          :special_depreciation_rate,
          :first_year_prorated,
          :registered_method,
          :depreciation_start_date,
          :memo
        )
      end

      def fixed_asset_response(fixed_asset)
        response = {
          id: fixed_asset.id,
          property_id: fixed_asset.property_id,
          name: fixed_asset.name,
          acquired_on: fixed_asset.acquired_on,
          acquisition_cost: fixed_asset.acquisition_cost.to_f,
          asset_type: fixed_asset.asset_type,
          account_item: fixed_asset.account_item,
          account_item_name: fixed_asset.account_item_name,
          asset_classification: fixed_asset.asset_classification,
          asset_classification_name: fixed_asset.asset_classification_name,
          business_use_ratio: fixed_asset.business_use_ratio&.to_f,
          acquisition_type: fixed_asset.acquisition_type,
          service_start_date: fixed_asset.service_start_date,
          quantity: fixed_asset.quantity,
          unit: fixed_asset.unit,
          location: fixed_asset.location,
          description: fixed_asset.description,
          created_at: fixed_asset.created_at,
          updated_at: fixed_asset.updated_at
        }

        if fixed_asset.depreciation_policy
          response[:depreciation_policy] = {
            id: fixed_asset.depreciation_policy.id,
            method: fixed_asset.depreciation_policy.method,
            method_name: fixed_asset.depreciation_policy.depreciation_method_name,
            useful_life_years: fixed_asset.depreciation_policy.useful_life_years,
            residual_rate: fixed_asset.depreciation_policy.residual_rate.to_f,
            depreciation_type: fixed_asset.depreciation_policy.depreciation_type,
            depreciation_type_name: fixed_asset.depreciation_policy.depreciation_type_name,
            special_depreciation_rate: fixed_asset.depreciation_policy.special_depreciation_rate&.to_f,
            first_year_prorated: fixed_asset.depreciation_policy.first_year_prorated,
            registered_method: fixed_asset.depreciation_policy.registered_method,
            depreciation_start_date: fixed_asset.depreciation_policy.depreciation_start_date,
            memo: fixed_asset.depreciation_policy.memo
          }
        end

        response
      end

      def depreciation_year_response(depreciation_year)
        {
          id: depreciation_year.id,
          fixed_asset_id: depreciation_year.fixed_asset_id,
          fiscal_year_id: depreciation_year.fiscal_year_id,
          fiscal_year: depreciation_year.fiscal_year.year,
          opening_book_value: depreciation_year.opening_book_value.to_f,
          depreciation_amount: depreciation_year.depreciation_amount.to_f,
          closing_book_value: depreciation_year.closing_book_value.to_f,
          created_at: depreciation_year.created_at,
          updated_at: depreciation_year.updated_at
        }
      end
    end
  end
end
