# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/utils", under: "utils"
pin "d3", to: "https://cdn.skypack.dev/d3@7"
# pin "preferences_matter", to: "preferences_matter.js"
# pin "matter-js", to: "https://cdnjs.cloudflare.com/ajax/libs/matter-js/0.19.0/matter.min.js"
