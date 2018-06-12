# frozen_string_literal: true

require_relative 'baseball_discord/bot'

@discord_bot = BaseballDiscord::Bot.new(
  client_id: ENV['DISCORD_CLIENT_ID'],
  token: ENV['DISCORD_TOKEN']
)

trap('TERM') do
  # No sync because we're in a trap context
  @discord_bot.stop(true)

  exit
end

# This will block the running process, so it should be executed last
@discord_bot.run
