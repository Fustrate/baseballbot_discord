# frozen_string_literal: true

require 'discordrb'
require 'mlb_stats_api'
require 'redis'
require 'rufus-scheduler'
require 'terminal-table'

require_relative '../baseball_discord/utilities'
require_relative 'output_helpers'

require_relative 'alert'
require_relative 'feed'
require_relative 'line_score'
require_relative 'play'

module GameChatBot
  class Bot < Discordrb::Commands::CommandBot
    SERVER_ID = 450792745553100801

    attr_reader :client, :redis

    def initialize(attributes = {})
      @games = {}

      @client = MLBStatsAPI::Client.new
      @redis = Redis.new

      ready { start_loop }

      register_commands

      super attributes.merge(prefix: '!')
    end

    def register_commands
      command(:linescore) { |event| feed_for_event(event)&.send_line_score }
      command(:lineups) { |event| feed_for_event(event)&.send_lineups }
      command(:umpires) { |event| feed_for_event(event)&.send_umpires }

      command(:lineup) do |event, *args|
        feed_for_event(event)&.send_lineup(event, args.join(' '))
      end
    end

    def feed_for_event(event)
      @games[event.channel&.id]
    end

    def end_feed_for_channel(channel)
      @games.del channel.id
    end

    def start_loop
      scheduler = Rufus::Scheduler.new

      scheduler.every('5m') { start_games }
      scheduler.every('20s') { update_games }

      # Start right away
      start_games
      update_games
    end

    def update_games
      @games.each_value(&:update_game_chat)
    end

    def start_games
      @redis.hgetall('live_games').each do |channel_name, game_pk|
        channel = channels.find { |chan| chan.name == channel_name }

        next if @games[channel.id]&.game_pk == game_pk

        @games[channel.id] = game_feed(game_pk, channel)
      end
    end

    def channels
      @channels ||= servers[SERVER_ID].channels
    end

    def game_feed(game_pk, channel)
      Feed.new(self, game_pk, channel, @client.live_feed(game_pk))
    end
  end
end
