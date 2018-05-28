# frozen_string_literal: true

require_relative 'baseball_discord/bot'
require_relative 'baseball_discord/command'
require_relative 'baseball_discord/utilities'

require_relative 'baseball_discord/commands/debug'
require_relative 'baseball_discord/commands/last_ten'
require_relative 'baseball_discord/commands/next_ten'
require_relative 'baseball_discord/commands/scoreboard'
require_relative 'baseball_discord/commands/standings'
require_relative 'baseball_discord/commands/verify'

require_relative 'baseball_discord/events/member_join'

@discord_bot = BaseballDiscord::Bot.new(
  client_id: ENV['DISCORD_CLIENT_ID'],
  token: ENV['DISCORD_TOKEN'],
  prefix: '!',
  db: {
    user: ENV['PG_USERNAME'],
    dbname: ENV['PG_DATABASE'],
    password: ENV['PG_PASSWORD']
  }
)

@discord_bot.include! BaseballDiscord::Commands::Debug
@discord_bot.include! BaseballDiscord::Commands::LastTen
@discord_bot.include! BaseballDiscord::Commands::NextTen
@discord_bot.include! BaseballDiscord::Commands::Scoreboard
@discord_bot.include! BaseballDiscord::Commands::Standings
@discord_bot.include! BaseballDiscord::Commands::Verify

@discord_bot.include! BaseballDiscord::Events::MemberJoin

# Trap before running
trap('TERM') do
  # No sync because we're in a trap context
  @discord_bot.stop(true)

  exit
end

@discord_bot.run
