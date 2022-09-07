# frozen_string_literal: true

require 'chronic'
require 'date'
require 'discordrb'
require 'em-hiredis'
require 'eventmachine'
require 'json'
require 'mlb_stats_api'
require 'open-uri'
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
Dir.glob("#{__dir__}/{commands,events}/*").each { require_relative _1 }

module BaseballDiscord
  class Bot < Discordrb::Commands::CommandBot
    # ID of the user allowed to administrate the bot
    ADMIN_ID = 429364871121993728

    INTENTS = %i[
      servers server_members server_messages server_message_reactions direct_messages direct_message_reactions
    ].freeze

    def initialize
      super(
        client_id: ENV.fetch('DISCORD_CLIENT_ID'),
        token: ENV.fetch('DISCORD_TOKEN'),
        prefix: prefix_proc(config.server_prefixes),
        intents: INTENTS
      )

      load_commands
    end

    # rubocop:disable Metrics/MethodLength
    def load_commands
      BaseballDiscord::Commands::Debug.register self
      include! BaseballDiscord::Commands::Glossary
      include! BaseballDiscord::Commands::Invite
      BaseballDiscord::Commands::Links.register self
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
        (prefixes[message.channel.server&.id] || ['!']).each do |prefix|
          return message.content[prefix.size..] if message.content.start_with?(prefix)
        end

        nil
      end
    end

    def logger = (@logger ||= Logger.new($stdout))

    def redis = (@redis ||= RedisConnection.new(self))

    def mlb = (@mlb ||= MLBStatsAPI::Client.new(logger:, cache: Redis.new))

    def config = (@config ||= Config.new)
  end

  class UserError < RuntimeError; end
end
