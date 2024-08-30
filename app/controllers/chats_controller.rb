class ChatsController < ApplicationController
    def create
      application = Application.find_by(token: params[:application_token])
      chat = application.chats.create!
      render json: { number: chat.number }, status: :created
    end
  
    def index
      application = Application.find_by(token: params[:application_token])
      chats = application.chats
      render json: chats
    end
  end
  