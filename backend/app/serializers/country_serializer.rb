class CountrySerializer
  def self.call(country)
    { id: country.id, code: country.code, name: country.name, currency_code: country.currency_code }
  end
end
