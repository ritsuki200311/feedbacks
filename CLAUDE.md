# CLAUDE.md
必ず日本語で回答してください。
This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Starting the Application
```bash
bin/rails server
# or with foreman for development
foreman start -f Procfile.dev
```

### Testing
```bash
# Run all tests
bin/rails test

# Run system tests with specific database user
export TEST_DATABASE_USERNAME=akimotoritsuki && bin/rails test:system

# Run specific test file
bin/rails test test/controllers/posts_controller_test.rb
```

### Database Operations
```bash
# Create and migrate database
bin/rails db:create db:migrate

# Seed database
bin/rails db:seed

# Reset database
bin/rails db:reset
```

### Code Quality
```bash
# Run RuboCop linting
bundle exec rubocop

# Run security analysis
bundle exec brakeman
```

### Asset Management
```bash
# Precompile assets
bin/rails assets:precompile

# Build Tailwind CSS
bin/rails tailwindcss:build
```

## Architecture Overview

This is a Rails 8.0.1 application with Ruby 3.4.2 that serves as a creative feedback platform with community features.

### Core Models and Relationships

**User System:**
- `User` - Main user model with Devise authentication
- `SupporterProfile` - Extended profile for supporters with JSONB attributes
- `Preference` - User preferences stored as JSONB
- Users have coins and rank_points systems

**Content System:**
- `Post` - Main content model supporting multiple creation types (illustrations, writing, music)
- Supports multiple file attachments: images, videos, audios with format validation
- Has tag system and belongs to communities
- `Comment` - Nested comments with x_position/y_position for image comments
- `Vote` - Polymorphic voting system

**Community System:**
- `Community` - Groups that users can join
- `CommunityUser` - Join table for community membership
- Posts can belong to communities

**Messaging System:**
- `Room` - Chat rooms between users
- `Entry` - User participation in rooms
- `Message` - Individual messages with read status

### Key Controllers
- `PostsController` - Handles content creation and display
- `CommentsController` - Manages comments including image positioning
- `CommunitiesController` - Community management with join/leave functionality
- `VotesController` - Voting functionality
- `Admin::UsersController` - Admin panel for user management

### Frontend Technologies
- **Stimulus** - JavaScript framework with controllers for:
  - `image_comments_controller.js` - Interactive image commenting with click positioning
  - `comment_modal_controller.js` - Modal dialogs
  - `form_controller.js` - Form enhancements
- **Turbo** - Hotwire's SPA-like navigation
- **Tailwind CSS** - Utility-first CSS framework
- **Importmaps** - JavaScript module management

### File Storage
- Active Storage with AWS S3 integration
- Support for images (JPEG, PNG, GIF, max 5MB)
- Support for videos (MP4, MOV, AVI, max 500MB)  
- Support for audio files (MP3, WAV, OGG, max 100MB)

### Database
- PostgreSQL in production
- Uses JSONB for flexible data storage (preferences, supporter profiles)

### Special Features
- **Image Comments**: Click-to-comment functionality on images with coordinate positioning
- **Coin System**: Users earn/spend coins for various activities
- **Ranking System**: A/B/C ranking based on rank_points
- **Multiple Creation Types**: Support for illustrations, writing, and music content
- **Real-time Messaging**: DM system between users

### Development Notes
- The app is currently working on image commenting functionality (branch: 画像上にコメント)
- Uses Japanese for UI text and comments
- Active Job configured with async adapter
- Letter Opener Web for email testing in development