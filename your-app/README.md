# Your App

## Overview
This application allows users to register and set their preferences. After registration, users will be directed to a preferences page where they can input their preferences. Once preferences are saved, users will be redirected to the home screen.

## File Structure
- **app/controllers/preferences_controller.rb**: Contains the `PreferencesController` class for handling preferences logic.
- **app/models/preference.rb**: Defines the `Preference` model for managing preferences data.
- **app/views/preferences/new.html.erb**: HTML form for users to input their preferences during registration.
- **app/views/preferences/edit.html.erb**: HTML form for users to edit their existing preferences.
- **config/routes.rb**: Defines the routes for the application, including preferences routes.
- **db/migrate/[timestamp]_create_preferences.rb**: Migration file for creating the preferences table in the database.

## Setup Instructions
1. Clone the repository to your local machine.
2. Run `bundle install` to install the necessary gems.
3. Run `rails db:migrate` to set up the database.
4. Start the server with `rails server`.
5. Navigate to `http://localhost:3000` to access the application.

## Features
- User registration with preference input.
- Ability to edit preferences.
- Redirects to the home screen after setting preferences.

## Contributing
Feel free to submit issues or pull requests for any improvements or bug fixes.