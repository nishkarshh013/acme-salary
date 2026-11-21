class ApplicationController < ActionController::API
  include ActionController::Cookies
  include ErrorResponses
  # Order matters: the Origin check runs before authentication.
  include SameOriginRequests
  include Authentication

  rescue_from ActiveRecord::RecordNotFound do
    render_errors "Not found", status: :not_found
  end
end
