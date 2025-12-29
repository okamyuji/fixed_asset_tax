module Api
  module V1
    class CalculationRunsController < BaseController
      before_action :set_calculation_run, only: [ :show, :execute ]

      def index
        runs = current_tenant.calculation_runs
                             .includes(:municipality, :fiscal_year)
                             .order(created_at: :desc)
        render json: runs.map { |r| calculation_run_response(r) }
      end

      def show
        render json: calculation_run_response(@calculation_run, include_results: true)
      end

      def create
        municipality = Municipality.find(params[:municipality_id])
        fiscal_year = FiscalYear.find(params[:fiscal_year_id])

        calculation_run = current_tenant.calculation_runs.create!(
          municipality: municipality,
          fiscal_year: fiscal_year,
          status: "queued"
        )

        render json: calculation_run_response(calculation_run), status: :created
      end

      def execute
        result = Tax::PropertyTaxCalculator.new(
          tenant: current_tenant,
          municipality: @calculation_run.municipality,
          fiscal_year: @calculation_run.fiscal_year
        ).call

        if result[:success]
          @calculation_run.update!(status: "succeeded")
          render json: calculation_run_response(@calculation_run, include_results: true)
        else
          @calculation_run.update!(status: "failed", error_message: result[:error])
          render json: { error: result[:error] }, status: :unprocessable_entity
        end
      end

      private

      def set_calculation_run
        @calculation_run = current_tenant.calculation_runs.find(params[:id])
      end

      def calculation_run_response(run, include_results: false)
        response = {
          id: run.id,
          municipality_id: run.municipality_id,
          municipality_name: run.municipality.name,
          fiscal_year_id: run.fiscal_year_id,
          fiscal_year: run.fiscal_year.year,
          status: run.status,
          error_message: run.error_message,
          created_at: run.created_at,
          updated_at: run.updated_at
        }

        if include_results
          response[:results] = run.calculation_results.includes(:property).map do |result|
            {
              id: result.id,
              property_id: result.property_id,
              property_name: result.property.name,
              tax_amount: result.tax_amount.to_f,
              breakdown: result.breakdown_json
            }
          end
        end

        response
      end
    end
  end
end
