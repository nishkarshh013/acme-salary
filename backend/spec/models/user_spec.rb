require "rails_helper"

RSpec.describe User, type: :model do
  subject { build(:user) }

  describe "associations" do
    it { is_expected.to have_many(:sessions).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:email_address) }
    it { is_expected.to validate_uniqueness_of(:email_address).ignoring_case_sensitivity }
    it { is_expected.to have_secure_password }
  end

  it "normalizes the email address" do
    expect(build(:user, email_address: "  HR@Acme.Test ").email_address).to eq("hr@acme.test")
  end

  describe ".authenticate_by" do
    let!(:user) { create(:user, email_address: "hr@acme.test", password: "correct-horse-battery") }

    it "finds the user with the right password, whatever the email's case" do
      expect(described_class.authenticate_by(email_address: "HR@acme.test", password: "correct-horse-battery"))
        .to eq(user)
    end

    it "returns nil for a wrong password" do
      expect(described_class.authenticate_by(email_address: "hr@acme.test", password: "wrong")).to be_nil
    end
  end
end
