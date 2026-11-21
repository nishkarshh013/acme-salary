module Api
  module Insights
    # GET /api/insights/summary
    class SummariesController < ApplicationController
      def show
        summary = SalaryStatistics.summary
        render json: {
          headcount: summary[:headcount],
          total_payroll_usd: converted(summary),
          by_country: summary[:by_country].map do |row|
            { country: { id: row[:id], code: row[:code], name: row[:name] },
              headcount: row[:headcount], total_payroll_usd: converted(row) }
          end,
          by_department: summary[:by_department].map do |row|
            { department: { id: row[:id], name: row[:name] }, headcount: row[:headcount], total_payroll_usd: converted(row) }
          end
        }
      end

      private

      def converted(row) = ConvertedMoneySerializer.call(row[:total_usd], row[:rates_as_of])
    end
  end
end
