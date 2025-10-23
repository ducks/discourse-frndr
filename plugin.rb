# frozen_string_literal: true

# name: discourse-frndr
# about: Friend finding app - match people based on interests and compatibility
# version: 20251023
# authors: ducks
# url: https://github.com/ducks/discourse-frndr
# required_version: 2.7.0

enabled_site_setting :frndr_enabled

module ::Frndr
  PLUGIN_NAME = "discourse-frndr"
end

require_relative "lib/frndr/engine"
require_relative "lib/frndr/matcher"

after_initialize do
  # Add route for discover page
  Discourse::Application.routes.append do
    namespace :frndr do
      get "/discover" => "discover#index"
    end
  end
end
