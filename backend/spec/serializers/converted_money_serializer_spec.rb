require "rails_helper"

RSpec.describe ConvertedMoneySerializer do
  it "labels a converted amount with its target currency and rate date" do
    expect(described_class.call(BigDecimal("140400.54"), Date.new(2026, 10, 1))).to eq(
      amount: "140400.54", currency: "USD", converted: true, rates_as_of: "2026-10-01",
      label: "USD, converted at fixed rates as of 2026-10-01"
    )
  end

  it "explains a missing amount" do
    expect(described_class.call(nil, Date.new(2026, 10, 1))).to include(
      amount: nil, converted: true, label: "USD conversion unavailable: an exchange rate is missing"
    )
  end

  it "labels a zero total that needed no rate" do
    expect(described_class.call(BigDecimal("0"), nil)).to include(amount: "0.00", rates_as_of: nil,
                                                                 label: "USD, converted at fixed rates")
  end
end
