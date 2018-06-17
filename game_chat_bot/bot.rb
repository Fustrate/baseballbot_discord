# frozen_string_literal: true

require 'discordrb'
require 'mlb_stats_api'
require 'redis'
require 'rufus-scheduler'
require 'terminal-table'
require 'time'

require_relative '../baseball_discord/utilities'
require_relative 'output_helpers'

require_relative 'alert'
require_relative 'game_channel'
require_relative 'line_score'
require_relative 'play'

module GameChatBot
  class Bot < Discordrb::Commands::CommandBot
    attr_reader :client, :redis

    def initialize(attributes = {})
      @games = {}

      @client = MLBStatsAPI::Client.new
      @redis = Redis.new

      ready { start_loop }

      register_commands

      super attributes.merge(prefix: '!')
    end

    def home_run_alert(embed)
      channel(457653686118907936).send_embed '', embed
    end

    protected

    def register_commands
      command(:linescore) { |event| feed_for_event(event)&.send_line_score }
      command(:lineups) { |event| feed_for_event(event)&.send_lineups }
      command(:umpires) { |event| feed_for_event(event)&.send_umpires }

      command(:lineup) do |event, *args|
        feed_for_event(event)&.send_lineup(event, args.join(' '))
      end

      command(:start) { |event| feed_for_event(event)&.unmute! }
      command(:stop) { |event| feed_for_event(event)&.mute! }
    end

    def feed_for_event(event)
      @games[event.channel&.id]
    end

    def start_loop
      scheduler = Rufus::Scheduler.new

      scheduler.every('20s') { update_games }

      # Start right away
      update_games
    end

    def update_games
      @games.each_value(&:update_game_chat)

      start_games

      @games.select { |_, game| game.game_over }.keys.each do |channel_id|
        @games.delete channel_id
        @redis.hdel 'live_games', channel(channel_id).name
      end
    end

    def start_games
      @redis.hgetall('live_games').each do |channel_name, game_pk|
        chan = find_channel(channel_name).first

        next unless chan && @games[chan.id]&.game_pk != game_pk

        @games[chan.id] = game_channel(game_pk, chan)
      end
    end

    def game_channel(game_pk, channel)
      GameChannel.new(self, game_pk, channel, @client.live_feed(game_pk))
    end
  end
end
