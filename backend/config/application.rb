require_relative "boot"

require "rails"
require_relative "../lib/immutable_assets"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Backend
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # The business's time zone decides what "today" is: effective and hire
    # dates may not be later than Date.current in this zone, and
    # GET /api/session tells the frontend the same date. Any name from
    # `bin/rails time:zones:all`, e.g. "Asia/Kolkata". Timestamps are still
    # stored in UTC.
    config.time_zone = ENV.fetch("APP_TIME_ZONE", "UTC")
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # Session-cookie authentication (docs/architecture.md, decision 1). API
    # mode leaves out the cookie and session middleware, so add them back.
    config.middleware.use ActionDispatch::Cookies
    config.middleware.use ActionDispatch::Session::CookieStore,
                          key: "_acme_salary_session", httponly: true, same_site: :lax,
                          secure: Rails.env.production?

    # Extra origins allowed to send POST/PATCH/PUT/DELETE, besides the app's
    # own (see SameOriginRequests). Set per environment.
    config.x.allowed_origins = []

    # The React build's index.html (frontend/dist, which the Dockerfile copies
    # into public/). FrontendController serves it for the app's own paths.
    config.x.frontend_index = config.root.join("public", "index.html")
    # Hashed build files under /assets/ (the React build) are cached for a year.
    config.middleware.insert_before ActionDispatch::Static, ImmutableAssets
  end
end
