# Frndr Architecture

## Overview

Frndr is built as a Discourse plugin that leverages Discourse's user fields system and extends it with a matching algorithm and discovery interface.

## Core Components

### 1. Matching Algorithm (`lib/frndr/matcher.rb`)

The heart of the system - calculates compatibility between users based on their profile answers.

**How it works:**
1. Fetches all user fields (profile questions) from Discourse
2. Compares answers between two users field by field
3. Counts matching answers (exact match required)
4. Returns compatibility as percentage: `(matching / total) * 100`

**Key methods:**
- `calculate_compatibility(user1, user2)` - Returns 0-100 compatibility score
- `find_matches_for(user, limit: 20)` - Returns array of matches sorted by compatibility

**Example:**
```ruby
user1.user_fields = { "1" => "3", "2" => "2", "3" => "3" }
user2.user_fields = { "1" => "3", "2" => "2", "3" => "1" }

Frndr::Matcher.calculate_compatibility(user1, user2)
# => 67 (2 out of 3 answers match)
```

**Current limitations:**
- Requires exact match (no fuzzy matching)
- All questions weighted equally
- Skips unanswered questions

**Future improvements:**
- Weighted questions (importance levels)
- Similarity scoring for numeric ranges
- Consider answer proximity (2 vs 3 is closer than 1 vs 3)

### 2. Discovery Controller (`app/controllers/frndr/discover_controller.rb`)

Rails controller that serves match data to the frontend.

**Endpoint:** `GET /frndr/discover`

**Authentication:** Requires login

**Response format:**
```json
{
  "matches": [
    {
      "id": 123,
      "username": "alice",
      "name": "Alice Smith",
      "avatar_template": "/user_avatar/...",
      "compatibility": 85
    }
  ]
}
```

**Process:**
1. Get current user from session
2. Call `Frndr::Matcher.find_matches_for(current_user)`
3. Serialize users with `BasicUserSerializer`
4. Add compatibility score to each user object
5. Return JSON

### 3. Frontend (Ember.js)

#### Route (`assets/javascripts/discourse/routes/discover.js`)

Standard Discourse route that fetches data:

```javascript
async model() {
  return ajax("/frndr/discover");
}
```

Returns promise that resolves to match data.

#### Template (`assets/javascripts/discourse/templates/discover.hbs`)

Handlebars template with card-based layout:

**Structure:**
- Container div (`.frndr-discover`)
- Grid of match cards (`.frndr-matches`)
- Each card shows:
  - Avatar (using Discourse `{{avatar}}` helper)
  - Username and name
  - Compatibility percentage
  - Link to profile

**Conditional rendering:**
- Shows matches if any exist
- Shows "no matches" message if empty

#### Styles (`assets/stylesheets/frndr.scss`)

CSS Grid layout with responsive design:

**Key features:**
- Auto-fill grid: `repeat(auto-fill, minmax(300px, 1fr))`
- Card hover effects (box shadow)
- Centered content (flexbox)
- Success color for compatibility score
- Uses Discourse CSS variables (`var(--primary-low)`, `var(--success)`)

## Data Flow

```
User visits /discover
    “
Ember Route loads
    “
AJAX GET /frndr/discover
    “
DiscoverController#index
    “
Frndr::Matcher.find_matches_for(current_user)
    “
  1. Query all activated users except current
  2. For each user: calculate_compatibility
  3. Filter out 0% matches
  4. Sort by compatibility (descending)
  5. Take top 20
    “
Serialize with BasicUserSerializer
    “
Add compatibility score to each
    “
Return JSON to frontend
    “
Template renders cards
```

## Database Schema

**No custom tables** - Uses Discourse's existing schema:

### User Fields (`user_fields` table)
Built-in Discourse table for custom profile questions:

```ruby
id: integer
name: string          # "How social are you?"
field_type: string    # "dropdown", "text", "confirm"
editable: boolean
description: text
required: boolean
show_on_profile: boolean
show_on_user_card: boolean
position: integer
```

### User Field Answers (stored in `user_custom_fields` table)

User answers stored as JSON in `users` table:

```ruby
user.user_fields
# => { "1" => "3", "2" => "2", "3" => "1" }
```

Key = user field ID, Value = answer

## Performance Considerations

### Current approach:
- Queries all activated users from database
- Calculates compatibility in Ruby (not SQL)
- Limits to 20 matches after sorting

### Scalability issues at >1000 users:
- O(n) database query for all users
- O(n) Ruby iterations to calculate compatibility
- O(n log n) sort operation

### Future optimizations:
- Cache compatibility scores between users
- Pre-calculate matches nightly (background job)
- Use PostgreSQL for similarity calculation (custom SQL function)
- Paginate results (infinite scroll)
- Add filters to reduce candidate pool (location, tags, etc.)

## Security

### Authentication:
- Controller uses `requires_login` - Discourse handles session
- No additional auth needed

### Authorization:
- Users can only see other activated, non-suspended users
- Discourse's `User.real.activated.not_suspended` scope

### Data privacy:
- Only exposes data already in `BasicUserSerializer`:
  - Username, name, avatar
  - No email addresses
  - No private user fields
- Compatibility score is calculated on-the-fly (not stored)

## Extension Points

### Adding filters:

```ruby
# In controller
def index
  matches = Frndr::Matcher.find_matches_for(
    current_user,
    limit: 20,
    filters: { tags: params[:tags] }  # New!
  )
end
```

### Adding weights:

```ruby
# In matcher
def self.calculate_compatibility(user1, user2, weights: {})
  user_fields.each do |field|
    weight = weights[field.id] || 1.0
    matching_fields += weight if answer1 == answer2
    total_fields += weight
  end
end
```

### Caching matches:

```ruby
# In matcher
def self.find_matches_for(user, limit: 20)
  Rails.cache.fetch("frndr:matches:#{user.id}", expires_in: 1.hour) do
    # calculation here
  end
end
```

## Testing Strategy

### Unit tests (RSpec):
```ruby
# spec/lib/frndr/matcher_spec.rb
describe Frndr::Matcher do
  it "calculates 100% compatibility for identical answers"
  it "calculates 0% compatibility for different answers"
  it "skips users with no answers"
  it "handles missing user fields"
end
```

### Controller tests:
```ruby
# spec/requests/frndr/discover_controller_spec.rb
describe "GET /frndr/discover" do
  it "requires login"
  it "returns matches as JSON"
  it "includes compatibility scores"
end
```

### Integration tests:
- Create users with known answers
- Visit /discover
- Verify expected matches appear
- Verify compatibility percentages

## Deployment

### Requirements:
- Discourse 2.7.0+
- Ruby 3.0+
- PostgreSQL (included with Discourse)

### Installation:
1. Symlink or clone to `plugins/` directory
2. Restart Discourse (rebuilds assets)
3. Plugin auto-loads via Rails engine

### Configuration:
- No database migrations (uses existing tables)
- No custom settings (yet)
- Works immediately after installation

## Monitoring

### Metrics to track:
- Average compatibility scores
- Distribution of match counts per user
- API response times for `/frndr/discover`
- User engagement (visits to discover page)

### Potential issues:
- Slow queries with large user base (>1000)
- High memory usage calculating all matches
- Cache stampede if adding caching

## Future Architecture

### Phase 2: Like/Pass System
- New tables: `frndr_likes`, `frndr_passes`
- Mutual matches (both users liked each other)
- Hide passed users from future results

### Phase 3: Real-time Matching
- Use ActionCable (WebSockets) for live updates
- Notify users when they get a new match
- Show "X people viewed your profile"

### Phase 4: Advanced Matching
- Machine learning for compatibility prediction
- Consider implicit signals (topic interactions, likes)
- Collaborative filtering (users similar to you liked...)

## Code Style

Follows Discourse conventions:
- Frozen string literals
- Namespaced under `::Frndr` module
- Rails engine for autoloading
- SCSS using Discourse variables
- Ember.js for frontend
- Handlebars templates
