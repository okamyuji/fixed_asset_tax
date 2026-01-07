module Tax
  class CorporateScheduleGenerator
    def initialize(tenant:, fiscal_year:)
      @tenant = tenant
      @fiscal_year = fiscal_year
    end

    def generate_all
      results = {}

      results[:schedule_16_1] = generate_schedule_16_1
      results[:schedule_16_2] = generate_schedule_16_2
      results[:schedule_16_6] = generate_schedule_16_6
      results[:schedule_16_7] = generate_schedule_16_7

      results
    end

    # 別表十六(一): 定額法償却資産
    def generate_schedule_16_1
      assets = fetch_assets_for_schedule("straight_line")
      data = build_schedule_data(assets, "定額法")

      save_or_update_schedule("schedule_16_1", data)
    end

    # 別表十六(二): 定率法償却資産
    def generate_schedule_16_2
      assets = fetch_assets_for_schedule("declining_balance")
      data = build_schedule_data(assets, "定率法")

      save_or_update_schedule("schedule_16_2", data)
    end

    # 別表十六(六): 一括償却資産
    def generate_schedule_16_6
      assets = fetch_lump_sum_assets
      data = build_lump_sum_schedule_data(assets)

      save_or_update_schedule("schedule_16_6", data)
    end

    # 別表十六(七): 少額減価償却資産
    def generate_schedule_16_7
      assets = fetch_small_value_assets
      data = build_small_value_schedule_data(assets)

      save_or_update_schedule("schedule_16_7", data)
    end

    private

    def fetch_assets_for_schedule(depreciation_method)
      @tenant.fixed_assets
        .joins(:depreciation_policy, :property)
        .where(properties: { party: @tenant.parties.where(type: "Corporation") })
        .where(depreciation_policies: {
          method: depreciation_method,
          depreciation_type: "normal"
        })
        .includes(:depreciation_policy, :depreciation_years)
    end

    def fetch_lump_sum_assets
      @tenant.fixed_assets
        .joins(:depreciation_policy, :property)
        .where(properties: { party: @tenant.parties.where(type: "Corporation") })
        .where(depreciation_policies: { depreciation_type: "lump_sum" })
        .includes(:depreciation_policy, :depreciation_years)
    end

    def fetch_small_value_assets
      @tenant.fixed_assets
        .joins(:depreciation_policy, :property)
        .where(properties: { party: @tenant.parties.where(type: "Corporation") })
        .where(depreciation_policies: { depreciation_type: "small_value" })
        .includes(:depreciation_policy, :depreciation_years)
    end

    def build_schedule_data(assets, method_name)
      items = assets.map do |asset|
        depreciation_year = asset.depreciation_years.find_by(fiscal_year: @fiscal_year)

        {
          asset_id: asset.id,
          asset_name: asset.name,
          account_item: asset.account_item_name,
          acquisition_date: asset.acquired_on,
          acquisition_cost: asset.acquisition_cost.to_f,
          useful_life_years: asset.depreciation_policy.useful_life_years,
          depreciation_method: method_name,
          opening_book_value: depreciation_year&.opening_book_value&.to_f || 0,
          depreciation_amount: depreciation_year&.depreciation_amount&.to_f || 0,
          closing_book_value: depreciation_year&.closing_book_value&.to_f || 0
        }
      end

      {
        fiscal_year: @fiscal_year.year,
        method: method_name,
        total_acquisition_cost: items.sum { |i| i[:acquisition_cost] },
        total_opening_book_value: items.sum { |i| i[:opening_book_value] },
        total_depreciation_amount: items.sum { |i| i[:depreciation_amount] },
        total_closing_book_value: items.sum { |i| i[:closing_book_value] },
        items: items,
        generated_at: Time.current
      }
    end

    def build_lump_sum_schedule_data(assets)
      items = assets.map do |asset|
        depreciation_year = asset.depreciation_years.find_by(fiscal_year: @fiscal_year)
        years_elapsed = asset.depreciation_years.count

        {
          asset_id: asset.id,
          asset_name: asset.name,
          acquisition_date: asset.acquired_on,
          acquisition_cost: asset.acquisition_cost.to_f,
          years_elapsed: years_elapsed,
          annual_depreciation: (asset.acquisition_cost / 3.0).to_f,
          depreciation_amount: depreciation_year&.depreciation_amount&.to_f || 0,
          remaining_years: [ 3 - years_elapsed, 0 ].max
        }
      end

      {
        fiscal_year: @fiscal_year.year,
        total_acquisition_cost: items.sum { |i| i[:acquisition_cost] },
        total_depreciation_amount: items.sum { |i| i[:depreciation_amount] },
        items: items,
        generated_at: Time.current
      }
    end

    def build_small_value_schedule_data(assets)
      items = assets.map do |asset|
        depreciation_year = asset.depreciation_years.find_by(fiscal_year: @fiscal_year)

        {
          asset_id: asset.id,
          asset_name: asset.name,
          acquisition_date: asset.acquired_on,
          acquisition_cost: asset.acquisition_cost.to_f,
          depreciation_amount: depreciation_year&.depreciation_amount&.to_f || 0
        }
      end

      {
        fiscal_year: @fiscal_year.year,
        total_acquisition_cost: items.sum { |i| i[:acquisition_cost] },
        total_depreciation_amount: items.sum { |i| i[:depreciation_amount] },
        items: items,
        generated_at: Time.current
      }
    end

    def save_or_update_schedule(schedule_type, data)
      schedule = CorporateTaxSchedule.find_or_initialize_by(
        tenant: @tenant,
        fiscal_year: @fiscal_year,
        schedule_type: schedule_type
      )

      schedule.data_json = data
      schedule.status = "draft" if schedule.new_record?

      if schedule.save
        { success: true, schedule: schedule }
      else
        { success: false, errors: schedule.errors.full_messages }
      end
    end
  end
end
