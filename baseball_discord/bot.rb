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

    def initialize(attributes = {})
      @db = PG::Connection.new attributes.delete(:db)

      super attributes

      @redis = Redis.new
      @logger = Logger.new($stdout)
      @mlb = MLBStatsAPI::Client.new(logger: @logger, cache: @redis)
    end
  end
end
