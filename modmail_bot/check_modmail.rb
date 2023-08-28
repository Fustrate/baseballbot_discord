# frozen_string_literal: true

module ModmailBot
  class CheckModmail
    # Automod and bans might be separated into other channels later
    CHANNEL_IDS = {
      modmail: 1141768383797416018
    }.freeze

    TAG_IDS = {
      automod: 1142133675203506266,
      ban: 1142133717695995954,
      other: 1143038222730014780
    }.freeze

    attr_reader :bot

    def initialize(bot)
      @bot = bot
    end

    def check!
      @modmail ||= bot.reddit.session.modmail

      bot.reddit.with_account do
        @modmail.conversations(subreddits: [subreddit], limit: 25, sort: :recent).each { process_modmail(_1) }
      end
    end

    protected

    def subreddit = (@subreddit ||= bot.reddit.session.subreddit('baseball'))

    def process_modmail(conversation)
      conversation_last_updated = conversation.last_updated.to_i

      thread_last_updated = bot.redis.hget('discord_threads', conversation.id)&.to_i
      thread_id = bot.redis.hget('modmail_to_discord', conversation.id)

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
        next unless message.date.to_i > since && !internal_message?(message)

        thread.send_message message_to_discord(message, since)

        sleep 0.5
      end

      bot.redis.hset('discord_threads', conversation.id, conversation.last_updated.to_i)
    end

    def conversation_to_discord(conversation)
      message = conversation.messages.first

      <<~MARKDOWN
        #{message.markdown_body}

        [View on Reddit](https://mod.reddit.com/mail/all/#{conversation.id})
      MARKDOWN
    end

    def message_to_discord(message, since)
      <<~MARKDOWN
        Reply from #{message.author[:name]}:

        #{message.markdown_body}

        t:#{message.date.to_i - since}
      MARKDOWN
    end

    def tags_for(conversation)
      return [TAG_IDS[:ban]] if conversation.subject[/permanently banned from participating|is temporarily banned/]

      return [TAG_IDS[:automod]] if conversation.user[:name] == 'AutoModerator'

      [TAG_IDS[:other]]
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
