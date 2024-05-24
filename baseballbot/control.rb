# frozen_string_literal: true

require 'daemons'

options = {
  log_output: true,
  backtrace: true,
  output_logfilename: '../log/baseballbot_output.log',
  logfilename: '../log/baseballbot.log',
  dir: '../tmp',
  dir_mode: :normal,
  app_name: 'BaseballBot'
}

Daemons.run 'run.rb', options
