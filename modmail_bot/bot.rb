# frozen_string_literal: true

require 'discordrb'
require 'pg'
require 'redis'
require 'rufus-scheduler'
require 'time'

require_relative '../shared/output_helpers'
require_relative '../shared/utilities'

require_relative 'reddit_client'

module ModmailBot
  class Bot < Discordrb::Commands::CommandBot
    attr_reader :reddit, :scheduler

    INTENTS = %i[servers server_messages server_message_reactions].freeze

    def initialize
      ready { start_loop }

      super(
        client_id: ENV.fetch('DISCORD_MODMAIL_CLIENT_ID'),
        token: ENV.fetch('DISCORD_MODMAIL_TOKEN'),
        command_doesnt_exist_message: nil,
        help_command: false,
        prefix: '!',
        intents: INTENTS
      )

      @reddit = RedditClient.new(self)
    end

    def logger = (@logger ||= Logger.new($stdout))

    def redis = (@redis ||= Redis.new)

    def db
      @db ||= PG::Connection.new(
        user: ENV.fetch('BASEBALLBOT_PG_USERNAME'),
        dbname: ENV.fetch('BASEBALLBOT_PG_DATABASE'),
        password: ENV.fetch('BASEBALLBOT_PG_PASSWORD')
      )
    end

    def with_reddit_account(&) = @reddit.with_account(&)

    protected

    def discord_server = (@discord_server ||= server 709901748445249628)

    def modmail_channel = (@modmail_channel ||= channel 1141768383797416018)

    def start_loop
      @scheduler = Rufus::Scheduler.new

      @scheduler.every('20s') { check_modmail }

      # Start right away
      check_modmail

      @scheduler.join
    end

    def check_modmail; end
  end
end
