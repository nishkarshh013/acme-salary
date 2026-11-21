require "rails_helper"

RSpec.describe "API employee writes", type: :request do
  include_context "employee with history"

  describe "POST /api/employees" do
    it_behaves_like "requires authentication", :post, "/api/employees"

    context "when logged in" do
      before { sign_in }

      let(:hire_params) do
        { first_name: "Ben", last_name: "Iyer", email: "ben.iyer@acme.test", hire_date: "2026-06-01",
          country_id: germany.id, department_id: sales.id, job_title_id: engineer.id,
          salary: "65000.00", reason: "New hire" }
      end

      it "hires the employee with the next code and returns 201 with the full employee" do
        Employee.find(employee.id).update_columns(employee_code: "EMP10000")

        expect { post "/api/employees", params: hire_params, as: :json }.to change(Employee, :count).by(1)

        expect(response).to have_http_status(:created)
        body = response.parsed_body["employee"]
        expect(body).to include(
          "employee_code" => "EMP10001", "first_name" => "Ben", "status" => "active", "lock_version" => 0,
          "current_salary" => { "amount" => "65000.00", "currency" => "EUR" }
        )
        expect(body["timeline"].map { |entry| [ entry["type"], entry["reason"] ] })
          .to contain_exactly([ "salary_revision", "New hire" ], [ "assignment", "New hire" ])
      end

      it "ignores a client-supplied employee code" do
        post "/api/employees", params: hire_params.merge(employee_code: "CUSTOM-1"), as: :json

        expect(response.parsed_body.dig("employee", "employee_code")).not_to eq("CUSTOM-1")
      end

      it "defaults the reason to 'Hired'" do
        post "/api/employees", params: hire_params.except(:reason), as: :json

        expect(response.parsed_body.dig("employee", "timeline").map { |e| e["reason"] }).to all(eq("Hired"))
      end

      it "returns 422 with every validation message and creates nothing" do
        expect do
          post "/api/employees", params: hire_params.merge(first_name: "", email: "nope"), as: :json
        end.to not_change(Employee, :count).and not_change(SalaryRevision, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body["errors"]).to include("First name can't be blank", "Email is invalid")
      end

      it "returns 400 naming an unknown field, and creates nothing" do
        expect { post "/api/employees", params: hire_params.merge(middle_name: "K"), as: :json }
          .not_to change(Employee, :count)

        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body).to eq("errors" => [ "Unknown parameter: middle_name" ])
      end

      it "returns 422 for a business-rule failure" do
        post "/api/employees", params: hire_params.merge(salary: "100.555"), as: :json

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("errors" => [ "Salary can have at most 2 decimal places" ])
      end
    end
  end

  describe "PATCH /api/employees/:id" do
    it_behaves_like "requires authentication", :patch, -> { "/api/employees/#{employee.id}" }

    context "when logged in" do
      before { sign_in }

      def patch_employee(id: employee.id, **params)
        patch "/api/employees/#{id}", params: { lock_version: employee.lock_version }.merge(params), as: :json
      end

      it "updates name, email and status and returns the employee with the new lock_version" do
        patch_employee(first_name: "Asha M", email: "asha.m@acme.test", status: "inactive")

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["employee"]).to include(
          "first_name" => "Asha M", "email" => "asha.m@acme.test", "status" => "inactive",
          "lock_version" => employee.lock_version + 1
        )
      end

      it "returns 404 for an unknown employee" do
        patch_employee(first_name: "X", id: 0)

        expect(response).to have_http_status(:not_found)
        expect(response.parsed_body).to eq("errors" => [ "Not found" ])
      end

      it "returns 409 for a stale lock_version and changes nothing" do
        before_snapshot = employee_snapshot(employee)

        patch_employee(first_name: "Changed", lock_version: employee.lock_version - 1)

        expect(response).to have_http_status(:conflict)
        expect(response.parsed_body).to eq("errors" => [ OptimisticLocking::STALE_MESSAGE ])
        expect(employee_snapshot(employee)).to eq(before_snapshot)
      end

      it "returns 422 for a salary, country or hire date change, and changes nothing" do
        before_snapshot = employee_snapshot(employee)

        patch_employee(first_name: "Changed", current_salary: "1", country_id: germany.id, hire_date: "2020-01-01")

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body["errors"]).to contain_exactly(
          "Salary can't be changed here; record a salary revision instead",
          "Country can't be changed here; record an assignment change instead",
          "Hire date can't be changed"
        )
        expect(employee_snapshot(employee)).to eq(before_snapshot)
      end

      # Development and test only: production drops unknown parameters.
      it "returns 400 naming an unknown field, and changes nothing" do
        before_snapshot = employee_snapshot(employee)

        patch_employee(first_name: "Changed", nickname: "Ash")

        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body).to eq("errors" => [ "Unknown parameter: nickname" ])
        expect(employee_snapshot(employee)).to eq(before_snapshot)
      end

      it "returns 422 for an invalid email and changes nothing" do
        before_snapshot = employee_snapshot(employee)

        patch_employee(email: "not-an-email")

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("errors" => [ "Email is invalid" ])
        expect(employee_snapshot(employee)).to eq(before_snapshot)
      end
    end
  end
end
