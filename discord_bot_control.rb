# frozen_string_literal: true

require 'daemons'

Daemons.run('discord_bot.rb', log_output: true)
