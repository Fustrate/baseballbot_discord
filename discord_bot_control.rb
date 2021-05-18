# frozen_string_literal: true

require 'daemons'

options = {
  log_output: true,
  backtrace: true,
  output_logfilename: 'log/discord_bot_output.txt',
  logfilename: 'log/discord_bot.log',
  dir_mode: :system
}

Daemons.run 'discord_bot.rb', options
