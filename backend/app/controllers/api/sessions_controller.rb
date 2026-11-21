module Api
  # Log in, log out, and report who is logged in.
  class SessionsController < ApplicationController
    INVALID_CREDENTIALS = "Invalid email address or password".freeze

    allow_unauthenticated_access only: :create
    rate_limit to: 10, within: 3.minutes, only: :create, with: lambda {
      render json: { error: "Too many login attempts. Try again in a few minutes." }, status: :too_many_requests
    }

    # GET /api/session
    def show
      render json: user_json(Current.user)
    end

    # POST /api/session
    def create
      user = authenticate
      if user
        start_new_session_for(user)
        render json: user_json(user), status: :created
      else
        # Same message whether the email or the password is wrong.
        render json: { error: INVALID_CREDENTIALS }, status: :unauthorized
      end
    end

    # DELETE /api/session
    def destroy
      terminate_session
      head :no_content
    end

    private

    def authenticate
      email_address = params[:email_address].to_s
      password = params[:password].to_s
      return if email_address.blank? || password.blank?

      User.authenticate_by(email_address: email_address, password: password)
    end

    def user_json(user)
      { user: { id: user.id, email_address: user.email_address } }
    end
  end
end
