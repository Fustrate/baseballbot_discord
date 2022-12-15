# frozen_string_literal: true

module BaseballDiscord
  class RedisConnection
    attr_reader :redis

    VERIFIED_MESSAGE = <<~PM
      Thanks for verifying your account! You should now have access to the server.
    PM

    def initialize(bot)
      @bot = bot

      connect
    end

    def connect
      ensure_redis

      # Make sure we eventually clear the queue
      EM.add_periodic_timer(30) { check_verification_queue }

      EM.next_tick do
        subscribe('discord.verified') do
          @bot.logger.debug '[Redis] Received discord.verified event'

          check_verification_queue
        end

        check_verification_queue
      end
    end

    def ensure_redis
      unless EM.reactor_running? && EM.reactor_thread.alive?
        Thread.new { EM.run }
        sleep 0.25
      end

      return if @redis

      @redis = EM::Hiredis.connect

      sleep 0.25
    end

    def expire(key, ttl)
      ensure_redis

      EM.next_tick do
        @bot.logger.debug "[Redis] Expire #{key}: #{ttl}"

        @redis.expire key, ttl
      end
    end

    def set(key, value)
      ensure_redis

      EM.next_tick do
        @bot.logger.debug "[Redis] Set #{key}: #{value.inspect}"

        @redis.set key, value
      end
    end

    def get(key)
      ensure_redis

      @redis.get(key) do |value|
        @bot.logger.debug "[Redis] Get #{key}: #{value.inspect}"

        yield value
      end
    end

    def subscribe(channel, &)
      ensure_redis

      @redis.pubsub.subscribe(channel, &)
    end

    protected

    def check_verification_queue
      ensure_redis

      @redis.lpop('discord.verification_queue') { process_verification_message(_1) }
    end

    def process_verification_message(message)
      return unless message

      @bot.logger.debug "[Redis] Queue has content: #{message}"

      data = JSON.parse(message)

      user_verified_on_reddit! data['state_token'], data['reddit_username']

      check_verification_queue
    end

    def user_verified_on_reddit!(state_token, reddit_username)
      @redis.get("discord.verification.#{state_token}") { process_verification_data(_1, reddit_username) }
    end

    def process_verification_data(state_data, reddit_username)
      return unless state_data

      data = JSON.parse state_data

      member = @bot.server(data['server'].to_i).member(data['user'].to_i)

      process_member_verification(member, data, reddit_username)
    end

    def process_member_verification(member, data, reddit_username)
      return unless member

      add_member_role member, data['role'].to_i

      update_member_name(member, reddit_username)

      send_verified_message(member, reddit_username)
    end

    def send_verified_message(member, reddit_username)
      member.pm(@bot.config.server(member.server.id)['verified_message'] || VERIFIED_MESSAGE)

      send_to_log_channel "[Verified] #{member.distinct} verified as #{reddit_username}", member.server.id
    end

    def add_member_role(member, role_id)
      member.add_role role_id

      @bot.logger.debug "[Role] Added role #{role_id} to #{member.distinct}"
    end

    def update_member_name(member, reddit_username)
      member.nick = reddit_username

      @bot.logger.debug "[Name] Updated name for #{member.distinct} to #{reddit_username}"
    rescue Discordrb::Errors::NoPermission
      send_to_log_channel "Couldn't update name for #{member.distinct} to #{reddit_username}", member.server.id
    end

    def send_to_log_channel(message, server_id)
      @bot.logger.debug message

      log_channel_id = @bot.config.server(server_id)['log_channel']

      return unless log_channel_id

      channel(log_channel_id).send_message message
    end
  end
end
