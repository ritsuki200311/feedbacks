// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
import PostCardController from "controllers/post_card_controller"
import CommentVoteController from "controllers/comment_vote_controller"

eagerLoadControllersFrom("controllers", application)

// 手動でコントローラーを登録
application.register("post-card", PostCardController)
application.register("comment-vote", CommentVoteController)

console.log('Stimulus application started and controllers registered!')
