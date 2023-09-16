# frozen_string_literal: true

source 'https://rubygems.org'

ruby file: '.ruby-version'

# All of the bots have to be run as daemons so that their connection to discord persists
gem 'daemons', '~> 1.4'
gem 'rake', '~> 13.0'

# Use redis as our cache
gem 'redis', '~> 5.0'

# Reddit account tokens are stored in Postgres [https://github.com/ged/ruby-pg]
gem 'pg', '~> 1.4'

# Use an ORM instead of interacting with pg directly
gem 'sequel', '~> 5.71'

# Discord interaction
gem 'discordrb', github: 'shardlab/discordrb', branch: 'main'

# MLB Stats API
gem 'mlb_stats_api', '>= 0.2.5'

# Reddit interaction [https://github.com/Fustrate/redd]
gem 'redd', '>= 0.9.0.pre.3', github: 'Fustrate/redd'

# Parse dates and times
gem 'chronic', '~> 0.10'
gem 'tzinfo', '~> 2.0'

# Utilities
gem 'rufus-scheduler', '~> 3.9'
gem 'terminal-table', '~> 3.0'
gem 'terrapin', '~> 0.6'

# ERROR -- : cannot load such file -- concurrent/concurrent_ruby_ext (LoadError)
gem 'concurrent-ruby-ext', '~> 1.2'

group :development do
  # Deploy with Capistrano
  gem 'capistrano', '~> 3.17', require: false
  gem 'capistrano-bundler', '~> 2.1', require: false
  gem 'capistrano-rbenv', '~> 2.2', require: false

  gem 'minitest', '~> 5.19'

  # Linters
  gem 'rubocop', '~> 1.56'
  gem 'rubocop-minitest', '~> 0.31', require: false
  gem 'rubocop-performance', '~> 1.19', require: false
  gem 'rubocop-rake', '~> 0.6', require: false
  gem 'rubocop-sequel', '~> 0.3', require: false
end
