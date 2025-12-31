namespace :delete_all_posts do
  desc "Delete all posts from the database"
  task execute: :environment do
    puts "Deleting all posts..."
    post_count = Post.count
    Post.destroy_all
    puts "Successfully deleted #{post_count} posts."
  end
end
