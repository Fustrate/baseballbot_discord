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

    def subreddit = (@subreddit ||= @reddit.session.subreddit('baseball'))

    def discord_server = (@discord_server ||= server 709901748445249628)

    def modmail_channel = (@modmail_channel ||= channel 1141768383797416018)

    def start_loop
      @scheduler = Rufus::Scheduler.new

      @scheduler.every('20s') { check_modmail }

      # Start right away
      check_modmail

      @scheduler.join
    end

    def check_modmail
      @modmail ||= @reddit.session.modmail

      with_reddit_account do
        @modmail.conversations(subreddits: [subreddit], limit: 10, sort: :recent).each { process_modmail(_1) }
      end
    end

    def process_modmail(conversation)
      conversation_last_updated = conversation.last_updated.to_i

      thread_last_updated = redis.hget('discord_threads', conversation.id)

      return post_thread!(conversation) unless thread_last_updated

      update_thread!(conversation, after: thread_last_updated) if conversation_last_updated > thread_last_updated
    end

    def post_thread!(conversation)
      thread = modmail_channel.start_thread(name, 7 * 24 * 60, type: :forum)

      redis.hset('discord_threads', conversation.id, conversation.last_updated.to_i)
    end

    def update_thread!(conversation, after:)
      since = Time.at(after)

      thread = modmail_channel

      conversation.messages.each do |message|
        next if message.date.to_i < since

        post_message_to_thread!(thread, message)
      end

      redis.hset('discord_threads', conversation.id, conversation.last_updated.to_i)
    end
  end
end

module Discordrb
  # A Discord channel, including data like the topic
  class Channel
    def start_thread(name, auto_archive_duration, message: nil, type: 11)
      message_id = message&.id || message
      type = TYPES[type] || type

      data = if message
              API::Channel.start_thread_with_message(@bot.token, @id, message_id, name, auto_archive_duration)
            else
              API::Channel.start_thread_without_message(@bot.token, @id, name, auto_archive_duration, type)
            end

      Channel.new(JSON.parse(data), @bot, @server)
    end
  end
end
