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
require 'yaml'

require_relative 'command'
require_relative 'config'
require_relative 'redis_connection'
require_relative 'utilities'

# Require all commands and events
Dir.glob(__dir__ + '/{commands,events}/*').sort.each do |path|
  require_relative path
end

module BaseballDiscord
  class Bot < Discordrb::Commands::CommandBot
    attr_reader :db, :mlb, :redis, :logger, :config

    # ID of the user allowed to administrate the bot
    ADMIN_ID = 429_364_871_121_993_728

    def initialize(attributes = {})
      @db = PG::Connection.new attributes.delete(:db)

      @config = Config.new

      super attributes.merge(prefix: prefix_proc(@config.server_prefixes))

      @logger = Logger.new($stdout)
      @redis = RedisConnection.new(self)

      @mlb = MLBStatsAPI::Client.new(logger: @logger, cache: Redis.new)

      load_commands
    end

    # rubocop:disable Metrics/MethodLength
    def load_commands
      include! BaseballDiscord::Commands::Debug
      include! BaseballDiscord::Commands::Glossary
      include! BaseballDiscord::Commands::Invite
      include! BaseballDiscord::Commands::Links
      include! BaseballDiscord::Commands::Players
      include! BaseballDiscord::Commands::Scoreboard
      include! BaseballDiscord::Commands::Standings
      include! BaseballDiscord::Commands::TeamCalendar
      include! BaseballDiscord::Commands::TeamRoles
      include! BaseballDiscord::Commands::Verify
      include! BaseballDiscord::Commands::WCStandings

      include! BaseballDiscord::Events::MemberJoin
    end
    # rubocop:enable Metrics/MethodLength

    def prefix_proc(prefixes)
      lambda do |message|
        prefixes = (message.server ? prefixes[message.server.id] : nil) || ['!']

        prefixes.each do |prefix|
          next unless message.content.start_with?(prefix)

          return message.content[prefix.size..-1]
        end

        nil
      end
    end
  end

  class UserError < RuntimeError
  end
end
