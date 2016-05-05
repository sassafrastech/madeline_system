source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 4.2.5'
gem 'pg', '~> 0.15'

# Assets
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.1.0'
gem 'therubyracer', platforms: :ruby
gem 'jquery-rails'
gem 'font-awesome-rails'
gem 'bootstrap-sass'
gem 'momentjs-rails'
gem 'fullcalendar-rails'
gem 'twitter-bootstrap-rails-confirm'
gem 'select2-rails'
gem 'rails-backbone'
gem 'uri-js-rails' # URI manipulation

# Authentication / Authorization
gem 'devise'
gem 'pundit'
gem 'rolify'

# Pagination
# gem 'will_paginate', '~> 3.0.4'
# gem 'will_paginate-bootstrap'

# Remove UTF8 parameter from GET forms
gem 'utf8_enforcer_workaround'

# Slim template language
gem 'slim'

# Cron jobs
gem 'whenever', require: false

# note, for now just using chronic, which was already included
# if the duplicate step recurrence feature requirements become more complex in the future, then will likely make sense to use ice_cube
#gem 'ice_cube'
# beware, I tried 'tickle' first but it didn't seem stable

# Internationalization
gem 'rails-i18n'

# Translate urls
gem 'route_translator'

# Model hierarchical data
gem 'closure_tree'

# File attachments
gem 'carrierwave'
gem 'mini_magick'

# needed for migration of legacy data
gem 'mysql2'

# Tables
gem 'wice_grid', '3.6.0.pre4'
gem 'font-awesome-sass', '~> 4.3'
gem 'jquery-ui-rails'

# Forms
gem 'simple_form'

# Passing controller data to JS
gem 'gon'

# JE Todo: Confirm if there are any potential conflicts between gon and active_model_serializers
gem 'active_model_serializers'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'

  # Watches for inefficient queries and recommends eager loading
  gem 'bullet'

  # Report number of queries in server log
  gem 'sql_queries_count'

  # Annotate models & factories
  gem 'annotate'

  # Better console printing
  gem 'awesome_print'

  # Specs and Test Coverage
  gem 'rspec-rails'
  gem 'pundit-matchers'
  gem 'factory_girl_rails'
  gem 'database_cleaner'
  gem 'faker'
  gem 'capybara'
  gem 'simplecov'
  gem 'quiet_assets'
end

group :development do
  # Improve error screens
  gem 'better_errors'
  gem 'binding_of_caller'

  # Fix db schema conflicts
  gem 'fix-db-schema-conflicts'

  # Deployment
  gem 'capistrano',  '~> 3.1'
  gem 'capistrano-rails', '~> 1.1'
  gem 'capistrano-passenger'
end

group :development, :doc do
  gem 'rails-erd'
end
