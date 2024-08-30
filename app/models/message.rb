class Message < ApplicationRecord

  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks


  belongs_to :chat, counter_cache: true

  validates :number, presence: true, uniqueness: { scope: :chat_id }
  validates :body, presence: true

  before_create :set_number

  def as_indexed_json(options = {})
    self.as_json(only: [:body])
  end

  private

  def set_number
    self.number = (self.chat.messages.maximum(:number) || 0) + 1
  end

end


Message.import(force: true)