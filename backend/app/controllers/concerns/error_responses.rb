# The one shape for every API error response: { "errors": ["..."] }, an
# array of human-readable messages.
module ErrorResponses
  extend ActiveSupport::Concern

  private

  def render_errors(messages, status:)
    render json: { errors: Array(messages) }, status: status
  end
end
