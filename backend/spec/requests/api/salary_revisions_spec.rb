require "rails_helper"

RSpec.describe "API salary revisions", type: :request do
  include_context "employee with history"

  it_behaves_like "requires authentication", :post, -> { "/api/employees/#{employee.id}/salary_revisions" }

  context "when logged in" do
    before { sign_in }

    def revise(id: employee.id, **params)
      post "/api/employees/#{id}/salary_revisions",
           params: { amount: "1100000.00", effective_date: "2026-06-01", reason: "Annual review",
                     lock_version: employee.lock_version }.merge(params),
           as: :json
    end

    it "records the revision and returns 201 with the updated employee" do
      expect { revise }.to change(SalaryRevision, :count).by(1)

      expect(response).to have_http_status(:created)
      body = response.parsed_body["employee"]
      expect(body).to include("current_salary" => { "amount" => "1100000.00", "currency" => "INR" },
                              "lock_version" => employee.lock_version + 1)
      expect(body["timeline"].first).to include(
        "type" => "salary_revision", "reason" => "Annual review",
        "amount" => { "amount" => "1100000.00", "currency" => "INR" },
        "previous_amount" => { "amount" => "1000000.00", "currency" => "INR" }
      )
    end

    it "returns 404 for an unknown employee" do
      expect { revise(id: 0) }.not_to change(SalaryRevision, :count)

      expect(response).to have_http_status(:not_found)
    end

    it "returns 409 for a stale lock_version and changes nothing" do
      before_snapshot = employee_snapshot(employee)

      revise(lock_version: employee.lock_version - 1)

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body).to eq("errors" => [ OptimisticLocking::STALE_MESSAGE ])
      expect(employee_snapshot(employee)).to eq(before_snapshot)
    end

    it "returns 422 for business-rule failures and changes nothing" do
      before_snapshot = employee_snapshot(employee)

      revise(amount: "0", effective_date: "2026-06-16")

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"])
        .to contain_exactly("Amount must be greater than 0", "Effective date can't be in the future")
      expect(employee_snapshot(employee)).to eq(before_snapshot)
    end
  end
end
