# frozen_string_literal: true

source 'https://rubygems.org'

ruby '2.7.2'

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
  gem 'minitest'
end
