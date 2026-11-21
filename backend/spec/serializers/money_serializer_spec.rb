require "rails_helper"

RSpec.describe MoneySerializer do
  it "sends the amount as a string with two decimals and its currency" do
    expect(described_class.call(BigDecimal("100000"), "USD")).to eq(amount: "100000.00", currency: "USD")
  end

  it "keeps large amounts exact, beyond float precision" do
    expect(described_class.call(BigDecimal("9999999999999.99"), "INR")[:amount]).to eq("9999999999999.99")
  end

  it "pads a single decimal" do
    expect(described_class.call(BigDecimal("1234.5"), "EUR")[:amount]).to eq("1234.50")
  end

  it "returns nil for no amount" do
    expect(described_class.call(nil, nil)).to be_nil
  end
end
