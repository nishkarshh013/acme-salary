require "rails_helper"

RSpec.describe Session, type: :model do
  it { is_expected.to belong_to(:user) }

  describe "#expired?" do
    around { |example| travel_to(Time.zone.local(2026, 6, 15, 9)) { example.run } }

    let(:session) { create(:user).sessions.create!(ip_address: "127.0.0.1", user_agent: "RSpec") }

    it "is false just under 12 hours after login" do
      travel_to(session.created_at + 12.hours - 1.second)

      expect(session).not_to be_expired
    end

    it "is true 12 hours after login" do
      travel_to(session.created_at + 12.hours)

      expect(session).to be_expired
    end
  end

  it "is removed with its user" do
    user = create(:user)
    user.sessions.create!(ip_address: "127.0.0.1", user_agent: "RSpec")

    expect { user.destroy }.to change(described_class, :count).by(-1)
  end
end
