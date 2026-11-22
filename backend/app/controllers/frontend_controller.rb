# Serves the React app's index.html (the frontend build, which the
# Dockerfile copies into public/) for any GET outside /api that isn't a
# real file (real files are served earlier, by ActionDispatch::Static), so
# a link like /employees/123 works on reload: React Router takes it from
# there. The page itself holds no data; every API call still needs a session.
#
# index.html is never cached, so a new deploy's asset names are picked up at
# once. The hashed files it points to are cached for a year (ImmutableAssets).
class FrontendController < ActionController::API
  def index
    index_html = Rails.configuration.x.frontend_index
    return head :not_found unless index_html.file?

    response.headers["Cache-Control"] = "no-cache"
    send_file index_html, type: "text/html; charset=utf-8", disposition: "inline"
  end
end
