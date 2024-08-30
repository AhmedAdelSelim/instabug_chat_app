class MessagesController < ApplicationController
    def create
      chat = Chat.find_by(application_id: params[:application_token], number: params[:chat_number])
      message = chat.messages.create!(message_params)
      render json: { number: message.number }, status: :created
    end
  
    def index
      chat = Chat.find_by(application_id: params[:application_token], number: params[:chat_number])
      messages = chat.messages
      render json: messages
    end

    def search
        chat = Chat.find_by(application_id: params[:application_token], number: params[:chat_number])
        messages = chat.messages.search(params[:query]).records
        render json: messages
    end
      
  
    private
  
    def message_params
      params.require(:message).permit(:body)
    end
  end
  