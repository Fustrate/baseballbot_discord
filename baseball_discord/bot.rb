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

    # Discord ID of the rBaseball server
    SERVER_ID = 400_516_567_735_074_817

    def initialize(attributes = {})
      @db = PG::Connection.new attributes.delete(:db)

      super attributes

      @redis = Redis.new
      @logger = Logger.new($stdout)
    end

    def self.parse_date(date)
      return Time.now if date.strip == ''

      Chronic.parse(date)
    end

    def self.parse_time(utc, time_zone: 'America/New_York')
      time_zone = TZInfo::Timezone.get(time_zone) if time_zone.is_a? String

      utc = Time.parse(utc).utc unless utc.is_a? Time

      period = time_zone.period_for_utc(utc)
      with_offset = utc + period.utc_total_offset

      Time.parse "#{with_offset.strftime('%FT%T')} #{period.zone_identifier}"
    end
  end
end
