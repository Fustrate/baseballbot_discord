# frozen_string_literal: true

require 'discordrb'
require 'mlb_stats_api'
require 'redis'
require 'rufus-scheduler'
require 'terminal-table'
require 'time'

require_relative '../baseball_discord/utilities'
require_relative 'output_helpers'

require_relative 'emoji'
require_relative 'game_channel'

require_relative 'embeds/alert'
require_relative 'embeds/color'
require_relative 'embeds/end_of_game'
require_relative 'embeds/end_of_inning'

require_relative 'embeds/play'
require_relative 'embeds/home_run'
require_relative 'embeds/interesting'
require_relative 'embeds/statcast_gfx'
require_relative 'embeds/strikeout_or_walk'

module GameChatBot
  # The master bot that controls all of the game channels
  class Bot < Discordrb::Commands::CommandBot
    attr_reader :client, :redis, :scheduler

    def initialize(attributes = {})
      @games = {}

      @client = MLBStatsAPI::Client.new
      @redis = Redis.new

      ready { start_loop }

      register_commands

      super attributes.merge(prefix: '!')
    end

    def home_run_alert(embed)
      @scheduler.in('15s') do
        channel(457653686118907936).send_embed '', embed
      end
    end

    protected

    def register_commands
      command(:linescore) { |event| feed_for_event(event)&.send_line_score }
      command(:lineups) { |event| feed_for_event(event)&.send_lineups }
      command(:umpires) { |event| feed_for_event(event)&.send_umpires }

      command(:lineup) do |event, *args|
        feed_for_event(event)&.send_lineup(event, args.join(' '))
      end

      command(:autoupdate) do |event, *args|
        feed_for_event(event)&.autoupdate(args.join(' '))
      end
    end

    def feed_for_event(event)
      @games[event.channel&.id]
    end

    def start_loop
      @scheduler = Rufus::Scheduler.new

      @scheduler.every('20s') { update_games }

      # Start right away
      update_games
    end

    def update_games
      @games.each_value(&:update)

      start_games

      @games.select { |_, game| game.game_over }.keys.each do |channel_id|
        @games.delete channel_id
        @redis.hdel 'live_games', channel(channel_id).name
      end
    end

    def start_games
      @redis.hgetall('live_games').each do |channel_name, game_pk|
        channel = find_channel(channel_name).first

        next unless channel && @games[channel.id]&.game_pk != game_pk

        @games[channel.id] = GameChannel.new(self, game_pk, channel)
      end
    end
  end
end
