class Application < ApplicationRecord
    has_secure_token :token
    has_many :chats, dependent: :destroy
  
    validates :name, presence: true
    
    before_create :generate_token

    private
  
    def generate_token
      self.token = SecureRandom.hex(16)
    end

  end
  