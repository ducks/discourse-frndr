# discourse-frndr

Friend finding app built on Discourse - match people based on interests and compatibility.

## Overview

Frndr transforms Discourse into a friend-finding platform. Users fill out profile questions, tag their intro topics with activities, and discover compatible friends through a matching algorithm.

## Features

- **Compatibility Matching**: Algorithm compares user profile answers to calculate compatibility percentage
- **Discovery Page**: Card-based UI showing potential matches with compatibility scores
- **Activity Tags**: Users tag intro topics with activities (hiking, board games, etc.)
- **Profile Questions**: Uses Discourse's built-in user fields for profile data

## Installation

1. Clone this repository to your Discourse plugins directory:
   ```bash
   cd ~/discourse/discourse/plugins
   git clone https://github.com/ducks/discourse-frndr.git
   ```

2. Or symlink during development:
   ```bash
   ln -s ~/dev/discourse-frndr ~/discourse/discourse/plugins/discourse-frndr
   ```

3. Restart Discourse:
   ```bash
   cd ~/discourse/discourse
   bin/rails restart
   ```

4. Enable the plugin in Admin > Settings > Plugins

## Configuration

### User Fields (Profile Questions)

Create user fields in Admin > Customize > User Fields:

1. Go to Admin > Customize > User Fields
2. Add fields with options like:
   - "How social are you?" (1-3 scale: 1=Introvert, 2=Balanced, 3=Extrovert)
   - "Preferred activity time?" (1=Mornings, 2=Afternoons, 3=Evenings)
   - "Activity level?" (1=Low, 2=Moderate, 3=High)

### Activity Tags

Create tags for activities in Admin > Tags:
- `hiking`
- `board-games`
- `cooking`
- `music`
- etc.

### Intro Topics Category

Create a dedicated category for intro topics:
1. Admin > Categories > New Category
2. Name: "Introductions" or "Find Friends"
3. Restrict to one topic per user (configure in category settings)

## Usage

### For Users

1. Fill out profile questions in user preferences
2. Create an intro topic in the Introductions category
3. Tag it with your activities
4. Visit `/discover` to see compatible matches

### Discovery Page

Access at: `https://your-forum.com/discover`

The page shows:
- Avatar and username of potential matches
- Compatibility percentage
- Link to view their full profile

## Testing

### Generate Test Users

Run the included script to create fake users with profile data:

```bash
cd ~/dev/discourse-frndr
./scripts/create-test-users.sh
```

This creates 20 users with random profile answers for testing the matching algorithm.

### Manual Testing

```bash
cd ~/discourse/discourse
bin/rails console
```

Then:
```ruby
# Create test users
user1 = User.create!(username: "alice", email: "alice@example.com", password: "password123")
user2 = User.create!(username: "bob", email: "bob@example.com", password: "password123")

# Set user field answers (assuming field IDs 1, 2, 3 exist)
user1.user_fields = { "1" => "3", "2" => "2", "3" => "3" }
user2.user_fields = { "1" => "3", "2" => "2", "3" => "1" }
user1.save!
user2.save!

# Test matching
Frndr::Matcher.calculate_compatibility(user1, user2)
# => Returns percentage (0-100)
```

## Architecture

See [ARCHITECTURE.md](./ARCHITECTURE.md) for detailed technical documentation.

## Development

### Project Structure

```
discourse-frndr/
├── plugin.rb                 # Main plugin file
├── lib/
│   └── frndr/
│       ├── engine.rb         # Rails engine
│       └── matcher.rb        # Matching algorithm
├── app/
│   └── controllers/
│       └── frndr/
│           └── discover_controller.rb
├── assets/
│   ├── javascripts/discourse/
│   │   ├── routes/
│   │   │   └── discover.js
│   │   └── templates/
│   │       └── discover.hbs
│   └── stylesheets/
│       └── frndr.scss
└── scripts/
    └── create-test-users.sh
```

### Running Tests

```bash
cd ~/discourse/discourse
bin/rake plugin:spec[discourse-frndr]
```

## Roadmap

- [ ] One intro topic per user validation
- [ ] Filter matches by activity tags
- [ ] Location-based matching
- [ ] Weighted questions (importance levels)
- [ ] "Pass" and "Like" actions
- [ ] Direct messaging integration
- [ ] Activity-based notifications

## License

MIT
