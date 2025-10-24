#!/usr/bin/env ruby
# frozen_string_literal: true

# Script to create test users with random profile answers for testing frndr matching
# Run from discourse root: cd ~/discourse/discourse && ruby plugins/discourse-frndr/scripts/create-test-users.rb

require_relative "../../../config/environment"

module Frndr
  class TestUserGenerator
    # First names for test users
    FIRST_NAMES = %w[
      Alice Bob Charlie Dana Eve Frank Grace Henry Iris Jack
      Kate Leo Maya Noah Olivia Paul Quinn Ruby Sam Tara
      Uma Victor Wanda Xavier Yara Zoe Amy Ben Clara David
    ]

    def self.random_user_fields
      user_field_ids = UserField.pluck(:id)
      return {} if user_field_ids.empty?

      # Generate random answers (1-3 scale)
      user_field_ids.each_with_object({}) do |field_id, hash|
        hash[field_id.to_s] = rand(1..3).to_s
      end
    end

    def self.generate
      puts "Creating test users..."
      puts "Note: Make sure you've created user fields first in Admin > Customize > User Fields"
      puts

      created_count = 0
      FIRST_NAMES.each do |name|
        username = name.downcase
        email = "#{username}@example.com"

        # Check if user already exists
        if User.exists?(username: username)
          puts "Skipping #{username} (already exists)"
          next
        end

        begin
          user =
            User.create!(
              username: username,
              name: name,
              email: email,
              password: "password123",
              approved: true,
              active: true,
              trust_level: 1,
            )

          # Set random user field answers
          user.user_fields = random_user_fields
          user.save!

          created_count += 1
          puts "Created #{username} (#{user.user_fields.inspect})"
        rescue StandardError => e
          puts "Failed to create #{username}: #{e.message}"
        end
      end

      puts
      puts "Created #{created_count} test users"
      puts
      puts "Next steps:"
      puts "1. Visit /discover as any user to see matches"
      puts "2. Test matching with: Frndr::Matcher.find_matches_for(User.find_by(username: 'alice'))"
    end
  end
end

Frndr::TestUserGenerator.generate
