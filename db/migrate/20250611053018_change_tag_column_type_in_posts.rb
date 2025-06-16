class ChangeTagColumnTypeInPosts < ActiveRecord::Migration[8.0]
  def change
    change_column :posts, :tag, :text
  end
end
