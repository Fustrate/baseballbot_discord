# frozen_string_literal: true

module GameChatBot
  class Play
    include OutputHelpers

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

    def strikeout_or_walk_embed
      {
        title: "#{type} (#{count})",
        description: description,
        color: color
      }
    end

    def home_run_embed
      {
        title: "#{type} (#{count})",
        description: description,
        color: color,
        fields: home_run_fields
      }
    end

    def home_run_fields
      event = @play['playEvents'].last

      hit = event['hitData']

      [
        { name: 'Launch Angle', value: "#{hit['launchAngle']} deg", inline: true },
        { name: 'Launch Speed', value: "#{hit['launchSpeed']} mph", inline: true },
        { name: 'Distance', value: "#{hit['totalDistance']} feet", inline: true },
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
        color: color
      }
    end

    def color
      return '3a9910'.to_i(16) if @play.dig('about', 'isScoringPlay')

      return '991010'.to_i(16) if @play.dig('about', 'hasOut')

      '106499'.to_i(16)
    end
  end
end
