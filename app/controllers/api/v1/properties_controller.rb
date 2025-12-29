module Api
  module V1
    class PropertiesController < BaseController
      before_action :set_property, only: [ :show, :update, :destroy ]

      def index
        properties = current_tenant.properties.includes(:party, :municipality)
        render json: properties.map { |p| property_response(p) }
      end

      def show
        render json: property_response(@property)
      end

      def create
        property = current_tenant.properties.build(property_params)

        if property.save
          render json: property_response(property), status: :created
        else
          render json: { errors: property.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @property.update(property_params)
          render json: property_response(@property)
        else
          render json: { errors: @property.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @property.destroy
        head :no_content
      end

      private

      def set_property
        @property = current_tenant.properties.find(params[:id])
      end

      def property_params
        params.require(:property).permit(:party_id, :municipality_id, :category, :name)
      end

      def property_response(property)
        {
          id: property.id,
          party_id: property.party_id,
          party_name: property.party.display_name,
          municipality_id: property.municipality_id,
          municipality_name: property.municipality.name,
          category: property.category,
          name: property.name,
          created_at: property.created_at,
          updated_at: property.updated_at
        }
      end
    end
  end
end
