# frozen_string_literal: true

require 'daemons'

options = {
  log_output: true,
  backtrace: true,
  output_logfilename: '../log/modmail_bot_output.txt',
  logfilename: '../log/modmail_bot.log',
  dir: './tmp',
  dir_mode: :normal
}

Daemons.run 'modmail_bot.rb', options
