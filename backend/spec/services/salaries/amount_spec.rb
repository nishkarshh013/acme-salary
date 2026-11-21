require "rails_helper"

RSpec.describe Salaries::Amount do
  def amount(raw, label: "Salary") = described_class.new(raw, label: label)

  it "parses a string exactly, with no errors" do
    parsed = amount("1234567.89")

    expect(parsed.value).to eq(BigDecimal("1234567.89"))
    expect(parsed.errors).to be_empty
  end

  it "accepts a BigDecimal" do
    expect(amount(BigDecimal("500.00")).errors).to be_empty
  end

  it "starts every message with the label" do
    expect(amount("", label: "New salary").errors).to eq([ "New salary can't be blank" ])
  end

  {
    "" => "Salary can't be blank",
    nil => "Salary can't be blank",
    "abc" => "Salary is not a number",
    "Infinity" => "Salary is not a number",
    "100.555" => "Salary can have at most 2 decimal places",
    "0" => "Salary must be greater than 0",
    "-1.00" => "Salary must be greater than 0",
    "10000000000000.00" => "Salary is too large"
  }.each do |raw, message|
    it "rejects #{raw.inspect} with #{message.inspect}, without raising" do
      expect(amount(raw).errors).to eq([ message ])
    end
  end
end
