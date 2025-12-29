module Api
  module V1
    class FiscalYearsController < BaseController
      skip_before_action :set_current_tenant, only: [ :index, :show ]

      def index
        fiscal_years = FiscalYear.order(year: :desc)
        render json: fiscal_years.map { |fy| fiscal_year_response(fy) }
      end

      def show
        fiscal_year = FiscalYear.find(params[:id])
        render json: fiscal_year_response(fiscal_year)
      end

      def create
        fiscal_year = FiscalYear.new(fiscal_year_params)

        if fiscal_year.save
          render json: fiscal_year_response(fiscal_year), status: :created
        else
          render json: { errors: fiscal_year.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def fiscal_year_params
        params.require(:fiscal_year).permit(:year, :starts_on, :ends_on)
      end

      def fiscal_year_response(fiscal_year)
        {
          id: fiscal_year.id,
          year: fiscal_year.year,
          starts_on: fiscal_year.starts_on,
          ends_on: fiscal_year.ends_on,
          created_at: fiscal_year.created_at,
          updated_at: fiscal_year.updated_at
        }
      end
    end
  end
end
