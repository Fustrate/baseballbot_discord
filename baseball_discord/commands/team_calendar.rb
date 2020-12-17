# frozen_string_literal: true

module BaseballDiscord
  module Commands
    module TeamCalendar
      extend Discordrb::Commands::CommandContainer

      command(
        :next,
        description: 'Display the next N games for a team',
        usage: 'next [N=10] [team]'
      ) do |event, *args|
        TeamCalendarCommand.new(event, *args).list_games(:future)
      end

      command(
        :last,
        description: 'Display the last N games for a team',
        usage: 'last [N=10] [team]'
      ) do |event, *args|
        TeamCalendarCommand.new(event, *args).list_games(:past)
      end

      class TeamCalendarCommand < Command
        attr_reader :past_or_future

        SCHEDULE = '/v1/schedule?teamId=%<team_id>d&startDate=%<start_date>s&' \
                   'endDate=%<end_date>s&sportId=1&eventTypes=primary&scheduleTypes=games&' \
                   'hydrate=team(venue(timezone)),game(content(summary)),linescore,broadcasts(all)'

        PREGAME_STATUSES = /Preview|Warmup|Pre-Game|Delayed Start|Scheduled/.freeze
        POSTGAME_STATUSES = /Final|Game Over|Postponed|Completed Early/.freeze

        def list_games(past_or_future)
          @past_or_future = past_or_future

          determine_team_and_number

          return react_to_message('❓') unless @team_id

          glorious_table_of_games
        end

        protected

        def past?
          @past_or_future == :past
        end

        def future?
          @past_or_future == :future
        end

        def determine_team_and_number
          number, name = parse_input(raw_args)

          @team_id = BaseballDiscord::Utilities.find_team_by_name(
            name ? [name] : names_from_context
          )

          @number = number.clamp(1, 15)
        end

        def parse_input(input)
          case input
          when /\A(\d+)\s+(.+)\z/
            [Regexp.last_match[1].to_i, Regexp.last_match[2]]
          when /\A(\D+)\z/
            [10, Regexp.last_match[1]]
          when /\A(\d+)\z/
            [Regexp.last_match[1].to_i, nil]
          else
            [10, nil]
          end
        end

        def glorious_table_of_games
          start_date, end_date = calendar_dates

          data = load_data_from_stats_api(
            SCHEDULE,
            team_id: @team_id,
            start_date: start_date.strftime('%m/%d/%Y'),
            end_date: end_date.strftime('%m/%d/%Y')
          )

          games_table process_games(data)
        end

        # TODO: This doesn't work in the off season.
        def calendar_dates
          # Go two hours back because of late games
          now = Time.now - 7200

          # Account for up to 5 off days
          days = (past? ? -1 : 1) * (@number + 5)

          [now, now + days * 24 * 3600].sort
        end

        def games_table(games)
          return 'No games found.' if games.empty?

          table = Terminal::Table.new(
            rows: table_rows(games),
            headings: table_headings,
            title: games.first[:team]
          )

          table.align_column(0, :right)
          table.align_column(3, :right) if future?

          format_table table
        end

        def table_headings
          return ['Date', '', 'Team', 'Result'] if past?

          ['Date', '', 'Team', 'Time']
        end

        def table_rows(games)
          rows = []

          separate_games_into_series(games).each do |series|
            first_game = true

            series.each do |game|
              rows << game_row(game, first_game)

              first_game = false
            end

            rows << :separator
          end

          # The last row is a separator
          rows[0...-1]
        end

        def game_row(game, first_game)
          versus_or_at = game[:home] ? 'vs' : '@'

          [
            game[:date].strftime('%-m/%-d'),
            first_game ? versus_or_at : '',
            game[:opponent],
            past? ? game[:outcome] : game[:date].strftime('%-I:%M %p')
          ]
        end

        def separate_games_into_series(games)
          series = []
          last_series = nil

          games.map do |game|
            key = "#{game[:home] ? 'vs' : '@'} #{game[:opponent]}"

            series << [] unless key == last_series

            series.last << game

            last_series = key
          end

          series
        end

        def process_games(data)
          games = []

          properly_ordered_dates(data).each do |date|
            next unless date['totalGames'].positive?

            properly_ordered_games(date).each do |game|
              next unless include_game?(game)

              games << game_data(game)
            end

            break if games.length >= @number
          end

          games.first @number
        end

        def properly_ordered_dates(data)
          past? ? data['dates'].reverse : data['dates']
        end

        def properly_ordered_games(date)
          past? ? date['games'].reverse : date['games']
        end

        def include_game?(game)
          status = game.dig('status', 'abstractGameState')

          (past? ? POSTGAME_STATUSES : PREGAME_STATUSES).match?(status)
        end

        def game_data(game)
          home_team = game.dig('teams', 'home', 'team', 'id') == @team_id

          data = basic_data(game, home_team)

          if past?
            if game.dig('status', 'detailedState') == 'Postponed'
              data[:outcome] = 'PPD'
            else
              mark_winning_team(game, data, home_team)
            end
          end

          data
        end

        def mark_winning_team(game, data, home_team)
          our_score = game.dig('teams', (home_team ? 'home' : 'away'), 'score')
          opp_score = game.dig('teams', (home_team ? 'away' : 'home'), 'score')

          # This is stupid and I love it.
          indicator = 'TWL'[our_score <=> opp_score]

          data[:outcome] = "#{indicator} #{our_score}-#{opp_score}"
        end

        def basic_data(game, home_team)
          team_key, opp_key = home_team ? %w[home away] : %w[away home]

          {
            home: home_team,
            opponent: game.dig('teams', opp_key, 'team', 'teamName'),
            team: game.dig('teams', team_key, 'team', 'name'),
            date: game_date(game, game.dig('teams', team_key, 'team', 'venue'))
          }
        end

        # Always parse the time in the current team's time zone - fans want to
        # see *their* time zone, not always the home team's.
        def game_date(game, team_venue)
          BaseballDiscord::Utilities.parse_time(
            game['gameDate'],
            time_zone: team_venue.dig('timeZone', 'id')
          )
        end
      end
    end
  end
end
