# frozen_string_literal: true

source 'https://rubygems.org'

ruby '3.2.2'

# Run the script as a daemon
gem 'daemons', '~> 1.4'
gem 'rake', '~> 13.0'

# Local services
gem 'em-hiredis', '~> 0.3'
gem 'redis', '~> 4.6'
# gem 'pg'

# Outside services
gem 'discordrb', github: 'shardlab/discordrb', branch: 'main'

# MLB Stats API
gem 'mlb_stats_api', '>= 0.2.5'

# Reddit interaction [https://github.com/Fustrate/redd]
gem 'redd', '>= 0.9.0.pre.3', github: 'Fustrate/redd'

# Parse dates and times
gem 'chronic', '~> 0.10'
gem 'tzinfo', '~> 2.0'

# Utilities
gem 'rufus-scheduler', '~> 3.8'
gem 'terminal-table', '~> 3.0'
gem 'terrapin', '~> 0.6'

# ERROR -- : cannot load such file -- concurrent/concurrent_ruby_ext (LoadError)
gem 'concurrent-ruby-ext', '~> 1.1'

group :development do
  # Deploy with Capistrano
  gem 'capistrano', '~> 3.17', require: false
  gem 'capistrano-bundler', '~> 2.1', require: false
  gem 'capistrano-rbenv', '~> 2.1', require: false

  gem 'minitest', '~> 5.16'

  # Linters
  gem 'rubocop', '~> 1.30'
  gem 'rubocop-performance', '~> 1.14', require: false
end
