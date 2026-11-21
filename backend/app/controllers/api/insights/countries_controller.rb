module Api
  module Insights
    class CountriesController < ApplicationController
      # GET /api/insights/countries
      def index
        rows = SalaryStatistics.by_country
        render json: {
          countries: rows.map do |row|
            { country: { id: row[:id], code: row[:code], name: row[:name], currency_code: row[:currency] },
              **SalaryStatisticsSerializer.call(row, row[:currency]),
              total_payroll_usd: ConvertedMoneySerializer.call(row[:total_usd], row[:rates_as_of]) }
          end
        }
      end

      # GET /api/insights/countries/:id?group_by=department|job_title
      def show
        country = Country.find(params[:id])
        group_by = params[:group_by].presence || "department"
        result = SalaryStatistics.within_country(country, group_by: group_by)
        return render_failure(result) if result.failure?

        render json: {
          country: CountrySerializer.call(country),
          group_by: group_by,
          groups: result.record.map do |row|
            { group: { id: row[:id], name: row[:name] }, **SalaryStatisticsSerializer.call(row, country.currency_code) }
          end
        }
      end
    end
  end
end
