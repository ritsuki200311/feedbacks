// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
import PostCardController from "controllers/post_card_controller"

eagerLoadControllersFrom("controllers", application)

// 手動でpost-cardコントローラーを登録
application.register("post-card", PostCardController)
