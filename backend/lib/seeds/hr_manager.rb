module Seeds
  # Seeds the single HR Manager account from HR_EMAIL and HR_PASSWORD.
  # Development falls back to demo credentials so a fresh checkout works;
  # every other environment requires both variables, so no real credentials
  # are ever committed. An existing account is left unchanged.
  class HrManager
    class MissingCredentialsError < StandardError; end

    DEMO_EMAIL = "hr@acme.example".freeze
    DEMO_PASSWORD = "demo-password-dev-only".freeze

    def self.call(...) = new(...).call

    def initialize(env: ENV, rails_env: Rails.env, out: $stdout)
      @env = env
      @rails_env = rails_env
      @out = out
    end

    def call
      email, password = credentials
      existing = User.find_by(email_address: email)
      if existing
        out.puts "HR manager account already exists; left unchanged"
        return existing
      end

      User.create!(email_address: email, password: password).tap do
        out.puts "Created the HR manager account#{' (development demo credentials)' if using_demo?}"
      end
    end

    private

    attr_reader :env, :rails_env, :out

    def credentials
      email = env["HR_EMAIL"].presence || (DEMO_EMAIL if rails_env.development?)
      password = env["HR_PASSWORD"].presence || (DEMO_PASSWORD if rails_env.development?)
      return [ email, password ] if email && password

      raise MissingCredentialsError, "Set HR_EMAIL and HR_PASSWORD to seed the HR manager account."
    end

    def using_demo?
      env["HR_EMAIL"].blank? || env["HR_PASSWORD"].blank?
    end
  end
end
