module Api
  class JobTitlesController < ApplicationController
    def index
      render json: { job_titles: JobTitle.order(:name).map { |job_title| LookupSerializer.call(job_title) } }
    end
  end
end
