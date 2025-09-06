class AddLengthLimitsToUsers < ActiveRecord::Migration[7.1]
  def change
    change_column :users, :email, :string, limit: 254, null: false, default: ""
    change_column :users, :encrypted_password, :string, limit: 255, null: false, default: ""
  end
end
