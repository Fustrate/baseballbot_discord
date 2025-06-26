# frozen_string_literal: true

require 'terminal-table'
require 'time'

require_relative '../discord_bot'

require_relative '../shared/output_helpers'
require_relative '../shared/utilities'

require_relative 'emoji'
require_relative 'game_channel'

require_relative 'embeds/alert'
require_relative 'embeds/end_of_game'
require_relative 'embeds/end_of_inning'

require_relative 'embeds/play'
require_relative 'embeds/home_run'
require_relative 'embeds/interesting'
require_relative 'embeds/strikeout_or_walk'

require_relative 'embeds/color'
require_relative 'embeds/social'
require_relative 'embeds/statcast_gfx'
require_relative 'embeds/video'

module GameChatBot
  # The master bot that controls all of the game channels
  class Bot < DiscordBot
    attr_reader :scheduler

    INTENTS = %i[servers server_messages server_message_reactions].freeze

    def initialize
      @games = {}

      super(
        client_id: ENV.fetch('DISCORD_GAMETHREAD_CLIENT_ID'),
        token: ENV.fetch('DISCORD_GAMETHREAD_TOKEN'),
        command_doesnt_exist_message: nil, help_command: false, prefix: '!', intents: INTENTS
      )
    end

    def send_to_home_runs_channel(embed)
      @scheduler.in('15s') do
        channel(457653686118907936).send_embed '', embed
      end
    end

    protected

    def baseball = (@baseball ||= server 400516567735074817)

    # TODO: Migrate to application commands
    def load_commands
      command(:linescore) { feed_for_event(it)&.send_line_score }
      command(:lineups) { feed_for_event(it)&.send_lineups }
      command(:umpires) { feed_for_event(it)&.send_umpires }

      register_commands_with_arguments
    end

    def register_commands_with_arguments
      command(:lineup) { |event, *args| feed_for_event(event)&.send_lineup(event, args.join(' ')) }
      command(:autoupdate, aliases: %i[update]) { |event, *args| feed_for_event(event)&.autoupdate(args.join(' ')) }
    end

    def feed_for_event(event) = @games[event.channel&.id]

    def event_loop
      # Make sure we've cached the list of channels in this server
      @all_channels ||= baseball.channels

      update_games
    end

    def update_games
      logger.info 'Updating game threads'

      @games.each_value(&:update)

      start_games

      @games.select { |_, game| game.game_over }.each_key do |channel_id|
        @games.delete channel_id
        redis.hdel 'live_games', channel(channel_id).name
      end
    end

    def start_games
      redis.hgetall('live_games').each do |channel_name, game_pk|
        channel = find_channel(channel_name).first

        next unless channel && @games[channel.id]&.game_pk != game_pk

        @games[channel.id] = GameChannel.new(self, game_pk, channel)
      end
    end
  end
end
