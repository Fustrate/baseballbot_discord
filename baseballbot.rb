# frozen_string_literal: true

require_relative 'baseballbot/bot'

@discord_bot = BaseballDiscord::Bot.new

trap('TERM') do
  @discord_bot.logger.debug '[TERM] Term signal received.'

  # No sync because we're in a trap context
  @discord_bot.stop(true)

  exit
end

# This will block the running process, so it should be executed last
@discord_bot.run
