module Api
  class DepartmentsController < ApplicationController
    def index
      render json: { departments: Department.order(:name).map { |department| LookupSerializer.call(department) } }
    end
  end
end
