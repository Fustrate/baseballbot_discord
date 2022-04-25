# frozen_string_literal: true

lock '~> 3.15'

set :application, 'discord_bot'
set :user, 'baseballbot'
set :deploy_to, "/home/#{fetch :user}/apps/#{fetch :application}"

set :repo_url, 'git@github.com:Fustrate/baseballbot_discord.git'
set :branch, ENV('REVISION', :master)

append :linked_dirs, 'log', 'tmp'
append :linked_files, 'config/servers.yml'

set :default_env, { path: '/opt/ruby/bin:$PATH' }

set :rbenv_ruby, File.read(File.expand_path('../.ruby-version', __dir__)).strip
set :rbenv_prefix, "RBENV_ROOT=#{fetch :rbenv_path} #{fetch :rbenv_path}/bin/rbenv exec"
set :rbenv_map_bins, %w[bundle gem honeybadger rake ruby]

namespace :deploy do
  after :finished, 'game_chat_bot:restart', 'discord_bot:restart'
  after :finishing, :cleanup
end
