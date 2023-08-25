# frozen_string_literal: true

require 'daemons'

options = {
  log_output: true,
  backtrace: true,
  output_logfilename: '../log/game_chat_bot_output.txt',
  logfilename: '../log/game_chat_bot.log',
  dir: '../tmp',
  dir_mode: :normal,
  app_name: 'GameThreadBot'
}

Daemons.run 'run.rb', options
