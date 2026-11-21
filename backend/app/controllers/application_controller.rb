class ApplicationController < ActionController::API
  include ActionController::Cookies
  # Order matters: the Origin check runs before authentication.
  include SameOriginRequests
  include Authentication
end
