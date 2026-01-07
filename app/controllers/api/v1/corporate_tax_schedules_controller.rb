module Api
  module V1
    class CorporateTaxSchedulesController < BaseController
      before_action :set_schedule, only: [ :show, :update, :destroy, :generate, :finalize, :export_csv ]

      # GET /api/v1/corporate_tax_schedules
      def index
        schedules = current_tenant.corporate_tax_schedules
          .includes(:fiscal_year)
          .order("fiscal_years.year DESC, schedule_type ASC")

        render json: schedules.map { |s| schedule_response(s) }
      end

      # GET /api/v1/corporate_tax_schedules/:id
      def show
        render json: schedule_response(@schedule)
      end

      # POST /api/v1/corporate_tax_schedules
      def create
        schedule = current_tenant.corporate_tax_schedules.build(schedule_params)

        if schedule.save
          render json: schedule_response(schedule), status: :created
        else
          render json: { errors: schedule.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/corporate_tax_schedules/:id
      def update
        if @schedule.finalized?
          render json: { error: "Cannot update finalized schedule" }, status: :unprocessable_entity
          return
        end

        if @schedule.update(schedule_params)
          render json: schedule_response(@schedule)
        else
          render json: { errors: @schedule.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/corporate_tax_schedules/:id
      def destroy
        if @schedule.finalized?
          render json: { error: "Cannot delete finalized schedule" }, status: :unprocessable_entity
          return
        end

        @schedule.destroy
        head :no_content
      end

      # POST /api/v1/corporate_tax_schedules/:id/generate
      def generate
        fiscal_year = FiscalYear.find(params[:fiscal_year_id])

        generator = Tax::CorporateScheduleGenerator.new(
          tenant: current_tenant,
          fiscal_year: fiscal_year
        )

        case @schedule.schedule_type
        when "schedule_16_1"
          result = generator.generate_schedule_16_1
        when "schedule_16_2"
          result = generator.generate_schedule_16_2
        when "schedule_16_6"
          result = generator.generate_schedule_16_6
        when "schedule_16_7"
          result = generator.generate_schedule_16_7
        else
          render json: { error: "Unknown schedule type" }, status: :bad_request
          return
        end

        if result[:success]
          render json: schedule_response(result[:schedule])
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/corporate_tax_schedules/generate_all
      def generate_all
        fiscal_year = FiscalYear.find(params[:fiscal_year_id])

        generator = Tax::CorporateScheduleGenerator.new(
          tenant: current_tenant,
          fiscal_year: fiscal_year
        )

        results = generator.generate_all

        successful = results.select { |_, v| v[:success] }
        failed = results.reject { |_, v| v[:success] }

        render json: {
          success: failed.empty?,
          generated: successful.keys,
          failed: failed.keys,
          schedules: successful.map { |_, v| schedule_response(v[:schedule]) }
        }
      end

      # POST /api/v1/corporate_tax_schedules/:id/finalize
      def finalize
        if @schedule.finalized?
          render json: { error: "Schedule is already finalized" }, status: :unprocessable_entity
          return
        end

        @schedule.finalize!
        render json: schedule_response(@schedule)
      end

      # GET /api/v1/corporate_tax_schedules/:id/export_csv
      def export_csv
        csv_data = generate_csv(@schedule)

        send_data csv_data,
          filename: "schedule_#{@schedule.schedule_type}_#{@schedule.fiscal_year.year}.csv",
          type: "text/csv"
      end

      private

      def set_schedule
        @schedule = current_tenant.corporate_tax_schedules.find(params[:id])
      end

      def schedule_params
        params.require(:corporate_tax_schedule).permit(
          :fiscal_year_id,
          :schedule_type,
          :data_json,
          :status,
          :notes
        )
      end

      def schedule_response(schedule)
        {
          id: schedule.id,
          fiscal_year_id: schedule.fiscal_year_id,
          fiscal_year: schedule.fiscal_year.year,
          schedule_type: schedule.schedule_type,
          schedule_type_name: schedule_type_name(schedule.schedule_type),
          data_json: schedule.data_json,
          status: schedule.status,
          notes: schedule.notes,
          finalized_at: schedule.finalized_at,
          created_at: schedule.created_at,
          updated_at: schedule.updated_at
        }
      end

      def schedule_type_name(type)
        {
          "schedule_16_1" => "別表十六(一) 定額法償却資産",
          "schedule_16_2" => "別表十六(二) 定率法償却資産",
          "schedule_16_6" => "別表十六(六) 一括償却資産",
          "schedule_16_7" => "別表十六(七) 少額減価償却資産"
        }[type] || type
      end

      def generate_csv(schedule)
        require "csv"

        data = schedule.data_json
        return "" unless data

        CSV.generate do |csv|
          case schedule.schedule_type
          when "schedule_16_1", "schedule_16_2"
            csv << [ "資産名", "勘定科目", "取得日", "取得価額", "耐用年数", "期首帳簿価額", "当期償却額", "期末帳簿価額" ]
            data["items"]&.each do |item|
              csv << [
                item["asset_name"],
                item["account_item"],
                item["acquisition_date"],
                item["acquisition_cost"],
                item["useful_life_years"],
                item["opening_book_value"],
                item["depreciation_amount"],
                item["closing_book_value"]
              ]
            end
            csv << [ "合計", "", "", data["total_acquisition_cost"], "", data["total_opening_book_value"], data["total_depreciation_amount"], data["total_closing_book_value"] ]
          when "schedule_16_6"
            csv << [ "資産名", "取得日", "取得価額", "経過年数", "年間償却額", "当期償却額", "残存年数" ]
            data["items"]&.each do |item|
              csv << [
                item["asset_name"],
                item["acquisition_date"],
                item["acquisition_cost"],
                item["years_elapsed"],
                item["annual_depreciation"],
                item["depreciation_amount"],
                item["remaining_years"]
              ]
            end
            csv << [ "合計", "", data["total_acquisition_cost"], "", "", data["total_depreciation_amount"], "" ]
          when "schedule_16_7"
            csv << [ "資産名", "取得日", "取得価額", "当期償却額" ]
            data["items"]&.each do |item|
              csv << [
                item["asset_name"],
                item["acquisition_date"],
                item["acquisition_cost"],
                item["depreciation_amount"]
              ]
            end
            csv << [ "合計", "", data["total_acquisition_cost"], data["total_depreciation_amount"] ]
          end
        end
      end
    end
  end
end
