# Session-cookie authentication, adapted from `rails generate authentication`
# for a JSON API: every action requires a session unless the controller opts
# out with allow_unauthenticated_access, and a missing session is a 401
# rather than a redirect.
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private

  def require_authentication
    resume_session || request_authentication
  end

  def resume_session
    Current.session ||= find_session_by_cookie
  end

  # An expired session is deleted and treated as missing, even if the
  # browser still sends its cookie.
  def find_session_by_cookie
    session = Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
    return session unless session&.expired?

    session.destroy
    nil
  end

  def request_authentication
    render_errors "Not logged in", status: :unauthorized
  end

  def start_new_session_for(user)
    user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
      Current.session = session
      cookies.signed[:session_id] = {
        value: session.id, expires: Session::LIFETIME, httponly: true, same_site: :lax,
        secure: Rails.env.production?
      }
    end
  end

  def terminate_session
    Current.session.destroy
    cookies.delete(:session_id)
  end
end
