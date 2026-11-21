require "rails_helper"

RSpec.describe EffectiveDate do
  around { |example| travel_to(Time.zone.local(2026, 6, 15, 12)) { example.run } }

  describe "#errors" do
    it "accepts today, given as a string" do
      date = described_class.new("2026-06-15")

      expect(date.value).to eq(Date.new(2026, 6, 15))
      expect(date.errors).to be_empty
    end

    it "rejects a blank date" do
      expect(described_class.new("").errors).to eq([ "Effective date can't be blank" ])
    end

    it "rejects an unparseable date without raising" do
      date = described_class.new("2026-13-45")

      expect(date.value).to be_nil
      expect(date.errors).to eq([ "Effective date is not a valid date" ])
    end

    it "rejects a future date" do
      expect(described_class.new(Date.new(2026, 6, 16)).errors).to eq([ "Effective date can't be in the future" ])
    end
  end

  describe "#earlier_than_latest_error" do
    let(:date) { described_class.new(Date.new(2026, 3, 1)) }

    it "allows the same day as the latest entry" do
      expect(date.earlier_than_latest_error(Date.new(2026, 3, 1), "assignment")).to be_nil
    end

    it "allows a history with no entries" do
      expect(date.earlier_than_latest_error(nil, "assignment")).to be_nil
    end

    it "names the history and the latest date when earlier" do
      expect(date.earlier_than_latest_error(Date.new(2026, 3, 2), "assignment"))
        .to eq("Effective date can't be earlier than the latest assignment (2026-03-02)")
    end
  end
end
