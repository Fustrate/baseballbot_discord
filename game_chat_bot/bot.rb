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

      scheduler.every('20s') { update_games }

      # Start right away
      start_games
      update_games
    end

    def update_games
      @games.each_value(&:update_game_chat)

      start_games
    end

    def start_games
      @redis.hgetall('live_games').each do |channel_name, game_pk|
        channel = server_channels.find { |chan| chan.name == channel_name }

        next unless channel && @games[channel.id]&.game_pk != game_pk

        @games[channel.id] = game_channel(game_pk, channel)
      end
    end

    def server_channels
      @server_channels ||= servers[SERVER_ID].channels
    end

    def game_channel(game_pk, channel)
      GameChannel.new(self, game_pk, channel, @client.live_feed(game_pk))
    end
  end
end
