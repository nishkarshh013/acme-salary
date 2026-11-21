require "rails_helper"

RSpec.describe Seeds::HrManager do
  def seed(env:, rails_env:)
    described_class.call(env: env, rails_env: ActiveSupport::EnvironmentInquirer.new(rails_env), out: StringIO.new)
  end

  let(:credentials) { { "HR_EMAIL" => "Manager@Acme.Test", "HR_PASSWORD" => "from-the-environment" } }

  it "creates the account from HR_EMAIL and HR_PASSWORD" do
    user = seed(env: credentials, rails_env: "production")

    expect(user.email_address).to eq("manager@acme.test")
    expect(user.authenticate("from-the-environment")).to eq(user)
  end

  it "falls back to the demo credentials in development" do
    user = seed(env: {}, rails_env: "development")

    expect(user.email_address).to eq(described_class::DEMO_EMAIL)
    expect(user.authenticate(described_class::DEMO_PASSWORD)).to eq(user)
  end

  it "refuses to use demo credentials outside development" do
    expect { seed(env: {}, rails_env: "production") }
      .to raise_error(described_class::MissingCredentialsError, /HR_EMAIL and HR_PASSWORD/)
      .and not_change(User, :count)
  end

  it "requires both variables outside development" do
    expect { seed(env: { "HR_EMAIL" => "manager@acme.test" }, rails_env: "production") }
      .to raise_error(described_class::MissingCredentialsError)
  end

  it "leaves an existing account and its password unchanged" do
    existing = create(:user, email_address: "manager@acme.test", password: "original-password")

    expect { seed(env: credentials, rails_env: "production") }.not_to change(User, :count)
    expect(existing.reload.authenticate("original-password")).to eq(existing)
  end
end
