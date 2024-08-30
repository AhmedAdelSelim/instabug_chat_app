
require 'bunny'
require 'active_record'

class MessageWorker
  include ActiveSupport::Inflector

  def initialize
    @conn = Bunny.new(ENV['RABBITMQ_URL'] || 'amqp://guest:guest@localhost:5672/')
    @conn.start
    @channel = @conn.create_channel
    @queue = @channel.queue('chat_count_updates', durable: true)
  end

  def start
    @queue.subscribe(block: true) do |delivery_info, _properties, body|
      handle_message(body)
    end
  end

  private

  def handle_message(body)
    data = JSON.parse(body)
    application_id = data['application_id']

    update_chats_count(application_id)

    update_messages_count(application_id)
  end

  def update_chats_count(application_id)
    Application.find(application_id).update(
      chats_count: Chat.where(application_id: application_id).count
    )
  end

  def update_messages_count(application_id)
    chats = Chat.where(application_id: application_id)
    chats.each do |chat|
      chat.update(messages_count: Message.where(chat_id: chat.id).count)
    end
  end
end
