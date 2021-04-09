# frozen_string_literal: true

require_relative 'concerns/alerts'
require_relative 'concerns/color_feed'
require_relative 'concerns/game_feed'
require_relative 'concerns/line_score'
require_relative 'concerns/plays'

require_relative 'output_helpers'

# rubocop:disable all
module Discordrb::API
  # Make an API request, including rate limit handling.
  def request(key, major_parameter, type, *attributes)
    # Add a custom user agent
    attributes.last[:user_agent] = user_agent if attributes.last.is_a? Hash

    # The most recent Discord rate limit requirements require the support of major parameters, where a particular route
    # and major parameter combination (*not* the HTTP method) uniquely identifies a RL bucket.
    key = [key, major_parameter].freeze

    begin
      mutex = @mutexes[key] ||= Mutex.new

      # Lock and unlock, i.e. wait for the mutex to unlock and don't do anything with it afterwards
      mutex_wait(mutex)

      # If the global mutex happens to be locked right now, wait for that as well.
      mutex_wait(@global_mutex) if @global_mutex.locked?

      response = nil
      begin
        response = raw_request(type, attributes)
      rescue RestClient::Exception => e
        response = e.response

        if response.body
          puts response.body

          data = JSON.parse(response.body)
          err_klass = Discordrb::Errors.error_class_for(data['code'] || 0)
          e = err_klass.new(data['message'], data['errors'])

          Discordrb::LOGGER.error(e.full_message)
        end

        raise e
      rescue Discordrb::Errors::NoPermission => e
        if e.respond_to?(:_rc_response)
          response = e._rc_response
        else
          Discordrb::LOGGER.warn("NoPermission doesn't respond_to? _rc_response!")
        end

        raise e
      ensure
        if response
          handle_preemptive_rl(response.headers, mutex, key) if response.headers[:x_ratelimit_remaining] == '0' && !mutex.locked?
        else
          Discordrb::LOGGER.ratelimit('Response was nil before trying to preemptively rate limit!')
        end
      end
    rescue RestClient::TooManyRequests => e
      # If the 429 is from the global RL, then we have to use the global mutex instead.
      mutex = @global_mutex if e.response.headers[:x_ratelimit_global] == 'true'

      unless mutex.locked?
        response = JSON.parse(e.response)
        wait_seconds = response['retry_after'].to_i / 1000.0
        Discordrb::LOGGER.ratelimit("Locking RL mutex (key: #{key}) for #{wait_seconds} seconds due to Discord rate limiting")
        trace("429 #{key.join(' ')}")

        # Wait the required time synchronized by the mutex (so other incoming requests have to wait) but only do it if
        # the mutex isn't locked already so it will only ever wait once
        sync_wait(wait_seconds, mutex)
      end

      retry
    end

    response
  end
end
# rubocop:enable all

module GameChatBot
  # Handles everything related to having a channel for a specific game.
  class GameChannel
    include Alerts
    include ColorFeed
    include GameFeed
    include LineScore
    include Plays

    include OutputHelpers

    attr_reader :bot, :channel, :feed, :game_pk, :game_over

    def initialize(bot, game_pk, channel)
      @bot = bot

      @game_pk = game_pk
      @channel = channel
      @feed = @bot.client.live_feed(game_pk)
      @color_feed = load_color_feed

      @starts_at = Time.parse @feed.game_data.dig('datetime', 'dateTime')
      @last_update = Time.now - 3600 # So we can at least do one update

      @game_over = false

      @unmuted = bot.redis.get("#{redis_key}_unmuted")
    end

    def send_message(text: '', embed: nil, at: nil, force: false)
      return unless force || @unmuted

      if at
        @bot.scheduler.at(at) do
          @channel.send_message(text, false, embed)
        end
      else
        @channel.send_message(text, false, embed)
      end
    end

    def autoupdate(new_state)
      # Allow the bare `!autoupdate` command to turn on updates
      return unmute! if new_state.empty? || %w[1 yes on true].include?(new_state.downcase.strip)

      return mute! if %w[0 no off false].include?(new_state.downcase.strip)

      nil
    end

    def update
      return unless ready_to_update? && @feed.update!

      # @bot.logger.info "[#{redis_key}] Updating"

      output_plays
      output_alerts
      output_lineups
      process_color_feed

      @bot.scheduler.in('15s') { update_channel_topic }

      @game_over = true if game_ended?
    rescue Net::OpenTimeout, SocketError, RestClient::NotFound
      nil
    end

    def send_line_score
      @bot.logger.info "[#{redis_key}] Sending line score"

      send_message text: line_score_block
    end

    def send_lineups
      @bot.logger.info "[#{redis_key}] Sending lineups"

      send_message text: lineups
    end

    def send_lineup(event, input)
      @bot.logger.info "[#{redis_key}] Sending lineup"

      lineup = team_lineup(input)

      return event.message.react('❓') unless lineup

      send_message text: lineup
    end

    def send_umpires
      @bot.logger.info "[#{redis_key}] Sending umpires"

      send_message embed: { fields: fields_for_umpires }
    end

    protected

    def load_color_feed
      @bot.client.color_feed(game_pk)
    rescue MLBStatsAPI::NotFoundError
      # No color feed
    end

    def redis_key
      @redis_key ||= "#{@channel.id}_#{@game_pk}"
    end

    def ready_to_update?
      return false if @game_over

      return true if Time.now >= @starts_at

      # Only update every ~30 minutes when the game hasn't started yet
      return false unless @last_update + 1800 <= Time.now

      @last_update = Time.now

      true
    end

    def mute!
      @bot.logger.info "[#{redis_key}] Muting"

      @unmuted = false

      @bot.redis.del "#{redis_key}_unmuted"

      'Autoupdates are off. Use `!autoupdate on` to unmute.'
    end

    def unmute!
      @bot.logger.info "[#{redis_key}] Unmuting"

      @unmuted = true

      @bot.redis.set "#{redis_key}_unmuted", 1

      'Autoupdates are on. Use `!autoupdate off` to mute.'
    end

    def update_channel_topic
      new_topic = line_score_state

      # We don't need to keep updating the same thing
      return if new_topic == @channel.topic

      @bot.logger.info "[#{redis_key}] Updating topic: #{new_topic}"

      @channel.topic = new_topic
    end
  end
end
