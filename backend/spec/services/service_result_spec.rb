require "rails_helper"

RSpec.describe ServiceResult do
  it "carries the record on success, with no errors" do
    result = described_class.success(:record)

    expect(result).to be_success
    expect(result.record).to eq(:record)
    expect(result.errors).to eq([])
  end

  it "carries error messages on failure" do
    result = described_class.failure([ "First", "Second" ])

    expect(result).to be_failure
    expect(result).not_to be_success
    expect(result.errors).to eq([ "First", "Second" ])
  end

  it "wraps a single error message in an array" do
    expect(described_class.failure("Only one").errors).to eq([ "Only one" ])
  end
end
