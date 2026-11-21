module Employees
  # Search, filter, sort and paginate the employee list. Returns a
  # ServiceResult whose record is a Page; invalid parameters are a failure
  # with messages (the controller renders them as 422).
  class Search
    SORTABLE = %w[ employee_code last_name hire_date current_salary ].freeze
    DIRECTIONS = %w[ asc desc ].freeze
    STATUSES = %w[ active inactive all ].freeze
    FILTERS = %w[ country_id department_id job_title_id ].freeze
    DEFAULT_SORT = "last_name".freeze
    DEFAULT_PER_PAGE = 25
    MAX_PER_PAGE = 100

    Page = Data.define(:employees, :page, :per_page, :total_count) do
      def total_pages = (total_count + per_page - 1) / per_page
    end

    def self.call(params) = new(params).call

    # params: q, country_id, department_id, job_title_id, status, sort,
    # direction, page, per_page. All optional; values may be strings.
    def initialize(params)
      @params = params.to_h.with_indifferent_access
    end

    def call
      errors = validation_errors
      return ServiceResult.failure(errors) if errors.any?

      scope = filtered_scope
      employees = scope.includes(:country, :department, :job_title)
                       .order(sort => direction, id: :asc)
                       .offset((page - 1) * per_page)
                       .limit(per_page)
                       .to_a

      ServiceResult.success(Page.new(employees: employees, page: page, per_page: per_page, total_count: scope.count))
    end

    private

    attr_reader :params

    def filtered_scope
      scope = Employee.all
      scope = scope.where(status: status) unless status == "all"
      FILTERS.each { |filter| scope = scope.where(filter => integer_param(filter)) if params[filter].present? }
      scope = scope.where(search_condition, pattern: "%#{Employee.sanitize_sql_like(query)}%") if query.present?
      scope
    end

    # First and last name are covered by the full-name match.
    def search_condition
      <<~SQL.squish
        (employees.first_name || ' ' || employees.last_name) ILIKE :pattern
        OR employees.email ILIKE :pattern
        OR employees.employee_code ILIKE :pattern
      SQL
    end

    def validation_errors
      errors = FILTERS.filter_map do |filter|
        "#{filter} must be a positive integer" if params[filter].present? && integer_param(filter).nil?
      end
      errors << "status must be one of: #{STATUSES.join(', ')}" unless STATUSES.include?(status)
      errors << "sort must be one of: #{SORTABLE.join(', ')}" unless SORTABLE.include?(sort)
      errors << "direction must be asc or desc" unless DIRECTIONS.include?(direction)
      if sort == "current_salary" && params[:country_id].blank?
        errors << "Sorting by current salary needs a country filter, because salaries are in different currencies"
      end
      errors << "page must be a positive integer" if page.nil?
      errors << "per_page must be a positive integer" if per_page.nil?
      errors
    end

    def query = params[:q].to_s.squish
    def status = params[:status].presence || "active"
    def sort = params[:sort].presence || DEFAULT_SORT
    def direction = params[:direction].presence || "asc"
    def page = positive_integer(params[:page].presence || 1)

    def per_page
      value = positive_integer(params[:per_page].presence || DEFAULT_PER_PAGE)
      value && [ value, MAX_PER_PAGE ].min
    end

    def integer_param(name) = positive_integer(params[name])

    def positive_integer(value)
      number = Integer(value.to_s, 10, exception: false)
      number if number&.positive?
    end
  end
end
