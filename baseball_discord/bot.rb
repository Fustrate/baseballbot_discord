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

require_relative 'config'
require_relative 'redis_connection'
require_relative 'slash_command'

require_relative '../shared/utilities'

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
        prefix: '!',
        intents: INTENTS
      )

      load_commands
    end

    # rubocop:disable Metrics/MethodLength
    def load_commands
      BaseballDiscord::Commands::Debug.register self
      BaseballDiscord::Commands::Glossary.register self
      BaseballDiscord::Commands::Invite.register self
      BaseballDiscord::Commands::Links.register self
      BaseballDiscord::Commands::Scoreboard.register self
      BaseballDiscord::Commands::Standings.register self
      BaseballDiscord::Commands::Schedule.register self
      BaseballDiscord::Commands::TeamRoles.register self
      BaseballDiscord::Commands::Verify.register self
      BaseballDiscord::Commands::Wildcard.register self

      include! BaseballDiscord::Events::MemberJoin
    end
    # rubocop:enable Metrics/MethodLength

    def logger = (@logger ||= Logger.new($stdout))

    def redis = (@redis ||= RedisConnection.new(self))

    def mlb = (@mlb ||= MLBStatsAPI::Client.new(logger:, cache: Redis.new))

    def config = (@config ||= Config.new)
  end

  class UserError < RuntimeError; end
end
