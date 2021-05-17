# frozen_string_literal: true

source 'https://rubygems.org'

ruby '3.0.1'

# Run the script as a daemon
gem 'daemons'
gem 'rake'

# Local services
gem 'em-hiredis'
gem 'redis'
# gem 'pg'

# Outside services
gem 'discordrb', github: 'shardlab/discordrb', branch: 'main'
gem 'mlb_stats_api', '>= 0.2.3'
gem 'redd'

# Parse dates and times
gem 'chronic'
gem 'tzinfo'

# Utilities
gem 'rufus-scheduler'
gem 'terminal-table'
gem 'terrapin'

# ERROR -- : cannot load such file -- concurrent/concurrent_ruby_ext (LoadError)
gem 'concurrent-ruby-ext'

group :development do
  # Deploy with Capistrano
  gem 'capistrano', '~> 3.15', require: false
  gem 'capistrano-bundler', require: false
  gem 'capistrano-rbenv', '~> 2.1', require: false

  gem 'minitest'

  # Linters
  gem 'rubocop'
  gem 'rubocop-performance', require: false
end
