# frozen_string_literal: true

source 'https://rubygems.org'

ruby '2.6.3'

# Run the script as a daemon
gem 'daemons'
gem 'rake'

# Local services
gem 'em-hiredis'
gem 'redis', git: 'https://github.com/redis/redis-rb.git'
# gem 'pg'

# Outside services
gem 'discordrb', git: 'https://github.com/meew0/discordrb.git'
gem 'mlb_stats_api', '>= 0.2.3'
gem 'redd'

# Parse dates and times
gem 'chronic'
gem 'tzinfo'

# Utilities
gem 'rufus-scheduler'
gem 'terminal-table'
gem 'terrapin'

group :development do
  gem 'minitest'
end
