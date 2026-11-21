# The one shape for every API error response: { "errors": ["..."] }, an
# array of human-readable messages.
module ErrorResponses
  extend ActiveSupport::Concern

  private

  def render_errors(messages, status:)
    render json: { errors: Array(messages) }, status: status
  end

  # 409 when the caller's lock_version is out of date, 422 otherwise.
  def render_failure(result)
    render_errors result.errors, status: result.stale? ? :conflict : :unprocessable_content
  end
end
