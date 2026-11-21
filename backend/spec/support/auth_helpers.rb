module AuthHelpers
  # Logs in through the real endpoint, so the request spec's cookie jar
  # holds a genuine signed session cookie.
  def sign_in(user = create(:user))
    post "/api/session", params: { email_address: user.email_address, password: user.password }, as: :json
    raise "sign_in failed with #{response.status}" unless response.status == 201

    user
  end
end

RSpec.configure { |config| config.include AuthHelpers, type: :request }
