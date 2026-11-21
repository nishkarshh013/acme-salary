require "rails_helper"

RSpec.describe Employees::Search do
  let(:india) { create(:country, code: "IN", currency_code: "INR") }
  let(:usa) { create(:country, code: "US", currency_code: "USD") }
  let(:engineering) { create(:department, name: "Engineering") }
  let(:sales) { create(:department, name: "Sales") }
  let(:engineer) { create(:job_title, name: "Engineer") }
  let(:manager) { create(:job_title, name: "Manager") }

  let!(:asha) do
    create(:employee, employee_code: "EMP00001", first_name: "Asha", last_name: "Rao", email: "asha.rao@acme.test",
                      country: india, salary_currency: "INR", department: engineering, job_title: engineer,
                      hire_date: Date.new(2020, 1, 1), current_salary: BigDecimal("2000000"), status: "active")
  end
  let!(:ben) do
    create(:employee, employee_code: "EMP00002", first_name: "Ben", last_name: "Rao", email: "ben.rao@acme.test",
                      country: usa, salary_currency: "USD", department: sales, job_title: engineer,
                      hire_date: Date.new(2019, 5, 1), current_salary: BigDecimal("90000"), status: "active")
  end
  let!(:cara) do
    create(:employee, employee_code: "EMP00003", first_name: "Cara", last_name: "Smith", email: "cara.smith@acme.test",
                      country: india, salary_currency: "INR", department: sales, job_title: manager,
                      hire_date: Date.new(2018, 3, 1), current_salary: BigDecimal("3000000"), status: "inactive")
  end
  let!(:dev) do
    create(:employee, employee_code: "EMP00004", first_name: "Dev", last_name: "Patel", email: "dev.patel@acme.test",
                      country: india, salary_currency: "INR", department: engineering, job_title: manager,
                      hire_date: Date.new(2021, 7, 1), current_salary: BigDecimal("1500000"), status: "active")
  end

  def search(**params) = described_class.call(params)

  def found(**params)
    result = search(**params)
    raise "search failed: #{result.errors}" unless result.success?

    result.record.employees
  end

  describe "defaults" do
    it "lists active employees sorted by last name, then id" do
      expect(found).to eq([ dev, asha, ben ])
    end
  end

  describe "status" do
    it "shows only inactive employees" do
      expect(found(status: "inactive")).to eq([ cara ])
    end

    it "shows everyone with 'all'" do
      expect(found(status: "all")).to contain_exactly(asha, ben, cara, dev)
    end

    it "rejects an unknown status" do
      expect(search(status: "retired").errors).to eq([ "status must be one of: active, inactive, all" ])
    end
  end

  describe "search term" do
    it "matches last name, case-insensitively" do
      expect(found(q: "RAO")).to eq([ asha, ben ])
    end

    it "matches first name" do
      expect(found(q: "dev")).to eq([ dev ])
    end

    it "matches the full name, ignoring extra spaces" do
      expect(found(q: "  asha   rao ")).to eq([ asha ])
    end

    it "matches email" do
      expect(found(q: "ben.rao@")).to eq([ ben ])
    end

    it "matches employee code" do
      expect(found(q: "emp00004")).to eq([ dev ])
    end

    it "treats LIKE wildcards as literal characters" do
      expect(found(q: "%")).to be_empty
      expect(found(q: "_")).to be_empty
    end

    it "combines with the status filter" do
      expect(found(q: "smith")).to be_empty
      expect(found(q: "smith", status: "all")).to eq([ cara ])
    end
  end

  describe "filters" do
    it "filters by country" do
      expect(found(country_id: india.id.to_s)).to eq([ dev, asha ])
    end

    it "filters by department" do
      expect(found(department_id: sales.id)).to eq([ ben ])
    end

    it "filters by job title" do
      expect(found(job_title_id: manager.id)).to eq([ dev ])
    end

    it "combines filters" do
      expect(found(country_id: india.id, department_id: engineering.id, job_title_id: engineer.id)).to eq([ asha ])
    end

    it "rejects a non-numeric filter value" do
      expect(search(country_id: "abc").errors).to eq([ "country_id must be a positive integer" ])
    end
  end

  describe "sorting" do
    it "sorts by hire date, newest first" do
      expect(found(sort: "hire_date", direction: "desc")).to eq([ dev, asha, ben ])
    end

    it "sorts by employee code" do
      expect(found(sort: "employee_code")).to eq([ asha, ben, dev ])
    end

    it "sorts by current salary within a country" do
      expect(found(sort: "current_salary", direction: "desc", country_id: india.id)).to eq([ asha, dev ])
    end

    it "refuses to sort by current salary across countries" do
      expect(search(sort: "current_salary").errors)
        .to eq([ "Sorting by current salary needs a country filter, because salaries are in different currencies" ])
    end

    it "rejects a column outside the allowlist" do
      expect(search(sort: "email").errors).to eq([ "sort must be one of: employee_code, last_name, hire_date, current_salary" ])
    end

    it "rejects an unknown direction" do
      expect(search(direction: "sideways").errors).to eq([ "direction must be asc or desc" ])
    end
  end

  describe "pagination" do
    it "returns the requested page with the total count" do
      page = search(status: "all", sort: "employee_code", per_page: "2", page: "2").record

      expect(page.employees).to eq([ cara, dev ])
      expect(page).to have_attributes(page: 2, per_page: 2, total_count: 4, total_pages: 2)
    end

    it "defaults to 25 per page" do
      expect(search.record).to have_attributes(page: 1, per_page: 25, total_count: 3, total_pages: 1)
    end

    it "caps per_page at 100" do
      expect(search(per_page: 500).record.per_page).to eq(100)
    end

    it "returns an empty page past the end" do
      expect(search(page: 9).record).to have_attributes(employees: [], total_count: 3)
    end

    it "rejects a page that isn't a positive integer" do
      expect(search(page: "0", per_page: "x").errors)
        .to eq([ "page must be a positive integer", "per_page must be a positive integer" ])
    end
  end

  it "reports every invalid parameter at once" do
    expect(search(status: "x", sort: "x", direction: "x").errors.size).to eq(3)
  end
end
