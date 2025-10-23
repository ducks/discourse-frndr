# frozen_string_literal: true

module Frndr
  class Matcher
    def self.calculate_compatibility(user1, user2)
      # Get all user fields (profile questions)
      user_fields = UserField.all
      return 0 if user_fields.empty?

      total_fields = 0
      matching_fields = 0

      user_fields.each do |field|
        # Get answers for both users
        answer1 = user1.user_fields[field.id.to_s]
        answer2 = user2.user_fields[field.id.to_s]

        # Skip if either user hasn't answered this field
        next if answer1.blank? || answer2.blank?

        total_fields += 1

        # Check if answers match exactly
        matching_fields += 1 if answer1 == answer2
      end

      # Return compatibility as percentage (0-100)
      return 0 if total_fields.zero?
      (matching_fields.to_f / total_fields * 100).round
    end

    def self.find_matches_for(user, limit: 20)
      # Get all users except current user
      potential_matches = User.real
        .activated
        .not_suspended
        .where.not(id: user.id)
        .limit(limit * 2) # Get more than needed to filter

      # Calculate compatibility for each user
      matches = potential_matches.map do |potential_match|
        compatibility = calculate_compatibility(user, potential_match)
        next if compatibility.zero?

        {
          user: potential_match,
          compatibility: compatibility,
        }
      end.compact

      # Sort by compatibility (highest first) and limit
      matches.sort_by { |m| -m[:compatibility] }.first(limit)
    end
  end
end
