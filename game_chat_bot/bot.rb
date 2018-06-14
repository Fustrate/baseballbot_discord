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

    def start_loop
      scheduler = Rufus::Scheduler.new

      scheduler.every('20s') { update_games }

      update_games
    end

    def update_games
      load_games if @games.empty?

      @games.each_value(&:update_game_chat)
    end

    def load_games
      # @games[455657467360313357] = game_feed(530388, 455657467360313357)
      # @games[455657468442443777] = game_feed(530394, 455657468442443777)
      # @games[455657468102443018] = game_feed(530395, 455657468102443018)
      # @games[455657469268590592] = game_feed(530389, 455657469268590592)
      # @games[455657469600071684] = game_feed(530390, 455657469600071684)
      # @games[455657469947936770] = game_feed(530393, 455657469947936770)
      @games[456019857838833665] = game_feed(530423, 456019857838833665)
    end

    def game_feed(game_pk, channel_id)
      Feed.new(
        self,
        game_pk,
        servers[SERVER_ID].channels.find { |channel| channel.id == channel_id },
        @client.live_feed(game_pk)
      )
    end
  end
end
