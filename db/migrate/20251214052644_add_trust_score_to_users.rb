class AddTrustScoreToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :trust_score, :decimal, precision: 3, scale: 2, default: 3.0, null: false
  end
end
