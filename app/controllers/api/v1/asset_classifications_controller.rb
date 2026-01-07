module Api
  module V1
    class AssetClassificationsController < BaseController
      # GET /api/v1/asset_classifications
      def index
        render json: {
          asset_classifications: asset_classification_list,
          account_items: account_item_list,
          depreciation_methods: depreciation_method_list,
          depreciation_types: depreciation_type_list,
          acquisition_types: acquisition_type_list
        }
      end

      # GET /api/v1/asset_classifications/account_items
      def account_items
        render json: { account_items: account_item_list }
      end

      # GET /api/v1/asset_classifications/useful_life
      def useful_life
        account_item = params[:account_item]

        if account_item.blank?
          render json: { error: "account_item parameter is required" }, status: :bad_request
          return
        end

        useful_life = FixedAsset.useful_life_for(account_item)

        if useful_life
          render json: {
            account_item: account_item,
            useful_life_years: useful_life
          }
        else
          render json: {
            account_item: account_item,
            useful_life_years: nil,
            message: "No useful life information available for this account item"
          }
        end
      end

      private

      def asset_classification_list
        AssetClassifications::ASSET_CLASSIFICATIONS.map do |key, value|
          {
            key: key.to_s,
            name: value[:name],
            code: value[:code]
          }
        end
      end

      def account_item_list
        {
          tangible: format_account_items(AssetClassifications::TANGIBLE_ACCOUNT_ITEMS),
          intangible: format_account_items(AssetClassifications::INTANGIBLE_ACCOUNT_ITEMS),
          deferred: format_account_items(AssetClassifications::DEFERRED_ACCOUNT_ITEMS)
        }
      end

      def format_account_items(items)
        items.map do |key, value|
          {
            key: key.to_s,
            name: value[:name],
            code: value[:code],
            useful_life_range: value[:useful_life_range] ? {
              min: value[:useful_life_range].min,
              max: value[:useful_life_range].max
            } : nil,
            description: value[:description]
          }
        end
      end

      def depreciation_method_list
        AssetClassifications::DEPRECIATION_METHODS.map do |key, value|
          {
            key: key.to_s,
            name: value[:name],
            code: value[:code]
          }
        end
      end

      def depreciation_type_list
        AssetClassifications::DEPRECIATION_TYPES.map do |key, value|
          {
            key: key.to_s,
            name: value[:name],
            code: value[:code],
            threshold: value[:threshold] ? {
              min: value[:threshold].min,
              max: value[:threshold].max
            } : nil
          }
        end
      end

      def acquisition_type_list
        AssetClassifications::ACQUISITION_TYPES.map do |key, value|
          {
            key: key.to_s,
            name: value[:name],
            code: value[:code]
          }
        end
      end
    end
  end
end
