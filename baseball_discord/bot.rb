# frozen_string_literal: true

require 'chronic'
require 'date'
require 'discordrb'
require 'mlb_stats_api'
require 'open-uri'
require 'pg'
require 'redd'
require 'redis'
require 'securerandom'
require 'terminal-table'
require 'tzinfo'

require_relative 'command'
require_relative 'utilities'

require_relative 'commands/debug'
require_relative 'commands/last_ten'
require_relative 'commands/next_ten'
require_relative 'commands/scoreboard'
require_relative 'commands/standings'
require_relative 'commands/verify'

require_relative 'events/member_join'

module BaseballDiscord
  class Bot < Discordrb::Commands::CommandBot
    attr_reader :db, :mlb, :redis, :logger

    NON_TEAM_CHANNELS = %w[
      general bot welcome verification discord-options
    ].freeze

    NON_TEAM_ROLES = [
      'mods', 'bot', 'verified', 'discord mods', 'team sub mods'
    ].freeze

    # Discord ID of the rBaseball server
    SERVER_ID = 400_516_567_735_074_817

    VERIFIED_ROLES = {
      400_516_567_735_074_817 => 449_686_034_507_366_440
    }.freeze

    def initialize(attributes = {})
      @db = PG::Connection.new attributes.delete(:db)

      super attributes

      @redis = Redis.new
      @logger = Logger.new($stdout)

      @mlb = MLBStatsAPI::Client.new(logger: @logger, cache: @redis)

      load_commands
    end

    def load_commands
      include! BaseballDiscord::Commands::Debug
      include! BaseballDiscord::Commands::LastTen
      include! BaseballDiscord::Commands::NextTen
      include! BaseballDiscord::Commands::Scoreboard
      include! BaseballDiscord::Commands::Standings
      include! BaseballDiscord::Commands::Verify

      include! BaseballDiscord::Events::MemberJoin
    end

    def run(async = false)
      super(async)
    end

    def user_verified(verification_token, reddit_username)
      data = @redis.hgetall(verification_token)

      guild = server data['server_id'].to_i
      member = guild.member data['user_id'].to_i

      verified_role = VERIFIED_ROLES[guild.id]

      member.add_role verified_role, 'User verified their reddit account'
      member.set_nick reddit_username, 'Syncing reddit username'

      member.pm 'Thanks for verifying your account!'
    end
  end
end
