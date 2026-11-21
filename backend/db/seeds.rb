# Safe to run on any database:
# 1. Creates the HR Manager account if it is missing, from HR_EMAIL and
#    HR_PASSWORD (development falls back to demo credentials; see
#    Seeds::HrManager). Outside development, missing variables are an error.
# 2. Generates demo data (10,000 employees across 8 countries, with salary
#    and assignment history) unless the database already has data, in which
#    case it says so and skips. Deterministic: the same seed always produces
#    the same data. To reset and reseed, run bin/rails db:seed:replant.
begin
  Seeds::HrManager.call
rescue Seeds::HrManager::MissingCredentialsError => e
  abort e.message
end

Seeds::Generator.new(count: 10_000).call
