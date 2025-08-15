class AddCommentToVotes < ActiveRecord::Migration[8.0]
  def change
    add_column :votes, :comment, :text
  end
end
