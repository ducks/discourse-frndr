# frozen_string_literal: true

Frndr::Engine.routes.draw do
  # Routes are defined in plugin.rb after_initialize block
end

Discourse::Application.routes.draw { mount ::Frndr::Engine, at: "frndr" }
