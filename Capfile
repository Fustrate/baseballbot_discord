# frozen_string_literal: true

# Load DSL and set up stages
require 'capistrano/setup'

# Include default deployment tasks
require 'capistrano/deploy'

# Include tasks from other gems
require 'capistrano/rbenv'
require 'capistrano/bundler'
require 'capistrano/scm/git'
# require 'capistrano/honeybadger'

# Load custom tasks from `lib/capistrano/tasks` if you have any defined
Dir.glob('lib/capistrano/tasks/*.rake').each { import _1 }

install_plugin Capistrano::SCM::Git
