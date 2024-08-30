class ApplicationsController < ApplicationController
    def create
      application = Application.create!(application_params)
      render json: application, status: :created
    end
  
    def update
      application = Application.find_by(token: params[:token])
      application.update!(application_params)
      render json: application
    end
  
    def show
      application = Application.find_by(token: params[:token])
      render json: application
    end
  
    private
  
    def application_params
      params.require(:application).permit(:name)
    end
  end
  