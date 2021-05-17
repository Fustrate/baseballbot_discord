# frozen_string_literal: true

require_relative 'game_chat_bot/bot'

@bot = GameChatBot::Bot.new

trap('TERM') do
  # No sync because we're in a trap context
  @bot.stop(true)

  exit
end

# This will block the running process, so it should be executed last
@bot.run
