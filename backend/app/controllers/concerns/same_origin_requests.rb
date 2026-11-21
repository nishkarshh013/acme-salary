# CSRF protection for the session cookie. Browsers send an Origin header on
# cross-site POST, PATCH, PUT and DELETE requests; reject those whose Origin
# is not the app's own (or an allowed dev origin). Requests without an
# Origin header (curl, same-origin requests from some browsers) pass, and
# still need a valid session. SameSite=Lax on the cookie is the second layer.
module SameOriginRequests
  extend ActiveSupport::Concern

  UNSAFE_METHODS = %w[ POST PATCH PUT DELETE ].freeze

  included do
    before_action :reject_cross_origin_request
  end

  private

  def reject_cross_origin_request
    return unless UNSAFE_METHODS.include?(request.method)

    origin = request.headers["Origin"]
    return if origin.nil? || allowed_origins.include?(origin)

    render json: { error: "Cross-origin request rejected" }, status: :forbidden
  end

  def allowed_origins
    [ request.base_url, *Rails.configuration.x.allowed_origins ]
  end
end
