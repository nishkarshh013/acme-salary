require "rails_helper"

RSpec.describe ExchangeRate, type: :model do
  subject { build(:exchange_rate) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:currency_code) }
    it { is_expected.to validate_presence_of(:rate_to_usd) }
    it { is_expected.to validate_presence_of(:as_of) }
    it { is_expected.to validate_uniqueness_of(:currency_code).ignoring_case_sensitivity }
    it { is_expected.to validate_numericality_of(:rate_to_usd).is_greater_than(0) }

    it { is_expected.to allow_value("INR").for(:currency_code) }
    it { is_expected.not_to allow_value("RUPEE", "IN", "12A").for(:currency_code) }
  end

  describe "normalization" do
    it "upcases and strips currency_code" do
      expect(build(:exchange_rate, currency_code: " inr ").currency_code).to eq("INR")
    end
  end

  describe "rate" do
    it "keeps eight decimal places without float rounding" do
      rate = create(:exchange_rate, currency_code: "INR", rate_to_usd: BigDecimal("0.01204819"))

      expect(rate.reload.rate_to_usd).to eq(BigDecimal("0.01204819"))
    end

    it "is rejected by the database when not positive" do
      rate = build(:exchange_rate, rate_to_usd: 0)

      expect { rate.save(validate: false) }
        .to raise_error(ActiveRecord::StatementInvalid, /exchange_rates_rate_to_usd_positive/)
    end

    it "allows only one rate per currency, even when validations are skipped" do
      create(:exchange_rate, currency_code: "INR")
      duplicate = build(:exchange_rate, currency_code: "INR")

      expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
