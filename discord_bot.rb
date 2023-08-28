# frozen_string_literal: true

require 'discordrb'
require 'logger'
require 'mlb_stats_api'
require 'redis'
require 'rufus-scheduler'
require 'sequel'

require_relative 'shared/config'
require_relative 'shared/reddit_client'

# Connect to the database immediately so that model classes can be created.
DB = Sequel.connect(
  adapter: :postgres,
  database: ENV.fetch('BASEBALLBOT_PG_DATABASE'),
  password: ENV.fetch('BASEBALLBOT_PG_PASSWORD'),
  user: ENV.fetch('BASEBALLBOT_PG_USERNAME'),
)

class DiscordBot < Discordrb::Commands::CommandBot
  def initialize(**options)
    ready { start_loop }

    super(**options)

    load_commands
  end

  def config = (@config ||= Config.new)

  def db = DB

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

    @scheduler.every('30s') { event_loop }

    @scheduler.join
  rescue NotImplementedError
    # Nothing to loop
  end

  def load_commands; end
end
