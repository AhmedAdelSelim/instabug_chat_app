class CreateMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :messages do |t|
      t.references :chat, null: false, foreign_key: true
      t.integer :number
      t.text :body

      t.timestamps
    end
    add_index :messages, :number, unique: true
  end
end
