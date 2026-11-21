require "rails_helper"

RSpec.describe "API insights", type: :request do
  include_context "salary statistics data"

  it_behaves_like "requires authentication", :get, "/api/insights/countries"
  it_behaves_like "requires authentication", :get, -> { "/api/insights/countries/#{india.id}" }
  it_behaves_like "requires authentication", :get, "/api/insights/summary"

  context "when logged in" do
    before { sign_in }

    describe "GET /api/insights/countries" do
      it "returns local statistics as strings and a labelled USD total per country" do
        get "/api/insights/countries"

        expect(response).to have_http_status(:ok)
        india_row = response.parsed_body["countries"].find { |row| row.dig("country", "code") == "IN" }
        expect(india_row).to eq(
          "country" => { "id" => india.id, "code" => "IN", "name" => "India", "currency_code" => "INR" },
          "headcount" => 4,
          "min_salary" => { "amount" => "1000000.00", "currency" => "INR" },
          "max_salary" => { "amount" => "4000000.00", "currency" => "INR" },
          "average_salary" => { "amount" => "2500000.00", "currency" => "INR" },
          "median_salary" => { "amount" => "2500000.00", "currency" => "INR" },
          "total_payroll" => { "amount" => "10000000.00", "currency" => "INR" },
          "total_payroll_usd" => { "amount" => "120000.00", "currency" => "USD", "converted" => true,
                                   "rates_as_of" => "2026-10-01",
                                   "label" => "USD, converted at fixed rates as of 2026-10-01" }
        )
      end

      it "returns null statistics for a country with no active employees" do
        get "/api/insights/countries"

        france_row = response.parsed_body["countries"].find { |row| row.dig("country", "code") == "FR" }
        expect(france_row).to include("headcount" => 0, "median_salary" => nil,
                                      "total_payroll" => { "amount" => "0.00", "currency" => "EUR" })
      end
    end

    describe "GET /api/insights/countries/:id" do
      it "groups by department by default, in the country's currency" do
        get "/api/insights/countries/#{india.id}"

        expect(response).to have_http_status(:ok)
        body = response.parsed_body
        expect(body).to include("group_by" => "department", "country" => include("code" => "IN"))
        expect(body["groups"].first).to include(
          "group" => { "id" => engineering.id, "name" => "Engineering" }, "headcount" => 3,
          "average_salary" => { "amount" => "2333333.33", "currency" => "INR" },
          "median_salary" => { "amount" => "2000000.00", "currency" => "INR" }
        )
      end

      it "groups by job title" do
        get "/api/insights/countries/#{india.id}", params: { group_by: "job_title" }

        expect(response.parsed_body["groups"].map { |g| g.dig("group", "name") }).to eq(%w[ Engineer Manager ])
      end

      it "returns an empty list for a country with no active employees" do
        get "/api/insights/countries/#{france.id}"

        expect(response.parsed_body["groups"]).to eq([])
      end

      it "returns 422 for any other group_by" do
        get "/api/insights/countries/#{india.id}", params: { group_by: "status" }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body).to eq("errors" => [ "group_by must be one of: department, job_title" ])
      end

      it "returns 404 for an unknown country" do
        get "/api/insights/countries/0"

        expect(response).to have_http_status(:not_found)
      end
    end

    describe "GET /api/insights/summary" do
      it "returns the org headcount and labelled USD totals by country and by department" do
        get "/api/insights/summary"

        expect(response).to have_http_status(:ok)
        body = response.parsed_body
        expect(body).to include(
          "headcount" => 6,
          "total_payroll_usd" => include("amount" => "260400.54", "converted" => true, "rates_as_of" => "2026-09-15")
        )
        expect(body["by_country"].find { |row| row.dig("country", "code") == "DE" })
          .to include("headcount" => 2, "total_payroll_usd" => include("amount" => "140400.54", "currency" => "USD"))
        expect(body["by_department"].find { |row| row.dig("department", "name") == "Engineering" })
          .to include("headcount" => 5,
                      "total_payroll_usd" => include("amount" => "224400.54",
                                                     "label" => "USD, converted at fixed rates as of 2026-09-15"))
      end

      it "has no org-wide average or median" do
        get "/api/insights/summary"

        expect(response.parsed_body.keys).to contain_exactly("headcount", "total_payroll_usd", "by_country", "by_department")
      end
    end
  end
end
