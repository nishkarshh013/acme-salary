# Demo data: 10,000 employees across 8 countries, with salary and assignment
# history. Deterministic: the same seed always produces the same data.
# Refuses to run on a database that already has data; to reset and reseed,
# run bin/rails db:seed:replant.
begin
  Seeds::Generator.new(count: 10_000).call
rescue Seeds::Generator::ExistingDataError => e
  abort e.message
end
