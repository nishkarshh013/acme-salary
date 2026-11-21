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

  it "marks failures as invalid by default" do
    result = described_class.failure("Broken rule")

    expect(result.error_type).to eq(:invalid)
    expect(result).not_to be_stale
  end

  it "can mark a failure as stale" do
    expect(described_class.failure("Changed elsewhere", error_type: :stale)).to be_stale
  end

  it "wraps a single error message in an array" do
    expect(described_class.failure("Only one").errors).to eq([ "Only one" ])
  end
end
