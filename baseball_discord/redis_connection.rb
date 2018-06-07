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

    def mapped_hmset(key, values = {})
      ensure_redis

      EM.next_tick do
        @bot.logger.debug "[Redis] Mapped HM Set #{key}: #{values.inspect}"

        @redis.mapped_hmset key, values
      end
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

    def subscribe(channel, &block)
      ensure_redis

      @redis.pubsub.subscribe channel, &block
    end

    def psubscribe(pattern)
      ensure_redis

      @redis.pubsub.psubscribe(pattern)

      @redis.pubsub.on(:pmessage) do |key, channel, message|
        break unless key == pattern

        yield key, channel, message
      end
    end

    protected

    def check_verification_queue
      @bot.logger.debug '[Redis] Checking queue...'

      ensure_redis

      @redis.lpop('discord.verification_queue') do |message|
        process_verification_message(message) if message
      end
    end

    def process_verification_message(message)
      @bot.logger.debug "[Redis] Queue has content: #{message}"

      data = JSON.parse(message)

      user_verified_on_reddit! data['state_token'], data['reddit_username']

      check_verification_queue
    end

    def user_verified_on_reddit!(state_token, reddit_username)
      @redis.get("discord.verification.#{state_token}") do |state_data|
        return unless state_data

        data = JSON.parse state_data

        member = @bot.server(data['server'].to_i).member(data['user'].to_i)

        process_member_verification(member, data, reddit_username)
      end
    end

    def process_member_verification(member, data, reddit_username)
      return unless member

      member.add_role data['role'].to_i

      update_member_name(member, reddit_username)

      send_verified_message(member)
    end

    def send_verified_message(member)
      custom_message = @bot.config.server(member.server.id)['verified_message']

      member.pm(custom_message || VERIFIED_MESSAGE)
    end

    def update_member_name(member, reddit_username)
      # return if member.display_name == reddit_username

      member.nick = reddit_username
    rescue Discordrb::Errors::NoPermission
      @bot.logger.info "Couldn't update name for #{member.distinct} " \
                       "to #{reddit_username}"
    end
  end
end
