# frozen_string_literal: true

module BaseballDiscord
  module Commands
    module Schedule
      def self.register(bot)
        bot.application_command(:next) { ScheduleCommand.new(it).list_games(:future) }
        bot.application_command(:last) { ScheduleCommand.new(it).list_games(:past) }
      end

      class ScheduleCommand < SlashCommand
        SCHEDULE = '/v1/schedule?teamId=%<team_id>d&startDate=%<start_date>s&endDate=%<end_date>s&sportId=1&' \
                   'hydrate=team(venue(timezone)),game(content(summary)),linescore,broadcasts(all)&' \
                   'eventTypes=primary&scheduleTypes=games'

        PREGAME_STATUSES = /Preview|Warmup|Pre-Game|Delayed Start|Scheduled/
        POSTGAME_STATUSES = /Final|Game Over|Postponed|Completed Early/

        IGNORE_CHANNELS = [452550329700188160].freeze

        def list_games(past_or_future)
          @past_or_future = past_or_future

          @team_id = determine_team

          return error_message('Could not determine a team...') unless @team_id

          @number = (options['amount'] || 10).clamp(1, 15)

          respond_with(content: glorious_table_of_games, ephemeral: IGNORE_CHANNELS.include?(channel.id))
        end

        protected

        def past? = (@past_or_future == :past)

        def determine_team
          BaseballDiscord::Utilities.find_team_by_name(options['team'] ? [options['team']] : names_from_context)
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

          [now, now + (days * 24 * 3600)].sort
        end

        def games_table(games)
          return 'No games found.' if games.empty?

          table = Terminal::Table.new(
            rows: table_rows(games),
            headings: ['Date', '', 'Team', past? ? 'Result' : 'Time'],
            title: games.first[:team],
            style: { border: :unicode }
          )

          table.align_column(0, :right)
          table.align_column(3, :right) unless past?

          format_table table
        end

        def table_rows(games)
          rows = []

          separate_games_into_series(games).each do |series|
            rows.concat(series.map.with_index { |game, index| game_row(game, index.zero?) }, [:separator])
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

          order = past? ? :reverse : :itself

          data['dates'].send(order).each do |date|
            next unless date['totalGames'].positive?

            games.concat(date['games'].send(order).filter_map { game_data(it) if include_game?(it) })

            break if games.length >= @number
          end

          games.first @number
        end

        def include_game?(game)
          (past? ? POSTGAME_STATUSES : PREGAME_STATUSES).match?(game.dig('status', 'abstractGameState'))
        end

        def game_data(game) = CalendarGame.new(game, @team_id, past?).to_h

        # Always parse the time in the current team's time zone - fans want to see *their* time zone, not always the
        # home team's.
        def game_date(game, team_venue)
          BaseballDiscord::Utilities.parse_time game['gameDate'], time_zone: team_venue.dig('timeZone', 'id')
        end
      end

      class CalendarGame
        attr_reader :game

        def initialize(game, team_id, past)
          @game = game
          @team_id = team_id
          @past = past

          @home = game.dig('teams', 'home', 'team', 'id') == team_id
        end

        def to_h
          basic_data.tap do |data|
            data[:outcome] = (game.dig('status', 'detailedState') == 'Postponed' ? 'PPD' : outcome) if @past
          end
        end

        protected

        def basic_data
          {
            home: @home,
            opponent: game.dig('teams', opp_key, 'team', 'teamName'),
            team: game.dig('teams', team_key, 'team', 'name'),
            date: game_date
          }
        end

        def outcome
          our_score = game.dig('teams', team_key, 'score')
          opp_score = game.dig('teams', opp_key, 'score')

          # This is stupid and I love it.
          "#{'TWL'[our_score <=> opp_score]} #{our_score}-#{opp_score}"
        end

        # Always parse the time in the current team's time zone - fans want to see *their* time zone, not always the
        # home team's.
        def game_date
          BaseballDiscord::Utilities.parse_time(
            game['gameDate'],
            time_zone: game.dig('teams', team_key, 'team', 'venue', 'timeZone', 'id')
          )
        end

        def team_key = (@home ? 'home' : 'away')

        def opp_key = (@home ? 'away' : 'home')
      end
    end
  end
end
