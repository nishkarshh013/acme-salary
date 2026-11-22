# Rack middleware for the React build's files under /assets/. Vite puts a
# content hash in each name (index-C2Y4hXW8.js), so a file never changes
# once published and browsers may cache it for a year without asking again.
# Every other public file keeps public_file_server.headers (no-cache).
class ImmutableAssets
  PREFIX = "/assets/".freeze
  CACHE_CONTROL = "public, max-age=31536000, immutable".freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)
    headers["cache-control"] = CACHE_CONTROL if status == 200 && env["PATH_INFO"].start_with?(PREFIX)
    [ status, headers, body ]
  end
end
