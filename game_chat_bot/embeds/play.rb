# frozen_string_literal: true

module GameChatBot
  module Embeds
    class Play
      include OutputHelpers

      BASERUNNERS = [
        'bases empty',
        'runner on first',
        'runner on second',
        'first and second',
        'runner on third',
        'first and third',
        'second and third',
        'bases loaded'
      ].freeze

      def initialize(play, channel)
        @play = play
        @channel = channel
      end

      def to_h
        {
          title: "#{team_emoji} #{type} (#{count})",
          description: description,
          color: color,
          footer: resulting_context
        }
      end

      def post_at
        Time.parse(@play['playEndTime']) + 15
      end

      def color
        return '3a9910'.to_i(16) if @play.dig('about', 'isScoringPlay')

        return '991010'.to_i(16) if @play.dig('about', 'hasOut')

        '106499'.to_i(16)
      end

      def team_flag
        @play.dig('about', 'halfInning') == 'top' ? 'away' : 'home'
      end

      def team_abbreviation
        @channel.feed.game_data.dig('teams', team_flag, 'abbreviation')
      end

      def team_emoji
        GameChatBot::Emoji.team_emoji(team_abbreviation)
      end

      def type
        @type ||= @play.dig('result', 'event')
      end

      def description
        description = squish @play.dig('result', 'description')

        return description unless @play.dig('about', 'isScoringPlay')

        "#{description}\n\n```\n#{@channel.rhe_table}\n```"
      end

      def count
        the_count = @play['count'].values_at('balls', 'strikes')

        # The API likes to show 4 balls or 3 strikes. HBP on a 3-ball count also
        # shows as Ball 4.
        the_count[0] = 3 if type == 'Walk' || the_count[0] == 4
        the_count[1] = 2 if type == 'Strikeout' || the_count[1] == 3

        the_count.join('-')
      end

      def pitcher
        "#{@play.dig('matchup', 'pitchHand', 'code')}HP " +
          @play.dig('matchup', 'pitcher', 'fullName')
      end

      def resulting_context
        outs = @play.dig('count', 'outs')

        text = [
          "#{outs} #{outs == 1 ? 'Out' : 'Outs'}",
          (runners unless outs == 3),
          pitcher
        ].compact.join('  |  ')

        { text: text }
      end

      def runners
        offense = @channel.feed.live_data&.dig('linescore', 'offense')

        return '' unless offense

        bitmap = 0b000
        bitmap |= 0b001 if offense['first']
        bitmap |= 0b010 if offense['second']
        bitmap |= 0b100 if offense['third']

        BASERUNNERS[bitmap]
      end
    end
  end
end
