class CreatePreferences < ActiveRecord::Migration[8.0]
  def change
    create_table :preferences do |t|
      t.references :user, null: false, foreign_key: true
      t.text :selected_items

      t.timestamps
    end
  end
end
