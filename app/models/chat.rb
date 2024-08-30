class Chat < ApplicationRecord
  belongs_to :application, counter_cache: true
  has_many :messages, dependent: :destroy

  validates :number, presence: true, uniqueness: { scope: :application_id }

  before_create :set_number
  after_create :enqueue_chat_count_job

private

  def enqueue_chat_count_job
    connection = Bunny.new
    connection.start
    channel = connection.create_channel
    queue = channel.queue('chat_count')
    queue.publish(self.application_id.to_s)
    connection.close
  end


  def set_number
    self.number = (self.application.chats.maximum(:number) || 0) + 1
  end

end
