# frozen_string_literal: true

module BaseballDiscord
  class RedisConnection
    attr_reader :redis

    def initialize(bot)
      @bot = bot

      connect
    end

    def connect
      ensure_redis

      EM.next_tick do
        subscribe('discord.debug') do |message|
          puts message.inspect
        end

        subscribe('discord.verified') do |_message|
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

    def check_verification_queue
      ensure_redis

      @redis.lpop('discord.verification_queue') do |value|
        if value
          value.to_i

          check_queue
        end
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

    def parse_message(data)
      JSON.parse(data)
    end
  end
end
