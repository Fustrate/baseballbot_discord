# frozen_string_literal: true

require_relative 'concerns/alerts'
require_relative 'concerns/game_feed'
require_relative 'concerns/line_score'
require_relative 'concerns/plays'

require_relative 'output_helpers'

module GameChatBot
  # Handles everything related to having a channel for a specific game.
  class GameChannel
    include Alerts
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

      @starts_at = Time.parse @feed.game_data.dig('datetime', 'dateTime')
      @last_update = Time.now - 3600 # So we can at least do one update

      @game_over = false
      @unmuted = bot.redis.get("#{redis_key}_unmuted")
    end

    def send_message(text: '', embed: nil, at: nil, force: false)
      return unless force || @unmuted

      if at
        @bot.scheduler.at(at) do
          @channel.send_message text, false, embed
        end
      else
        @channel.send_message text, false, embed
      end
    end

    def autoupdate(new_state)
      return unmute! if %w[1 yes on true].include?(new_state.downcase.strip)

      return mute! if %w[0 no off false].include?(new_state.downcase.strip)

      nil
    end

    def update
      return unless ready_to_update? && @feed.update!

      output_plays
      output_alerts

      @bot.scheduler.in('15s') do
        @channel.topic = line_score_state
      end

      if @feed.game_data.dig('status', 'abstractGameState') == 'Final'
        @game_over = true
      end
    rescue Net::OpenTimeout, SocketError, RestClient::NotFound
      nil
    end

    def send_line_score
      send_message text: line_score_block
    end

    def send_lineups
      send_message text: lineups
    end

    def send_lineup(event, input)
      lineup = team_lineup(input)

      return event.message.react('❓') unless lineup

      send_message(text: lineup)
    end

    def send_umpires
      send_embed embed: { fields: fields_for_umpires }
    end

    protected

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
      @unmuted = false

      bot.redis.del "#{redis_key}_unmuted"

      'Autoupdates are off. Use `!autoupdate on` to unmute.'
    end

    def unmute!
      @unmuted = true

      bot.redis.set "#{redis_key}_unmuted", 1

      'Autoupdates are on. Use `!autoupdate off` to mute.'
    end
  end
end
