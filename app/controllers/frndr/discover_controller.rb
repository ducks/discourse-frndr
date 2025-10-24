# frozen_string_literal: true

module Frndr
  class DiscoverController < ::ApplicationController
    requires_plugin Frndr::PLUGIN_NAME
    requires_login

    def index
      matches = Frndr::Matcher.find_matches_for(current_user, limit: 20)

      render json: {
        matches: serialize_data(
          matches.map { |m| m[:user] },
          BasicUserSerializer,
          root: false,
        ).each_with_index.map do |user_data, index|
          user_data[:compatibility] = matches[index][:compatibility]
          user_data
        end,
      }
    end
  end
end
