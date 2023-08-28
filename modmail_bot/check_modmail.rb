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
      @subreddit ||= bot.reddit.session.subreddit('baseball')

      bot.reddit.with_account do
        @modmail.conversations(subreddits: [@subreddit], limit: 25, sort: :recent).each { process_modmail(_1) }
      end
    end

    protected

    def modmails = (@modmails ||= bot.db[:modmails])

    def process_modmail(conversation)
      modmail = modmails.first(reddit_id: conversation.id)

      return post_thread!(conversation) unless modmail

      update_thread!(conversation, modmail)
    end

    def post_thread!(conversation)
      thread = bot.channel(CHANNEL_IDS[:modmail]).start_forum_thread(
        "#{conversation.user[:name] || 'Reddit'}: #{conversation.subject}",
        { content: conversation_to_discord(conversation) },
        applied_tags: tags_for(conversation)
      )

      insert_modmail(conversation, thread)
    end

    def update_thread!(conversation, modmail)
      thread = bot.channel modmail[:thread_id]

      new_messages = conversation.messages.filter_map do |message|
        message_to_discord(message) unless internal_message?(message) || message.date < modmail[:updated_at]
      end

      return if new_messages.none?

      new_messages.each { thread.send_message('', false, _1) }

      modmail.update(**timestamps)
    end

    def conversation_to_discord(conversation)
      message = conversation.messages.first

      <<~MARKDOWN
        #{message.markdown_body}

        [View on Reddit](https://mod.reddit.com/mail/all/#{conversation.id})
      MARKDOWN
    end

    def message_to_discord(message)
      {
        title: title_for(message),
        description: message.markdown_body,
        color: embed_color(message)
      }
    end

    def title_for(message)
      message.internal? ? "#{message.author[:name]} left a private note" : "#{message.author[:name]} replied"
    end

    def embed_color(message)
      # Dark Green
      return 2067276 if message.internal?

      author = message[:author]

      # Red
      return 15158332 if author[:isAdmin]

      # Dark But Not Black
      return 2895667 if author[:isHidden]

      # Green
      return 3066993 if author[:isMod]

      # Blue
      return 3447003 if author[:isOp]

      # None
      0
    end

    def tags_for(conversation)
      return [TAG_IDS[:ban]] if conversation.subject[/permanently banned from participating|is temporarily banned/]

      return [TAG_IDS[:automod]] if conversation.user[:name] == 'AutoModerator'

      [TAG_IDS[:other]]
    end

    def internal_message?(message)
      message.author[:name] == 'BaseballBot' && message.markdown_body.match?(/\A(Archived|Unarchived) by/)
    end

    def insert_modmail(conversation, thread)
      modmails.insert(
        subreddit_id: 15,
        reddit_id: conversation.id,
        subject: conversation.subject,
        thread_id: thread.id,
        username: conversation.user[:name],
        status: true,
        **timestamps
      )
    end

    def timestamps = { created_at: Time.now, updated_at: Time.now }
  end
end
