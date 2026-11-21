require "rails_helper"

RSpec.describe "API session", type: :request do
  let!(:user) { create(:user, email_address: "hr@acme.test", password: "correct-horse-battery") }

  # Request specs run against http://www.example.com.
  let(:own_origin) { "http://www.example.com" }

  def log_in(email_address: "hr@acme.test", password: "correct-horse-battery", headers: {})
    post "/api/session", params: { email_address: email_address, password: password }, as: :json, headers: headers
  end

  def session_cookie_header
    Array(response.headers["Set-Cookie"]).join("\n").lines.find { |line| line.start_with?("session_id=") }
  end

  describe "POST /api/session" do
    it "logs in with the right credentials and sets a signed, httpOnly, SameSite=Lax cookie" do
      expect { log_in }.to change(Session, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to eq("user" => { "id" => user.id, "email_address" => "hr@acme.test" })
      expect(session_cookie_header).to match(/httponly/i).and match(/samesite=lax/i)
      expect(cookies[:session_id]).not_to eq(Session.last.id.to_s) # signed, not the raw id
    end

    it "keeps the user logged in on the next request" do
      log_in
      get "/api/session"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("user", "email_address")).to eq("hr@acme.test")
    end

    it "rejects a wrong password with a generic message and no session" do
      expect { log_in(password: "wrong-password") }.not_to change(Session, :count)

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq("errors" => [ "Invalid email address or password" ])
      expect(session_cookie_header).to be_nil
    end

    it "gives an unknown email the same message as a wrong password" do
      log_in(email_address: "nobody@acme.test")

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq("errors" => [ "Invalid email address or password" ])
    end

    it "rejects a missing password without an error" do
      post "/api/session", params: { email_address: "hr@acme.test" }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  it_behaves_like "requires authentication", :get, "/api/session"
  it_behaves_like "requires authentication", :delete, "/api/session"

  describe "GET /api/session" do
    it "returns 401 without a session" do
      get "/api/session"

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq("errors" => [ "Not logged in" ])
    end

    it "returns 401 for a cookie that isn't signed by the app" do
      session = user.sessions.create!(ip_address: "127.0.0.1", user_agent: "RSpec")
      cookies[:session_id] = session.id.to_s

      get "/api/session"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "session expiry" do
    let(:login_time) { Time.zone.local(2026, 6, 15, 9) }

    before { travel_to(login_time) }

    it "sets the cookie to expire 12 hours after login" do
      log_in

      expires = session_cookie_header[/expires=([^;]+)/i, 1]
      expect(Time.httpdate(expires)).to eq(login_time + 12.hours)
    end

    it "keeps the session just under 12 hours after login" do
      log_in
      travel_to(login_time + 12.hours - 1.minute)

      get "/api/session"

      expect(response).to have_http_status(:ok)
    end

    # The browser drops the cookie at 12 hours, and the signed value carries
    # its own expiry, so a copied cookie replayed later is rejected too.
    it "rejects the login cookie replayed after 12 hours" do
      log_in
      copied_cookie = cookies[:session_id]
      travel_to(login_time + 12.hours + 1.second)
      cookies[:session_id] = copied_cookie

      get "/api/session"

      expect(response).to have_http_status(:unauthorized)
    end

    # Server-side check, for a validly signed cookie with no expiry of its
    # own, such as one issued as permanent before sessions expired.
    it "treats a session older than 12 hours as missing and deletes it" do
      session = user.sessions.create!(ip_address: "127.0.0.1", user_agent: "RSpec")
      travel_to(login_time + 12.hours + 1.second)
      cookies[:session_id] = signed_cookie_without_expiry(session.id)

      expect { get "/api/session" }.to change(Session, :count).by(-1)
      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body).to eq("errors" => [ "Not logged in" ])
    end

    it "accepts that same kind of cookie for a session under 12 hours old" do
      session = user.sessions.create!(ip_address: "127.0.0.1", user_agent: "RSpec")
      travel_to(login_time + 11.hours)
      cookies[:session_id] = signed_cookie_without_expiry(session.id)

      get "/api/session"

      expect(response).to have_http_status(:ok)
    end

    def signed_cookie_without_expiry(session_id)
      jar = ActionDispatch::Request.new(Rails.application.env_config.deep_dup).cookie_jar
      jar.signed[:session_id] = session_id
      jar[:session_id]
    end
  end

  describe "DELETE /api/session" do
    it "logs out: the session is deleted and the cookie no longer works" do
      log_in

      expect { delete "/api/session" }.to change(Session, :count).by(-1)
      expect(response).to have_http_status(:no_content)

      get "/api/session"
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 when not logged in" do
      delete "/api/session"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "Origin check" do
    it "rejects a login from a foreign origin" do
      expect { log_in(headers: { "Origin" => "https://evil.example" }) }.not_to change(Session, :count)

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body).to eq("errors" => [ "Cross-origin request rejected" ])
    end

    it "rejects a logout from a foreign origin and keeps the session" do
      log_in

      expect { delete "/api/session", headers: { "Origin" => "https://evil.example" } }
        .not_to change(Session, :count)
      expect(response).to have_http_status(:forbidden)

      get "/api/session"
      expect(response).to have_http_status(:ok)
    end

    it "rejects the opaque origin 'null'" do
      log_in(headers: { "Origin" => "null" })

      expect(response).to have_http_status(:forbidden)
    end

    it "allows the app's own origin" do
      log_in(headers: { "Origin" => own_origin })

      expect(response).to have_http_status(:created)
    end

    it "allows a request with no Origin header" do
      log_in

      expect(response).to have_http_status(:created)
    end

    context "with an extra allowed origin, like the Vite dev server in development" do
      around do |example|
        original = Rails.configuration.x.allowed_origins
        Rails.configuration.x.allowed_origins = [ "http://localhost:5173" ]
        example.run
      ensure
        Rails.configuration.x.allowed_origins = original
      end

      it "allows it" do
        log_in(headers: { "Origin" => "http://localhost:5173" })

        expect(response).to have_http_status(:created)
      end
    end
  end

  describe "rate limit" do
    it "blocks login after 10 attempts in 3 minutes, even with the right password" do
      10.times { log_in(password: "wrong-password") }
      expect(response).to have_http_status(:unauthorized)

      expect { log_in }.not_to change(Session, :count)
      expect(response).to have_http_status(:too_many_requests)
      expect(response.parsed_body).to eq("errors" => [ "Too many login attempts. Try again in a few minutes." ])
    end

    it "allows logging in again once the window has passed" do
      10.times { log_in(password: "wrong-password") }

      travel 3.minutes + 1.second do
        log_in
        expect(response).to have_http_status(:created)
      end
    end
  end
end
