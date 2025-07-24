class CreateCommunities < ActiveRecord::Migration[8.0]
  def change
    create_table :communities do |t|
      t.string :name
      t.text :description
      t.boolean :is_public
      t.string :tags

      t.timestamps
    end
  end
end
