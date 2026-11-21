module Seeds
  # Fixed reference data for the demo seed. Amounts are BigDecimal; the only
  # floats are the headcount weights, which never touch money.
  module ReferenceData
    # Exchange rates are fixed and dated, as the requirements describe.
    # rate_to_usd is the USD value of one unit of the currency.
    RATES_AS_OF = Date.new(2026, 10, 1)

    # factor scales the USD band to the local market; round_to is the step
    # salaries are rounded to in that currency; weight sets uneven headcount.
    Country = Data.define(:code, :name, :currency_code, :rate_to_usd, :factor, :round_to, :weight)

    COUNTRIES = [
      Country.new("US", "United States",  "USD", BigDecimal("1.00000000"), BigDecimal("1.00"), 1_000, 28),
      Country.new("IN", "India",          "INR", BigDecimal("0.01200000"), BigDecimal("0.28"), 10_000, 24),
      Country.new("GB", "United Kingdom", "GBP", BigDecimal("1.27000000"), BigDecimal("0.80"), 1_000, 12),
      Country.new("DE", "Germany",        "EUR", BigDecimal("1.08000000"), BigDecimal("0.80"), 1_000, 10),
      Country.new("FR", "France",         "EUR", BigDecimal("1.08000000"), BigDecimal("0.72"), 1_000, 7),
      Country.new("CA", "Canada",         "CAD", BigDecimal("0.73000000"), BigDecimal("0.82"), 1_000, 7),
      Country.new("SG", "Singapore",      "SGD", BigDecimal("0.74000000"), BigDecimal("0.85"), 1_000, 6),
      Country.new("BR", "Brazil",         "BRL", BigDecimal("0.18000000"), BigDecimal("0.32"), 100, 6)
    ].freeze

    # Annual gross base salary band in USD, before the country factor.
    # Titles carry their seniority level; weight sets headcount within the
    # department, so juniors outnumber managers.
    JobTitle = Data.define(:name, :band_min, :band_max, :weight)
    Department = Data.define(:name, :weight, :job_titles)

    def self.title(name, min_k, max_k, weight)
      JobTitle.new(name, BigDecimal(min_k * 1_000), BigDecimal(max_k * 1_000), weight)
    end

    DEPARTMENTS = [
      Department.new("Engineering", 30, [
        title("Software Engineer I", 70, 95, 30),
        title("Software Engineer II", 90, 125, 30),
        title("Senior Software Engineer", 120, 165, 22),
        title("Staff Engineer", 160, 210, 8),
        title("Engineering Manager", 150, 200, 10)
      ]),
      Department.new("Product", 8, [
        title("Product Manager", 110, 150, 70),
        title("Senior Product Manager", 140, 185, 30)
      ]),
      Department.new("Sales", 18, [
        title("Sales Development Representative", 50, 70, 40),
        title("Account Executive", 75, 120, 45),
        title("Sales Manager", 120, 160, 15)
      ]),
      Department.new("Marketing", 8, [
        title("Marketing Specialist", 60, 85, 65),
        title("Marketing Manager", 100, 140, 35)
      ]),
      Department.new("Finance", 7, [
        title("Financial Analyst", 70, 100, 65),
        title("Finance Manager", 120, 160, 35)
      ]),
      Department.new("Human Resources", 6, [
        title("HR Generalist", 60, 85, 70),
        title("HR Business Partner", 95, 130, 30)
      ]),
      Department.new("Operations", 10, [
        title("Operations Analyst", 60, 90, 75),
        title("Operations Manager", 100, 140, 25)
      ]),
      Department.new("Customer Support", 13, [
        title("Support Specialist", 45, 65, 75),
        title("Support Team Lead", 65, 90, 25)
      ])
    ].freeze

    RAISE_REASONS = [ "Annual review", "Merit increase", "Market adjustment" ].freeze
  end
end
