# frozen_string_literal: true

require 'daemons'

Daemons.run('game_chat_bot.rb', log_output: true)
