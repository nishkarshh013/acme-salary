require "rails_helper"

RSpec.describe "API assignments", type: :request do
  include_context "employee with history"

  it_behaves_like "requires authentication", :post, -> { "/api/employees/#{employee.id}/assignments" }

  context "when logged in" do
    before { sign_in }

    def change_assignment(id: employee.id, **params)
      post "/api/employees/#{id}/assignments",
           params: { effective_date: "2026-06-01", reason: "Reorganisation",
                     lock_version: employee.lock_version }.merge(params),
           as: :json
    end

    it "records a department change and returns 201 with the updated employee" do
      expect { change_assignment(department_id: sales.id) }.to change(EmployeeAssignment, :count).by(1)

      expect(response).to have_http_status(:created)
      body = response.parsed_body["employee"]
      expect(body.dig("department", "name")).to eq("Sales")
      expect(body["timeline"].first).to include("type" => "assignment", "reason" => "Reorganisation")
      expect(body["timeline"].first.dig("previous", "department", "name")).to eq("Engineering")
    end

    it "records a country move with a new salary in the new currency" do
      change_assignment(country_id: germany.id, new_salary: "65000.00", reason: "Relocation")

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["employee"]).to include(
        "country" => include("code" => "DE"),
        "current_salary" => { "amount" => "65000.00", "currency" => "EUR" }
      )
    end

    it "returns 404 for an unknown employee" do
      expect { change_assignment(department_id: sales.id, id: 0) }.not_to change(EmployeeAssignment, :count)

      expect(response).to have_http_status(:not_found)
    end

    it "returns 409 for a stale lock_version and changes nothing" do
      before_snapshot = employee_snapshot(employee)

      change_assignment(department_id: sales.id, lock_version: employee.lock_version - 1)

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body).to eq("errors" => [ OptimisticLocking::STALE_MESSAGE ])
      expect(employee_snapshot(employee)).to eq(before_snapshot)
    end

    it "returns 422 for a business-rule failure and changes nothing" do
      before_snapshot = employee_snapshot(employee)

      change_assignment(country_id: germany.id)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body)
        .to eq("errors" => [ "New salary is required when the salary currency changes (INR to EUR)" ])
      expect(employee_snapshot(employee)).to eq(before_snapshot)
    end

    it "returns 422 for an unknown country, department or job title, instead of keeping the current one" do
      before_snapshot = employee_snapshot(employee)

      change_assignment(country_id: 0, job_title_id: 0, department_id: sales.id)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body).to eq("errors" => [ "Country not found", "Job title not found" ])
      expect(employee_snapshot(employee)).to eq(before_snapshot)
    end
  end
end
