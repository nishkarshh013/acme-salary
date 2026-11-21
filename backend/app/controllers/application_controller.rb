class ApplicationController < ActionController::API
  include ActionController::Cookies
  include ErrorResponses
  # Order matters: the Origin check runs before authentication.
  include SameOriginRequests
  include Authentication

  # Read parameters from the top level of the JSON body, not wrapped under
  # the controller's name.
  wrap_parameters false

  rescue_from ActiveRecord::RecordNotFound do
    render_errors "Not found", status: :not_found
  end

  # Raised only in development and test (action_on_unpermitted_parameters
  # = :raise); production drops unknown parameters instead.
  rescue_from ActionController::UnpermittedParameters do |error|
    render_errors error.params.map { |name| "Unknown parameter: #{name}" }, status: :bad_request
  end
end
