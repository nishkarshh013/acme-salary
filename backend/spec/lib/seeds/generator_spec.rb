require "rails_helper"

RSpec.describe Seeds::Generator do
  # Validations compare effective dates with today; the seed's history ends at AS_OF.
  around { |example| travel_to(Time.zone.local(2026, 11, 21, 12)) { example.run } }

  def generate(count: 50, seed: 1234, **options)
    described_class.new(count: count, seed: seed, out: StringIO.new, **options).call
  end

  # Natural keys only, so two runs compare equal even though ids differ.
  def snapshot
    {
      countries: Country.order(:code).pluck(:code, :name, :currency_code),
      rates: ExchangeRate.order(:currency_code).pluck(:currency_code, :rate_to_usd, :as_of),
      employees: Employee.joins(:country, :department, :job_title).order(:employee_code)
                         .pluck(:employee_code, :first_name, :last_name, :email, :hire_date, :status,
                                "countries.code", "departments.name", "job_titles.name",
                                :current_salary, :salary_currency, :created_at, :updated_at),
      revisions: SalaryRevision.joins(:employee).order("employees.employee_code", :effective_date)
                               .pluck("employees.employee_code", :effective_date, :amount, :currency,
                                      :previous_amount, :previous_currency, :reason, :created_at),
      assignments: EmployeeAssignment.joins(:employee, :country, :department, :job_title)
                                     .order("employees.employee_code", :effective_date)
                                     .pluck("employees.employee_code", :effective_date, "countries.code",
                                            "departments.name", "job_titles.name", :reason, :created_at)
    }
  end

  # Generates inside a savepoint and rolls it back, so the next run starts
  # from an empty database without deleting any history rows.
  def snapshot_of_run(seed:)
    result = nil
    ApplicationRecord.transaction(requires_new: true) do
      generate(seed: seed)
      result = snapshot
      raise ActiveRecord::Rollback
    end
    result
  end

  describe "generated data" do
    before { generate }

    let(:employees) { Employee.includes(:country, :salary_revisions, :employee_assignments).to_a }

    it "creates the requested number of employees with reference data" do
      expect(Employee.count).to eq(50)
      expect(Country.count).to eq(8)
      expect(Country.where(currency_code: "EUR").pluck(:code)).to contain_exactly("DE", "FR")
      expect(ExchangeRate.pluck(:currency_code)).to match_array(Country.distinct.pluck(:currency_code))
      expect(JobTitle.count).to be_between(15, 20)
    end

    it "gives every employee a current salary and currency equal to their latest revision" do
      employees.each do |employee|
        latest = employee.salary_revisions.max_by(&:effective_date)

        expect([ employee.current_salary, employee.salary_currency ])
          .to eq([ latest.amount, latest.currency ]), employee.employee_code
      end
    end

    it "gives every employee a current country, department and job title equal to their latest assignment" do
      employees.each do |employee|
        latest = employee.employee_assignments.max_by(&:effective_date)

        expect([ employee.country_id, employee.department_id, employee.job_title_id ])
          .to eq([ latest.country_id, latest.department_id, latest.job_title_id ]), employee.employee_code
      end
    end

    it "keeps every salary in the currency of the employee's country" do
      employees.each do |employee|
        expect(employee.salary_currency).to eq(employee.country.currency_code), employee.employee_code
      end
    end

    it "sets previous amount and currency on every revision after the first, from the one before" do
      employees.each do |employee|
        first, *later = employee.salary_revisions.sort_by(&:effective_date)

        expect([ first.previous_amount, first.previous_currency ]).to eq([ nil, nil ])
        [ first, *later ].each_cons(2) do |before, after|
          expect([ after.previous_amount, after.previous_currency ])
            .to eq([ before.amount, before.currency ]), employee.employee_code
        end
      end
    end

    it "stores emails in lowercase and leaves every record valid" do
      expect(Employee.pluck(:email)).to all(match(/\A[a-z0-9.]+@acme\.example\z/))
      expect(employees.map(&:valid?)).to all(be(true))
      expect(SalaryRevision.all.map(&:valid?)).to all(be(true))
    end
  end

  describe "country moves" do
    before { generate(move_share: 0.5) }

    it "records an assignment and a revision from the old currency to the new one" do
      moves = SalaryRevision.where.not(previous_currency: nil).where("previous_currency <> currency")

      expect(moves).not_to be_empty
      moves.each do |revision|
        assignment = revision.employee.employee_assignments.find_by!(effective_date: revision.effective_date)

        expect(assignment.reason).to start_with("Relocation to")
        expect(assignment.country.currency_code).to eq(revision.currency)
      end
    end
  end

  describe "determinism" do
    it "produces identical data for the same seed" do
      expect(snapshot_of_run(seed: 1234)).to eq(snapshot_of_run(seed: 1234))
    end

    it "produces different data for a different seed" do
      expect(snapshot_of_run(seed: 1234)[:employees]).not_to eq(snapshot_of_run(seed: 5678)[:employees])
    end

    it "leaves Faker's random generator as it was" do
      expect { generate }.not_to change(Faker::Config, :random)
    end
  end

  describe "an existing database" do
    it "skips with a message pointing to db:seed:replant and changes nothing" do
      create(:employee)
      out = StringIO.new
      result = nil

      expect { result = described_class.new(count: 50, seed: 1234, out: out).call }
        .to not_change(Employee, :count)
        .and not_change(SalaryRevision, :count)
        .and not_change(Country, :count)

      expect(result).to be(false)
      expect(out.string).to include("skipped generating demo data", "bin/rails db:seed:replant")
    end
  end
end
