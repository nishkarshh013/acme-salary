module Seeds
  # Generates the demo data set: reference data, employees, and their salary
  # and assignment history. Deterministic: the same count and seed produce
  # the same rows on every run, because every random choice (Faker's
  # included) comes from one Random instance and "today" is fixed at AS_OF.
  #
  # Safe to run on any database: if any seeded table already has rows, it
  # prints a message and changes nothing.
  #
  # Rows are written with insert_all!, which skips validations, callbacks and
  # normalizes, so the generator itself keeps emails lowercase, currency
  # codes uppercase, and the employee's current values equal to their latest
  # revision and assignment.
  class Generator
    DEFAULT_SEED = 20_261_121
    BATCH_SIZE = 1_000
    # The generated history ends here, whatever day the seed runs.
    AS_OF = Date.new(2026, 10, 31)
    EARLIEST_HIRE = Date.new(2014, 1, 1)
    MAX_RAISES = 3
    # Later events start at least this many days after the hire date.
    MIN_DAYS_AFTER_HIRE = 90
    EMAIL_DOMAIN = "acme.example".freeze

    Plan = Struct.new(:code, :first_name, :last_name, :email, :hire_date, :status,
                      :department, :job_title, :revisions, :assignments, keyword_init: true)

    def initialize(count:, seed: DEFAULT_SEED, move_share: 0.02, inactive_share: 0.03, out: $stdout)
      @count = count
      @random = Random.new(seed)
      @move_share = move_share
      @inactive_share = inactive_share
      @out = out
      @emails = Set.new
    end

    # Returns false, after printing why, when the database already has data.
    def call
      if existing_data?
        out.puts existing_data_message
        return false
      end

      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      with_faker_random do
        ApplicationRecord.transaction do
          insert_reference_data
          plans = Array.new(count) { |index| plan_employee(index + 1) }
          employee_ids = insert_employees(plans)
          insert_history(plans, employee_ids)
        end
      end
      report(Process.clock_gettime(Process::CLOCK_MONOTONIC) - started)
      true
    end

    private

    attr_reader :count, :random, :move_share, :inactive_share, :out

    SEEDED_TABLES = [ Country, Department, JobTitle, ExchangeRate, Employee ].freeze
    private_constant :SEEDED_TABLES

    def existing_data?
      SEEDED_TABLES.any?(&:exists?)
    end

    def existing_data_message
      "The database already has data (#{Employee.count} employees); skipped generating demo data. " \
        "To reset and reseed, run: bin/rails db:seed:replant"
    end

    def with_faker_random
      previous = Faker::Config.random
      Faker::Config.random = random
      yield
    ensure
      Faker::Config.random = previous
    end

    # --- Reference data ------------------------------------------------------

    def insert_reference_data
      seeded_at = time_on(AS_OF)
      stamps = { created_at: seeded_at, updated_at: seeded_at }

      @country_ids = ids_by(Country, :code, ReferenceData::COUNTRIES.map do |country|
        { code: country.code, name: country.name, currency_code: country.currency_code, **stamps }
      end)
      @department_ids = ids_by(Department, :name, ReferenceData::DEPARTMENTS.map { |d| { name: d.name, **stamps } })
      @job_title_ids = ids_by(JobTitle, :name, ReferenceData::DEPARTMENTS.flat_map(&:job_titles).map do |title|
        { name: title.name, **stamps }
      end)

      rates = ReferenceData::COUNTRIES.uniq(&:currency_code).map do |country|
        { currency_code: country.currency_code, rate_to_usd: country.rate_to_usd,
          as_of: ReferenceData::RATES_AS_OF, **stamps }
      end
      ExchangeRate.insert_all!(rates)
    end

    def ids_by(model, key, rows)
      model.insert_all!(rows, returning: [ :id, key ]).to_h { |row| [ row[key.to_s], row["id"] ] }
    end

    # --- Planning (all random choices happen here, in a fixed order) ---------

    def plan_employee(number)
      department = weighted(ReferenceData::DEPARTMENTS)
      job_title = weighted(department.job_titles)
      country = weighted(ReferenceData::COUNTRIES)
      hire_date = EARLIEST_HIRE + random.rand(0..(AS_OF - EARLIEST_HIRE - MIN_DAYS_AFTER_HIRE).to_i)
      first_name = Faker::Name.first_name
      last_name = Faker::Name.last_name

      plan = Plan.new(
        code: format("EMP%05d", number),
        first_name: first_name,
        last_name: last_name,
        email: unique_email(first_name, last_name, number),
        hire_date: hire_date,
        status: random.rand < inactive_share ? "inactive" : "active",
        department: department,
        job_title: job_title,
        revisions: [],
        assignments: []
      )
      plan_history(plan, country)
      plan
    end

    # Hire, then 0–3 raises and possibly one country move, on distinct dates.
    def plan_history(plan, country)
      position = BigDecimal(random.rand(0..1_000)) / 1_000 # place within the band
      growth = BigDecimal(1) # product of all raises so far
      salary = local_salary(plan.job_title, country, position, growth)

      plan.assignments << { country: country, date: plan.hire_date, reason: "Hired" }
      plan.revisions << { amount: salary, currency: country.currency_code, previous_amount: nil,
                          previous_currency: nil, date: plan.hire_date, reason: "Hired" }

      tenure_years = (AS_OF - plan.hire_date).to_i / 365
      raises = random.rand(0..[ MAX_RAISES, tenure_years ].min)
      moves = tenure_years >= 1 && random.rand < move_share ? 1 : 0
      dates = later_dates(plan.hire_date, raises + moves)
      move_at = moves.positive? ? random.rand(dates.size) : nil

      dates.each_with_index do |date, index|
        previous_salary = salary
        previous_country = country

        if index == move_at
          country = weighted(ReferenceData::COUNTRIES.reject { |c| c.currency_code == country.currency_code })
          salary = local_salary(plan.job_title, country, position, growth)
          reason = "Relocation to #{country.name}"
          plan.assignments << { country: country, date: date, reason: reason }
        else
          raise_factor = 1 + (BigDecimal(random.rand(30..120)) / 1_000) # 3.0% to 12.0%
          growth *= raise_factor
          salary = round_salary(salary * raise_factor, country)
          reason = ReferenceData::RAISE_REASONS[random.rand(ReferenceData::RAISE_REASONS.size)]
        end

        plan.revisions << { amount: salary, currency: country.currency_code, previous_amount: previous_salary,
                            previous_currency: previous_country.currency_code, date: date, reason: reason }
      end
    end

    # n distinct dates after the hire date, sorted, none later than AS_OF.
    def later_dates(hire_date, n)
      first = hire_date + MIN_DAYS_AFTER_HIRE
      return [] if n.zero? || (AS_OF - first).to_i < n

      dates = Set.new
      dates << first + random.rand(0..(AS_OF - first).to_i) while dates.size < n
      dates.sort
    end

    # USD band position, scaled by the country factor and converted with the
    # seeded rate, then rounded to the country's step.
    def local_salary(job_title, country, position, growth)
      usd = job_title.band_min + ((job_title.band_max - job_title.band_min) * position)
      round_salary(usd * growth * country.factor / country.rate_to_usd, country)
    end

    def round_salary(amount, country)
      step = country.round_to
      [ BigDecimal((amount / step).round) * step, BigDecimal(step) ].max
    end

    def weighted(items)
      pick = random.rand(items.sum(&:weight))
      items.find { |item| (pick -= item.weight).negative? }
    end

    def unique_email(first_name, last_name, number)
      local = [ first_name, last_name ].map { |part| I18n.transliterate(part).downcase.gsub(/[^a-z]/, "") }.join(".")
      email = "#{local}@#{EMAIL_DOMAIN}"
      email = "#{local}#{number}@#{EMAIL_DOMAIN}" if @emails.include?(email)
      @emails << email
      email
    end

    # --- Inserting -------------------------------------------------------------

    def insert_employees(plans)
      rows = plans.map { |plan| employee_row(plan) }
      rows.each_slice(BATCH_SIZE).each_with_object({}) do |batch, ids|
        Employee.insert_all!(batch, returning: [ :id, :employee_code ]).each do |row|
          ids[row["employee_code"]] = row["id"]
        end
      end
    end

    # Current values are taken from the last planned revision and assignment.
    def employee_row(plan)
      revision = plan.revisions.last
      assignment = plan.assignments.last
      last_change = [ revision[:date], assignment[:date] ].max

      {
        employee_code: plan.code,
        first_name: plan.first_name,
        last_name: plan.last_name,
        email: plan.email,
        hire_date: plan.hire_date,
        status: plan.status,
        country_id: @country_ids.fetch(assignment[:country].code),
        department_id: @department_ids.fetch(plan.department.name),
        job_title_id: @job_title_ids.fetch(plan.job_title.name),
        current_salary: revision[:amount],
        salary_currency: revision[:currency],
        created_at: time_on(plan.hire_date),
        updated_at: time_on(last_change)
      }
    end

    def insert_history(plans, employee_ids)
      revisions = []
      assignments = []

      plans.each do |plan|
        employee_id = employee_ids.fetch(plan.code)
        plan.revisions.each { |revision| revisions << revision_row(employee_id, revision) }
        plan.assignments.each { |assignment| assignments << assignment_row(employee_id, plan, assignment) }
      end

      revisions.each_slice(BATCH_SIZE) { |batch| SalaryRevision.insert_all!(batch) }
      assignments.each_slice(BATCH_SIZE) { |batch| EmployeeAssignment.insert_all!(batch) }
    end

    def revision_row(employee_id, revision)
      {
        employee_id: employee_id,
        amount: revision[:amount],
        currency: revision[:currency],
        previous_amount: revision[:previous_amount],
        previous_currency: revision[:previous_currency],
        effective_date: revision[:date],
        reason: revision[:reason],
        created_at: time_on(revision[:date])
      }
    end

    def assignment_row(employee_id, plan, assignment)
      {
        employee_id: employee_id,
        country_id: @country_ids.fetch(assignment[:country].code),
        department_id: @department_ids.fetch(plan.department.name),
        job_title_id: @job_title_ids.fetch(plan.job_title.name),
        effective_date: assignment[:date],
        reason: assignment[:reason],
        created_at: time_on(assignment[:date])
      }
    end

    # History rows are stamped as recorded on their effective date.
    def time_on(date)
      Time.utc(date.year, date.month, date.day, 9)
    end

    def report(elapsed)
      out.puts "Seeded #{Country.count} countries, #{ExchangeRate.count} exchange rates, " \
               "#{Department.count} departments, #{JobTitle.count} job titles"
      out.puts "Seeded #{Employee.count} employees, #{SalaryRevision.count} salary revisions, " \
               "#{EmployeeAssignment.count} assignments"
      out.puts format("Finished in %.1f seconds", elapsed)
    end
  end
end
