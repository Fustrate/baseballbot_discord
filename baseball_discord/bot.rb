# frozen_string_literal: true

require 'chronic'
require 'date'
require 'discordrb'
require 'em-hiredis'
require 'eventmachine'
require 'json'
require 'mlb_stats_api'
require 'open-uri'
require 'pg'
require 'redd'
require 'redis'
require 'securerandom'
require 'terminal-table'
require 'tzinfo'

require_relative 'command'
require_relative 'redis_connection'
require_relative 'utilities'

# Require all commands and events
Dir.glob(__dir__ + '/{commands,events}/*').sort.each do |path|
  require_relative path
end

module BaseballDiscord
  class Bot < Discordrb::Commands::CommandBot
    attr_reader :db, :mlb, :redis, :logger

    # ID of the user allowed to administrate the bot
    ADMIN_ID = 429_364_871_121_993_728

    NON_TEAM_CHANNELS = %w[
      general bot welcome verification discord-options
    ].freeze

    NON_TEAM_ROLES = [
      'mods', 'bot', 'verified', 'discord mods', 'team sub mods'
    ].freeze

    # Discord IDs of different servers. Duplicates are allowed.
    SERVERS = {
      'baseball' => 400_516_567_735_074_817,
      'test' => 450_792_745_553_100_801,
      'seattle' => 342_154_103_687_872_513
    }.freeze

    # The 'Verified' role on each of the above servers.
    VERIFIED_ROLES = {
      400_516_567_735_074_817 => 451_065_609_556_590_602, # baseball
      450_792_745_553_100_801 => 450_811_043_997_024_258, # test
      342_154_103_687_872_513 => 434_592_928_795_459_584
    }.freeze

    def initialize(attributes = {})
      @db = PG::Connection.new attributes.delete(:db)

      super attributes

      @logger = Logger.new($stdout)
      @redis = RedisConnection.new(self)

      @mlb = MLBStatsAPI::Client.new(logger: @logger, cache: Redis.new)

      load_commands
    end

    def load_commands
      include! BaseballDiscord::Commands::Debug
      include! BaseballDiscord::Commands::Invite
      include! BaseballDiscord::Commands::Scoreboard
      include! BaseballDiscord::Commands::Standings
      include! BaseballDiscord::Commands::TeamCalendar
      include! BaseballDiscord::Commands::Verify

      include! BaseballDiscord::Events::MemberJoin
    end
  end

  class UserError < RuntimeError
  end
end
