#!/usr/bin/env ruby
# frozen_string_literal: true

# Script to create test users with random profile answers for testing frndr matching
# Run from discourse root: bin/rails runner plugins/discourse-frndr/scripts/create-test-users.rb

module Frndr
  class TestUserGenerator
    # First names for test users
    FIRST_NAMES = %w[
      Alice Bob Charlie Dana Eve Frank Grace Henry Iris Jack
      Kate Leo Maya Noah Olivia Paul Quinn Ruby Sam Tara
      Uma Victor Wanda Xavier Yara Zoe Amy Ben Clara David
    ]

    def self.set_random_user_fields(user)
      user_field_ids = UserField.pluck(:id)
      return if user_field_ids.empty?

      # Generate random answers (1-3 scale)
      user_field_ids.each do |field_id|
        user.custom_fields["user_field_#{field_id}"] = rand(1..3).to_s
      end
      user.save_custom_fields
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
        existing_user = User.find_by(username: username)
        if existing_user
          set_random_user_fields(existing_user)
          field_values = UserField.pluck(:id).map { |id| existing_user.custom_fields["user_field_#{id}"] }
          puts "Updated #{username} with fields: #{field_values.inspect}"
          next
        end

        begin
          user =
            User.create!(
              username: username,
              name: name,
              email: email,
              password: "TestPass123!@#",
              approved: true,
              active: true,
              trust_level: 1,
            )

          # Set random user field answers
          set_random_user_fields(user)

          created_count += 1
          field_values = UserField.pluck(:id).map { |id| user.custom_fields["user_field_#{id}"] }
          puts "Created #{username} (fields: #{field_values.inspect})"
        rescue StandardError => e
          puts "Failed to create #{username}: #{e.message}"
        end
      end

      puts
      puts "Created #{created_count} test users"
      puts "Password for all users: TestPass123!@#"
      puts
      puts "Next steps:"
      puts "1. Visit /discover as any user to see matches"
      puts "2. Test matching with: Frndr::Matcher.find_matches_for(User.find_by(username: 'alice'))"
    end
  end
end

Frndr::TestUserGenerator.generate
