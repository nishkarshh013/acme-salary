# The app configured with APP_TIME_ZONE=Asia/Kolkata, at 00:30 on 15 June
# 2026 in India, which is still 14 June in UTC. Sets the default zone the way
# config.time_zone does, so requests and services see it too.
RSpec.shared_context "Asia/Kolkata at 00:30 IST" do
  around do |example|
    original_zone = Time.zone_default
    Time.zone_default = Time.find_zone!("Asia/Kolkata")
    Time.use_zone(Time.zone_default) do
      travel_to(Time.utc(2026, 6, 14, 19, 0)) { example.run }
    end
  ensure
    Time.zone_default = original_zone
  end

  let(:ist_today) { Date.new(2026, 6, 15) }
end
