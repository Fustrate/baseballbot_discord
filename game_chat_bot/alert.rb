# frozen_string_literal: true

module GameChatBot
  class Alert
    include OutputHelpers

    def initialize(alert, game)
      @alert = alert
      @game = game
    end

    def embed
      case @alert['category']
      when 'end_of_half_inning' then end_of_inning_embed
      when 'game_over' then end_of_game_embed
      when 'pitcher_change' then pitcher_change_embed
      else
        basic_embed
      end
    end

    def end_of_inning_embed
      {
        title: @game.line_score.line_score_inning,
        color: '109799'.to_i(16),
        description: <<~DESCRIPTION
          Due Up:
          #{next_up.join("\n")}

          ```
          #{@game.line_score.rhe_table}
          ```
        DESCRIPTION
      }
    end

    def next_up
      @game.feed.live_data.dig('linescore', 'offense')
        .values_at('batter', 'onDeck', 'inHole')
        .map.with_index { |player, i| "#{i + 1}. #{player['fullName']}" }
    end

    def end_of_game_embed
      {
        title: 'Game Over',
        color: 'ffffff'.to_i(16),
        description: <<~DESCRIPTION
          #{description}

          ```
          #{@game.line_score.rhe_table}
          ```
        DESCRIPTION
      }
    end

    def pitcher_change_embed
      {
        title: 'Pitching Change',
        color: '109799'.to_i(16),
        description: description
      }
    end

    def basic_embed
      {
        title: titleize(@alert['category']),
        description: description,
        color: '109799'.to_i(16)
      }
    end

    def description
      # Get rid of the "In Los Angeles:" part that's in every description
      @alert['description'].gsub(/\Ain [a-z\. ]+: /i, '')
    end
  end
end
