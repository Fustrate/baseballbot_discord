# frozen_string_literal: true

module GameChatBot
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

    def initialize(play, game)
      @play = play
      @game = game
    end

    def embed
      case type
      when 'Walk', 'Strikeout' then strikeout_or_walk_embed
      when 'Home Run' then home_run_embed
      else
        basic_embed
      end
    end

    protected

    def type
      @type ||= @play.dig('result', 'event')
    end

    def description
      description = squish @play.dig('result', 'description')

      return description unless @play.dig('about', 'isScoringPlay')

      "#{description}\n\n```\n#{@game.line_score.rhe_table}\n```"
    end

    def count
      the_count = @play['count'].values_at('balls', 'strikes')

      # The API likes to show 4 balls or 3 strikes. HBP on what would be ball 4
      # also shows as Ball 4.
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
      offense = @game.feed.live_data&.dig('linescore', 'offense')

      return '' unless offense

      bitmap = 0b000
      bitmap |= 0b001 if offense['first']
      bitmap |= 0b010 if offense['second']
      bitmap |= 0b100 if offense['third']

      BASERUNNERS[bitmap]
    end

    def strikeout_or_walk_embed
      {
        title: "#{type} (#{count})",
        description: description,
        color: color,
        footer: resulting_context
      }
    end

    def home_run_embed
      {
        title: "#{type} (#{count})",
        description: description,
        color: color,
        fields: home_run_fields,
        footer: resulting_context
      }
    end

    def home_run_fields
      event = @play['playEvents'].last

      angle, speed, distance = event['hitData']
        .values_at 'launchAngle', 'launchSpeed', 'totalDistance'

      [
        { name: 'Launch Angle', value: "#{angle} deg", inline: true },
        { name: 'Launch Speed', value: "#{speed} mph", inline: true },
        { name: 'Distance', value: "#{distance} feet", inline: true },
        { name: 'Pitch', value: pitch_type(event), inline: true }
      ]
    end

    def pitch_type(event)
      speed = event.dig('pitchData', 'startSpeed')

      "#{speed} mph #{event.dig('details', 'type', 'description')}"
    end

    def basic_embed
      {
        title: "#{type} (#{count})",
        description: description,
        color: color,
        footer: resulting_context
      }
    end

    def color
      return '3a9910'.to_i(16) if @play.dig('about', 'isScoringPlay')

      return '991010'.to_i(16) if @play.dig('about', 'hasOut')

      '106499'.to_i(16)
    end
  end
end
