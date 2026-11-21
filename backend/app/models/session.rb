# A logged-in browser. Sessions last LIFETIME from login, however active
# they are; after that the HR Manager logs in again.
class Session < ApplicationRecord
  LIFETIME = 12.hours

  belongs_to :user

  def expired?
    created_at <= LIFETIME.ago
  end
end
