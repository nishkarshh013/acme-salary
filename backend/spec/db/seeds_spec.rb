require "rails_helper"

# Loads db/seeds.rb itself. Only the "existing data" path is exercised here;
# generating 10,000 employees is covered at small scale by the generator spec.
RSpec.describe "db/seeds.rb" do
  def run_seeds(env)
    stub_const("ENV", ENV.to_h.merge(env))
    load Rails.root.join("db/seeds.rb")
  end

  let(:credentials) { { "HR_EMAIL" => "manager@acme.test", "HR_PASSWORD" => "from-the-environment" } }

  context "when employee data already exists" do
    before { create(:employee) }

    it "creates the missing HR user, skips generation and does not exit" do
      expect { run_seeds(credentials) }
        .to output(/Created the HR manager account.*skipped generating demo data.*db:seed:replant/m).to_stdout
        .and change(User, :count).by(1)
        .and not_change(Employee, :count)
    end

    it "can run again without error, leaving the HR user unchanged" do
      create(:user, email_address: "manager@acme.test", password: "original-password")

      expect { run_seeds(credentials) }
        .to output(/already exists.*skipped generating demo data/m).to_stdout
        .and not_change(User, :count)
    end
  end

  it "exits with an error when the HR credentials are missing outside development" do
    expect { run_seeds("HR_EMAIL" => "", "HR_PASSWORD" => "") }
      .to raise_error(SystemExit) { |error| expect(error.status).not_to eq(0) }
      .and output(/HR_EMAIL and HR_PASSWORD/).to_stderr
  end
end
