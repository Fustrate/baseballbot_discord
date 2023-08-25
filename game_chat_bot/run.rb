# frozen_string_literal: true

require_relative 'bot'

@bot = GameChatBot::Bot.new

trap('TERM') do
  @bot.logger.debug '[TERM] Term signal received.'

  # No sync because we're in a trap context
  @bot.stop(true)

  exit
end

# This will block the running process, so it should be executed last
@bot.run
