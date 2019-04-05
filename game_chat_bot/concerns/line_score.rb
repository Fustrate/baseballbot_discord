# frozen_string_literal: true

module GameChatBot
  module LineScore
    PREGAME_STATUSES = /Preview|Pre-Game|Warmup|Delayed Start|Scheduled/.freeze
    POSTGAME_STATUSES = /Final|Game Over|Postponed|Completed Early/.freeze

    TIMEZONES = {
      ET: 'America/New_York',
      CT: 'America/Chicago',
      MT: 'America/Denver',
      PT: 'America/Los_Angeles'
    }.freeze

    def line_score
      rows = base_line_score

      @feed.linescore['innings'].each do |inning|
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
      format(
        '%<side>s of the %<inning>s',
        side: @feed.linescore['inningState'],
        inning: @feed.linescore['currentInningOrdinal']
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
      return game_start_times unless game_started?
      return innings == 9 ? 'Final' : "Final/#{innings}" if game_over?

      inning_state = @feed.linescore['inningState']

      return line_score_inning unless %w[Top Bottom].include?(inning_state)

      "#{line_score_outs}, #{line_score_inning}"
    end

    def game_start_times
      utc = Time.parse @feed.game_data.dig('datetime', 'dateTime')

      TIMEZONES.map do |code, identifier|
        time = time_in_time_zone(utc, TZInfo::Timezone.get(identifier))

        "#{time.strftime('%-I:%M')} #{code}"
      end.join(' | ')
    end

    def time_in_time_zone(utc, time_zone)
      period = time_zone.period_for_utc(utc)
      with_offset = utc + period.utc_total_offset

      Time.parse "#{with_offset.strftime('%FT%T')} #{period.zone_identifier}"
    end

    def line_score_outs
      outs = @feed.linescore['outs']

      outs == 1 ? '1 Out' : "#{outs} Outs"
    end

    def line_score_block
      <<~LINESCORE
        #{@line_score.line_score_state}

        ```#{@line_score.line_score}```
      LINESCORE
    end

    protected

    def innings
      [@feed.linescore['innings'].count, 9].max
    end

    def team_rhe(flag)
      @feed.linescore.dig('teams', flag).values_at('runs', 'hits', 'errors')
    end

    def team_name(flag)
      @feed.game_data.dig('teams', flag, 'abbreviation')
    end

    def game_over?
      POSTGAME_STATUSES
        .match?(@feed.game_data.dig('status', 'abstractGameState'))
    end

    def game_started?
      !PREGAME_STATUSES
        .match?(@feed.game_data.dig('status', 'abstractGameState'))
    end
  end
end
