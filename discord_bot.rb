# frozen_string_literal: true

require 'chronic'
require 'date'
require 'discordrb'
require 'mlb_stats_api'
require 'open-uri'
require 'redd'
require 'securerandom'
require 'terminal-table'
require 'tzinfo'

require_relative 'baseball_discord/bot'
require_relative 'baseball_discord/command'
require_relative 'baseball_discord/commands/auth'
require_relative 'baseball_discord/commands/debug'
require_relative 'baseball_discord/commands/last_ten'
require_relative 'baseball_discord/commands/next_ten'
require_relative 'baseball_discord/commands/scoreboard'
require_relative 'baseball_discord/commands/standings'
require_relative 'baseball_discord/events/member_join'

discord_bot = BaseballDiscord::Bot.new(
  client_id: ENV['DISCORD_CLIENT_ID'],
  token: ENV['DISCORD_TOKEN'],
  prefix: '!'
)

discord_bot.include! BaseballDiscord::Commands::Auth
discord_bot.include! BaseballDiscord::Commands::Debug
discord_bot.include! BaseballDiscord::Commands::LastTen
discord_bot.include! BaseballDiscord::Commands::NextTen
discord_bot.include! BaseballDiscord::Commands::Scoreboard
discord_bot.include! BaseballDiscord::Commands::Standings

discord_bot.include! BaseballDiscord::Events::MemberJoin

discord_bot.run
