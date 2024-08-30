require 'bunny'
require 'active_record'

class ChatWorker
    def initialize
      @connection = Bunny.new
      @connection.start
      @channel = @connection.create_channel
      @queue = @channel.queue('chat_count')
    end
  
    def perform(application_id)
      application = Application.find(application_id)
      application.update(chats_count: application.chats.count)
    end
  
    def work
      @queue.subscribe(block: true) do |delivery_info, _properties, body|
        application_id = body.to_i
        perform(application_id)
      end
    end
  
    def self.run
      worker = new
      worker.work
    end
  end
  
  ChatWorker.run
  