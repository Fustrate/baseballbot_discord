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
          title: "#{team_emoji} #{@play.dig('result', 'event')} (#{count})",
          description: description,
          color: color.to_i(16),
          footer: resulting_context
        }
      end

      def post_at() = (Time.parse(@play['playEndTime']) + 15)

      def color
        return '3a9910' if @play.dig('about', 'isScoringPlay')

        return '991010' if @play.dig('about', 'hasOut')

        '106499'
      end

      def team_flag() = @play.dig('about', 'halfInning') == 'top' ? 'away' : 'home'

      def team_abbreviation() = @channel.feed.game_data.dig('teams', team_flag, 'abbreviation')

      def team_emoji() = GameChatBot::Emoji.team_emoji(team_abbreviation)

      def description
        description = squish @play.dig('result', 'description')

        return description unless @play.dig('about', 'isScoringPlay')

        "#{description}\n\n```\n#{@channel.rhe_table}\n```"
      end

      def count
        the_count = @play['count'].values_at('balls', 'strikes')

        # The API likes to show 4 balls or 3 strikes. HBP on a 3-ball count also shows as Ball 4.
        "#{the_count[0].clamp(0, 3)}-#{the_count[1].clamp(0, 2)}"
      end

      def resulting_context
        outs = @play.dig('count', 'outs')

        text = [
          "#{outs} #{outs == 1 ? 'Out' : 'Outs'}",
          (runners unless outs == 3),
          "#{@play.dig('matchup', 'pitchHand', 'code')}HP #{@play.dig('matchup', 'pitcher', 'fullName')}"
        ].compact.join('  |  ')

        { text: text }
      end

      def runners
        offense = @channel.feed.linescore&.dig('offense')

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
