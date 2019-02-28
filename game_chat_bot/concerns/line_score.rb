# frozen_string_literal: true

module GameChatBot
  module LineScore
    POSTGAME_STATUSES = /Final|Game Over|Postponed|Completed Early/.freeze

    def line_score
      rows = base_line_score

      @feed.live_data.dig('linescore', 'innings').each do |inning|
        rows[2][inning['num']] = inning.dig('away', 'runs')
        rows[3][inning['num']] = inning.dig('home', 'runs')
      end

      prettify_table Terminal::Table.new(rows: rows)
    end

    def base_line_score
      [
        [''] + (1..innings).to_a + %w[R H E],
        :separator,
        team_line_score(away_team_name, innings, away_rhe),
        team_line_score(home_team_name, innings, home_rhe)
      ]
    end

    def team_line_score(name, innings, rhe)
      [name] + [''] * innings + rhe
    end

    def line_score_inning
      linescore = @feed.live_data['linescore']

      format(
        '%<side>s of the %<inning>s',
        side: linescore['inningState'],
        inning: linescore['currentInningOrdinal']
      )
    end

    def rhe_table
      prettify_table Terminal::Table.new(
        rows: [
          ['', 'R', 'H', 'E'],
          :separator,
          [team_name('away')] + team_rhe('away'),
          [team_name('home')] + team_rhe('home')
        ]
      )
    end

    def line_score_state
      return innings == 9 ? 'Final' : "Final/#{innings}" if game_over?

      str = line_score_inning

      linescore = @feed.live_data['linescore']

      if %w[Top Bottom].include?(linescore['inningState'])
        outs = linescore['outs'] == 1 ? '1 Out' : "#{linescore['outs']} Outs"

        str = "#{outs}, #{str}"
      end

      str
    end

    def line_score_block
      <<~LINESCORE
        #{@line_score.line_score_state}

        ```#{@line_score.line_score}```
      LINESCORE
    end

    protected

    def innings
      [@feed.live_data.dig('linescore', 'innings').count, 9].max
    end

    def team_rhe(flag)
      @feed.live_data.dig('linescore', 'teams', flag)
        .values_at('runs', 'hits', 'errors')
    end

    def team_name(flag)
      @feed.game_data.dig('teams', flag, 'abbreviation')
    end

    def game_over?
      POSTGAME_STATUSES
        .match?(@feed.game_data.dig('status', 'abstractGameState'))
    end
  end
end
