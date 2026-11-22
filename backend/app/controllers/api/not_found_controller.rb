module Api
  # Any /api path that matches no route: the same JSON 404 as a missing
  # record, rather than the React app or an HTML error page. There is no
  # endpoint here to protect, so it answers without a session.
  class NotFoundController < ApplicationController
    allow_unauthenticated_access

    def show
      render_errors "Not found", status: :not_found
    end
  end
end
