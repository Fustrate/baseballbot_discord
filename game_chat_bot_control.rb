# frozen_string_literal: true

require 'daemons'

options = {
  log_output: true,
  backtrace: true,
  output_logfilename: 'log/game_chat_bot_output.txt',
  logfilename: 'log/game_chat_bot.log'
}

Daemons.run 'game_chat_bot.rb', options
