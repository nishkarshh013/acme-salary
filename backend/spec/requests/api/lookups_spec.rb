require "rails_helper"

RSpec.describe "API lookups", type: :request do
  it_behaves_like "requires authentication", :get, "/api/countries"
  it_behaves_like "requires authentication", :get, "/api/departments"
  it_behaves_like "requires authentication", :get, "/api/job_titles"

  context "when logged in" do
    before { sign_in }

    it "lists countries by name with code and currency" do
      germany = create(:country, code: "DE", name: "Germany", currency_code: "EUR")
      india = create(:country, code: "IN", name: "India", currency_code: "INR")

      get "/api/countries"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("countries" => [
        { "id" => germany.id, "code" => "DE", "name" => "Germany", "currency_code" => "EUR" },
        { "id" => india.id, "code" => "IN", "name" => "India", "currency_code" => "INR" }
      ])
    end

    it "lists departments by name" do
      sales = create(:department, name: "Sales")
      engineering = create(:department, name: "Engineering")

      get "/api/departments"

      expect(response.parsed_body).to eq("departments" => [
        { "id" => engineering.id, "name" => "Engineering" }, { "id" => sales.id, "name" => "Sales" }
      ])
    end

    it "lists job titles by name" do
      title = create(:job_title, name: "Engineer")

      get "/api/job_titles"

      expect(response.parsed_body).to eq("job_titles" => [ { "id" => title.id, "name" => "Engineer" } ])
    end
  end
end
