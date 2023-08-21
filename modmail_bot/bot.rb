# frozen_string_literal: true

require 'discordrb'
require 'pg'
require 'redis'
require 'rufus-scheduler'
require 'time'

require_relative '../shared/discordrb_forum_threads'
require_relative '../shared/output_helpers'
require_relative '../shared/slash_command'
require_relative '../shared/utilities'

require_relative 'reddit_client'

# Require all commands
Dir.glob("#{__dir__}/{commands}/*").each { require_relative _1 }

module ModmailBot
  class Bot < Discordrb::Commands::CommandBot
    INTENTS = %i[servers server_messages server_message_reactions].freeze

    CHANNEL_IDS = {
      modmail: 1141768383797416018
    }.freeze

    TAG_IDS = {
      automod: 1142133675203506266,
      ban: 1142133717695995954
    }.freeze

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

      load_commands
    end

    def logger = (@logger ||= Logger.new($stdout))

    def redis = (@redis ||= Redis.new)

    def reddit = (@reddit ||= RedditClient.new(self))

    def db
      @db ||= PG::Connection.new(
        user: ENV.fetch('BASEBALLBOT_PG_USERNAME'),
        dbname: ENV.fetch('BASEBALLBOT_PG_DATABASE'),
        password: ENV.fetch('BASEBALLBOT_PG_PASSWORD')
      )
    end

    protected

    def load_commands
      ModmailBot::Commands::Archive.register self
    end

    def subreddit = (@subreddit ||= @reddit.session.subreddit('baseball'))

    def start_loop
      @scheduler = Rufus::Scheduler.new

      @scheduler.every('20s') { check_modmail }

      # Start right away
      check_modmail

      @scheduler.join
    end

    def check_modmail
      @modmail ||= reddit.session.modmail

      reddit.with_account do
        @modmail.conversations(subreddits: [subreddit], limit: 25, sort: :recent).each { process_modmail(_1) }
      end
    end

    def process_modmail(conversation)
      conversation_last_updated = conversation.last_updated.to_i

      thread_last_updated = redis.hget('discord_threads', conversation.id)&.to_i
      thread_id = redis.hget('modmail_to_discord', conversation.id)

      return post_thread!(conversation) unless thread_id && thread_last_updated

      return unless conversation_last_updated > thread_last_updated

      update_thread!(conversation, thread_id, after: thread_last_updated)
    end

    def post_thread!(conversation)
      thread = channel(CHANNEL_IDS[:modmail]).start_forum_thread(
        "#{conversation.user[:name] || 'Reddit'}: #{conversation.subject}",
        { content: conversation_to_discord(conversation) },
        applied_tags: tags_for(conversation)
      )

      update_redis!(conversation, thread)
    end

    def update_thread!(conversation, thread_id, after:)
      since = Time.at(after).to_i

      thread = channel thread_id

      conversation.messages.each do |message|
        next if message.date.to_i < since

        thread.send_message message_to_discord(message) unless internal_message?(message)

        sleep 0.5
      end

      redis.hset('discord_threads', conversation.id, conversation.last_updated.to_i)
    end

    def conversation_to_discord(conversation)
      message = conversation.messages.first

      <<~MARKDOWN
        #{message.markdown_body}

        [View on Reddit](https://mod.reddit.com/mail/all/#{conversation.id})
      MARKDOWN
    end

    def message_to_discord(message)
      <<~MARKDOWN
        Reply from #{message.author[:name]}:

        #{message.markdown_body}
      MARKDOWN
    end

    def tags_for(conversation)
      return [TAG_IDS[:ban]] if conversation.subject[/permanently banned from participating|is temporarily banned/]

      return [TAG_IDS[:automod]] if conversation.user[:name] == 'AutoModerator'

      []
    end

    def update_redis!(conversation, thread)
      redis.hset('modmail_to_discord', conversation.id, thread.id)
      redis.hset('discord_to_modmail', thread.id, conversation.id)
      redis.hset('discord_threads', conversation.id, conversation.last_updated.to_i)
    end

    def internal_message?(message)
      message.author[:name] == 'BaseballBot' && message.markdown_body.match?(/\A(Archived|Unarchived) by/)
    end
  end
end
