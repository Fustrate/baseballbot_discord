# frozen_string_literal: true

require 'daemons'

options = {
  log_output: true,
  backtrace: true,
  output_logfilename: '../log/modmail_bot_output.log',
  logfilename: '../log/modmail_bot.log',
  dir: '../tmp',
  dir_mode: :normal,
  app_name: 'BaseballModBot'
}

Daemons.run 'run.rb', options
