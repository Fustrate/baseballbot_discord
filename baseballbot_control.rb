# frozen_string_literal: true

require 'daemons'

options = {
  log_output: true,
  backtrace: true,
  output_logfilename: '../log/baseballbot_output.txt',
  logfilename: '../log/baseballbot.log',
  dir: './tmp',
  dir_mode: :normal
}

Daemons.run 'baseballbot.rb', options
