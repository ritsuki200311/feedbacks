class CreatePreferences < ActiveRecord::Migration[8.0]
  def change
    create_table :preferences do |t|
      t.references :user, null: false, foreign_key: true
      t.string :preference_type
      t.text :preference_value

      t.timestamps
    end
  end
end
