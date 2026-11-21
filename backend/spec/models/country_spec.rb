require "rails_helper"

RSpec.describe Country, type: :model do
  subject { build(:country) }

  describe "associations" do
    it { is_expected.to have_many(:employees).dependent(:restrict_with_error) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:code) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:currency_code) }
    it { is_expected.to validate_uniqueness_of(:code).ignoring_case_sensitivity }

    it { is_expected.to allow_value("IN").for(:code) }
    it { is_expected.not_to allow_value("IND", "I", "1N").for(:code) }

    it { is_expected.to allow_value("INR").for(:currency_code) }
    it { is_expected.not_to allow_value("RUPEE", "IN", "12A").for(:currency_code) }
  end

  describe "database" do
    it { is_expected.to have_db_index(:code).unique }
  end

  describe "normalization" do
    it "upcases and strips code and currency_code" do
      country = build(:country, code: " in ", currency_code: "inr ")

      expect(country.code).to eq("IN")
      expect(country.currency_code).to eq("INR")
    end
  end

  describe "deletion" do
    it "is blocked while employees belong to the country" do
      country = create(:country)
      create(:employee, country: country)

      expect(country.destroy).to be(false)
      expect(country.errors[:base]).to be_present
    end
  end
end
