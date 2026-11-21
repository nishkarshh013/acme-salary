require "rails_helper"

RSpec.describe "API employees", type: :request do
  let(:india) { create(:country, code: "IN", name: "India", currency_code: "INR") }
  let(:engineering) { create(:department, name: "Engineering") }
  let(:engineer) { create(:job_title, name: "Engineer") }
  let!(:employee) do
    create(:employee, employee_code: "EMP00001", first_name: "Asha", last_name: "Rao", email: "asha.rao@acme.test",
                      country: india, salary_currency: "INR", department: engineering, job_title: engineer,
                      hire_date: Date.new(2020, 1, 1), current_salary: BigDecimal("2000000.50"), status: "active")
  end

  describe "GET /api/employees" do
    it_behaves_like "requires authentication", :get, "/api/employees"

    context "when logged in" do
      before { sign_in }

      it "returns employees with nested references, money as strings, and page info" do
        get "/api/employees"

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq(
          "employees" => [ {
            "id" => employee.id, "employee_code" => "EMP00001", "first_name" => "Asha", "last_name" => "Rao",
            "email" => "asha.rao@acme.test", "hire_date" => "2020-01-01", "status" => "active",
            "country" => { "id" => india.id, "code" => "IN", "name" => "India", "currency_code" => "INR" },
            "department" => { "id" => engineering.id, "name" => "Engineering" },
            "job_title" => { "id" => engineer.id, "name" => "Engineer" },
            "current_salary" => { "amount" => "2000000.50", "currency" => "INR" }
          } ],
          "meta" => { "page" => 1, "per_page" => 25, "total_count" => 1, "total_pages" => 1 }
        )
      end

      it "passes search, filter, sort and page parameters to the search" do
        create(:employee, first_name: "Ben", last_name: "Rao", country: india, salary_currency: "INR")

        get "/api/employees", params: { q: "rao", country_id: india.id, sort: "current_salary",
                                        direction: "desc", per_page: 1, page: 2 }

        expect(response.parsed_body["employees"].map { |e| e["first_name"] }).to eq([ "Ben" ])
        expect(response.parsed_body["meta"]).to include("page" => 2, "per_page" => 1, "total_count" => 2)
      end

      it "returns 422 with a clear message for sorting by salary without a country" do
        get "/api/employees", params: { sort: "current_salary" }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("errors" => [
          "Sorting by current salary needs a country filter, because salaries are in different currencies"
        ])
      end

      it "runs the same number of queries however many employees are listed" do
        get "/api/employees" # warm up
        few = count_queries { get "/api/employees" }

        5.times do
          create(:employee, country: create(:country, currency_code: "EUR"), salary_currency: "EUR",
                            department: create(:department), job_title: create(:job_title))
        end
        many = count_queries { get "/api/employees" }

        expect(response.parsed_body["employees"].size).to eq(6)
        expect(many).to eq(few)
      end
    end
  end

  describe "GET /api/employees/:id" do
    it_behaves_like "requires authentication", :get, -> { "/api/employees/#{employee.id}" }

    context "when logged in" do
      before { sign_in }

      let(:germany) { create(:country, code: "DE", name: "Germany", currency_code: "EUR") }

      it "returns the employee with lock_version and the history, newest first" do
        create(:employee_assignment, employee: employee, country: india, effective_date: Date.new(2020, 1, 1),
                                     reason: "Hired")
        create(:salary_revision, employee: employee, currency: "INR", amount: BigDecimal("1900000"),
                                 effective_date: Date.new(2020, 1, 1), reason: "Hired")
        create(:salary_revision, employee: employee, currency: "INR", amount: BigDecimal("2000000.50"),
                                 previous_amount: BigDecimal("1900000"), previous_currency: "INR",
                                 effective_date: Date.new(2021, 1, 1), reason: "Annual review")

        get "/api/employees/#{employee.id}"

        expect(response).to have_http_status(:ok)
        body = response.parsed_body["employee"]
        expect(body).to include("employee_code" => "EMP00001", "lock_version" => employee.lock_version,
                                "current_salary" => { "amount" => "2000000.50", "currency" => "INR" })
        expect(body["timeline"].map { |entry| [ entry["type"], entry["effective_date"] ] }).to eq([
          [ "salary_revision", "2021-01-01" ], [ "salary_revision", "2020-01-01" ], [ "assignment", "2020-01-01" ]
        ])
        expect(body["timeline"].first).to include(
          "reason" => "Annual review",
          "amount" => { "amount" => "2000000.50", "currency" => "INR" },
          "previous_amount" => { "amount" => "1900000.00", "currency" => "INR" }
        )
      end

      it "shows an assignment with the one before it" do
        create(:employee_assignment, employee: employee, country: india, effective_date: Date.new(2020, 1, 1))
        create(:employee_assignment, employee: employee, country: germany, effective_date: Date.new(2022, 1, 1),
                                     reason: "Relocation")

        get "/api/employees/#{employee.id}"

        move = response.parsed_body.dig("employee", "timeline").first
        expect(move).to include("type" => "assignment", "reason" => "Relocation")
        expect(move.dig("country", "code")).to eq("DE")
        expect(move.dig("previous", "country", "code")).to eq("IN")
      end

      it "returns 404 for an unknown id" do
        get "/api/employees/0"

        expect(response).to have_http_status(:not_found)
        expect(response.parsed_body).to eq("errors" => [ "Not found" ])
      end
    end
  end
end
