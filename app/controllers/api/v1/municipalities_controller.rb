module Api
  module V1
    class MunicipalitiesController < BaseController
      skip_before_action :set_current_tenant, only: [ :index, :show ]

      def index
        municipalities = Municipality.all
        render json: municipalities.map { |m| municipality_response(m) }
      end

      def show
        municipality = Municipality.find(params[:id])
        render json: municipality_response(municipality)
      end

      def create
        municipality = Municipality.new(municipality_params)

        if municipality.save
          render json: municipality_response(municipality), status: :created
        else
          render json: { errors: municipality.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def municipality_params
        params.require(:municipality).permit(:code, :name)
      end

      def municipality_response(municipality)
        {
          id: municipality.id,
          code: municipality.code,
          name: municipality.name,
          created_at: municipality.created_at,
          updated_at: municipality.updated_at
        }
      end
    end
  end
end
