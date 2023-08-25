# frozen_string_literal: true

require 'discordrb'
require 'logger'
require 'mlb_stats_api'
require 'pg'
require 'redis'
require 'rufus-scheduler'

require_relative 'shared/config'
require_relative 'shared/reddit_client'

class DiscordBot < Discordrb::Commands::CommandBot
  def initialize(**options)
    ready { start_loop }

    super(**options)

    load_commands
  end

  def config = (@config ||= Config.new)

  def db
    @db ||= PG::Connection.new(
      user: ENV.fetch('BASEBALLBOT_PG_USERNAME'),
      dbname: ENV.fetch('BASEBALLBOT_PG_DATABASE'),
      password: ENV.fetch('BASEBALLBOT_PG_PASSWORD')
    )
  end

  def logger = (@logger ||= Logger.new($stdout))

  def reddit = (@reddit ||= RedditClient.new(self))

  def redis = (@redis ||= Redis.new)

  def stats_api = (@stats_api ||= MLBStatsAPI::Client.new(logger:, cache: redis))

  protected

  def event_loop = raise NotImplementedError

  def start_loop
    # Start right away
    event_loop

    @scheduler = Rufus::Scheduler.new

    @scheduler.every('30s', event_loop)

    @scheduler.join
  rescue NotImplementedError
    # Nothing to loop
  end

  def load_commands; end
end
