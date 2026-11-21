module Api
  class CountriesController < ApplicationController
    def index
      render json: { countries: Country.order(:name).map { |country| CountrySerializer.call(country) } }
    end
  end
end
