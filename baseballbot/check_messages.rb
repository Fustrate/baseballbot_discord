# frozen_string_literal: true

require_relative '../shared/reddit_client'

module BaseballDiscord
  class CheckMessages
    def initialize(bot)
      @bot = bot
    end

    def check!
      reddit.with_account do
        reddit.session.my_messages(category: 'unread', mark: false, limit: 10)&.each { process_message(_1) }
      end
    end

    protected

    def reddit = (@reddit ||= RedditClient.new(@bot))

    def process_message(message)
      match_data = message.body.match(/verify:(?<state>[a-z0-9_-]{22})/i)

      return unless match_data

      state_data = @bot.redis.get "discord.verification.#{match_data[:state]}"

      received_verification_message(message, JSON.parse(state_data)) if state_data
    end

    def verification_message?(message)
      message.is_a?(Redd::Models::PrivateMessage) &&
        message.subject.match?(/discord verification/i) &&
        message.body.match?(/verify:[a-z_-]{22}/i)
    end

    def received_verification_message(message, data)
      reddit_username = message.author.name

      member = @bot.server(data['server'].to_i).member(data['user'].to_i)

      process_member_verification(member, data, reddit_username)

      message.mark_as_read
    end

    def process_member_verification(member, data, reddit_username)
      return unless member

      add_member_role member, data['role'].to_i

      update_member_name(member, reddit_username)

      send_verified_message(member, reddit_username)
    end

    def send_verified_message(member, reddit_username)
      member.pm(@bot.config.server(member.server.id)['verified_message'] || VERIFIED_MESSAGE)

      send_to_log_channel 'Verified', "#{mention(member)} verified as #{reddit_username}", member.server.id
    end

    def add_member_role(member, role_id)
      member.add_role role_id

      @bot.logger.debug "[Role] Added role #{role_id} to #{mention(member)}"
    end

    def update_member_name(member, reddit_username)
      member.nick = reddit_username

      @bot.logger.debug "[Name] Updated name for #{mention(member)} to #{reddit_username}"
    rescue Discordrb::Errors::NoPermission
      send_to_log_channel(
        'Verification Error',
        "Couldn't update name for #{mention(member)} to #{reddit_username}",
        member.server.id
      )
    end

    def send_to_log_channel(title, description, server_id)
      @bot.logger.debug message

      log_channel_id = @bot.config.server(server_id)['log_channel']

      return unless log_channel_id

      @bot.channel(log_channel_id).send_message '', false, {
        title:,
        description:,
        color: '106499'.to_i(16)
      }
    end

    def mention(member) = "#{member.distinct} (<@#{member.id}>)"
  end
end
