# frozen_string_literal: true

require_relative 'concerns/alerts'
require_relative 'concerns/color_feed'
require_relative 'concerns/game_feed'
require_relative 'concerns/line_score'
require_relative 'concerns/plays'

require_relative 'output_helpers'

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

      # @bot.scheduler.in('15s') { update_channel_topic }

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

    def redis_key() = (@redis_key ||= "#{@channel.id}_#{@game_pk}")

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

      # This causes an API error and I can't for the life of me figure out WHAT THE DAMN ERROR IS
      @channel.topic = new_topic
    end
  end
end
