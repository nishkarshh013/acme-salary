require "rails_helper"

RSpec.describe SalaryStatistics do
  include_context "salary statistics data"

  describe ".by_country" do
    let(:rows) { described_class.by_country.index_by { |row| row[:code] } }

    it "lists every country, sorted by name" do
      expect(described_class.by_country.map { |row| row[:name] }).to eq(%w[ France Germany India Japan ])
    end

    it "computes India's statistics from active employees only, with an even-count median" do
      expect(rows["IN"]).to include(
        currency: "INR", headcount: 4,
        min: BigDecimal("1000000"), max: BigDecimal("4000000"),
        average: BigDecimal("2500000"), median: BigDecimal("2500000"), total: BigDecimal("10000000")
      )
    end

    it "computes a median between two values with cents" do
      expect(rows["DE"]).to include(headcount: 2, median: BigDecimal("65000.25"), average: BigDecimal("65000.25"),
                                    total: BigDecimal("130000.50"))
    end

    it "converts each total to USD exactly, with the date of the rate used" do
      expect(rows["IN"]).to include(total_usd: BigDecimal("120000.00"), rates_as_of: Date.new(2026, 10, 1))
      expect(rows["DE"]).to include(total_usd: BigDecimal("140400.54"), rates_as_of: Date.new(2026, 9, 15))
    end

    it "gives a country with only inactive employees zero headcount, no statistics and a zero total" do
      expect(rows["FR"]).to include(headcount: 0, min: nil, max: nil, average: nil, median: nil,
                                    total: BigDecimal("0"), total_usd: BigDecimal("0"))
    end

    it "includes a country with no employees at all" do
      expect(rows["JP"]).to include(headcount: 0, total: BigDecimal("0"))
    end
  end

  describe ".within_country" do
    def groups(country, group_by) = described_class.within_country(country, group_by: group_by).record

    it "groups India by department, with an odd-count median and a rounded average" do
      engineering_row, sales_row = groups(india, "department")

      expect(engineering_row).to include(
        name: "Engineering", headcount: 3, min: BigDecimal("1000000"), max: BigDecimal("4000000"),
        median: BigDecimal("2000000"), average: BigDecimal("2333333.33"), total: BigDecimal("7000000")
      )
      expect(sales_row).to include(name: "Sales", headcount: 1, median: BigDecimal("3000000"),
                                   total: BigDecimal("3000000"))
    end

    it "groups India by job title" do
      expect(groups(india, "job_title").map { |row| row.values_at(:name, :headcount, :total) }).to eq([
        [ "Engineer", 2, BigDecimal("3000000") ], [ "Manager", 2, BigDecimal("7000000") ]
      ])
    end

    it "is empty for a country with no active employees" do
      expect(groups(france, "department")).to eq([])
    end

    it "rejects any other group_by" do
      result = described_class.within_country(india, group_by: "country")

      expect(result).to be_failure
      expect(result.errors).to eq([ "group_by must be one of: department, job_title" ])
    end
  end

  describe ".summary" do
    let(:summary) { described_class.summary }

    it "counts active employees org-wide and converts the org total to USD" do
      # 120,000.00 (India) + 140,400.54 (Germany)
      expect(summary).to include(headcount: 6, total_usd: BigDecimal("260400.54"), rates_as_of: Date.new(2026, 9, 15))
    end

    it "totals each country in USD" do
      expect(summary[:by_country].map { |row| row.values_at(:code, :headcount, :total_usd) }).to eq([
        [ "FR", 0, BigDecimal("0") ], [ "DE", 2, BigDecimal("140400.54") ],
        [ "IN", 4, BigDecimal("120000.00") ], [ "JP", 0, BigDecimal("0") ]
      ])
    end

    it "converts department totals across currencies, labelled with the oldest rate used" do
      rows = summary[:by_department].index_by { |row| row[:name] }

      # Engineering: 7,000,000 INR x 0.012 = 84,000.00, plus 130,000.50 EUR x 1.08 = 140,400.54
      expect(rows["Engineering"]).to include(headcount: 5, total_usd: BigDecimal("224400.54"),
                                             rates_as_of: Date.new(2026, 9, 15))
      # Sales: only the active 3,000,000 INR counts
      expect(rows["Sales"]).to include(headcount: 1, total_usd: BigDecimal("36000.00"), rates_as_of: Date.new(2026, 10, 1))
      expect(rows["Support"]).to include(headcount: 0, total_usd: BigDecimal("0"), rates_as_of: nil)
    end

    it "has no average or median, which would mix salary markets" do
      expect(summary.keys).not_to include(:average, :median)
    end

    it "leaves a converted total empty, rather than undercounting, when a rate is missing" do
      inr_rate.destroy

      expect(summary[:total_usd]).to be_nil
      expect(summary[:by_department].find { |row| row[:name] == "Sales" }[:total_usd]).to be_nil
      expect(summary[:by_country].find { |row| row[:code] == "DE" }[:total_usd]).to eq(BigDecimal("140400.54"))
    end
  end
end
