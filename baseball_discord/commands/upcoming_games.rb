# frozen_string_literal: true

module BaseballDiscord
  module Commands
    module UpcomingGames
      extend Discordrb::Commands::CommandContainer

      COMMAND = :next
      DESCRIPTION = 'Display the next N games for a team'
      USAGE = 'next [N=10] [team]'

      command(COMMAND, description: DESCRIPTION, usage: USAGE) do |event, *args|
        UpcomingGamesCommand.new(event, *args).run
      end

      class UpcomingGamesCommand < Command
        SCHEDULE = \
          'http://statsapi.mlb.com/api/v1/schedule?teamId=%<team_id>d&' \
          'startDate=%<start_date>s&endDate=%<end_date>s&sportId=1&' \
          'eventTypes=primary&scheduleTypes=games&hydrate=team' \
          '(venue(timezone)),game(content(summary)),linescore,broadcasts(all)'

        PREGAME_STATUSES = [
          'Preview', 'Warmup', 'Pre-Game', 'Delayed Start', 'Scheduled'
        ].freeze

        def run
          number, name = parse_upcoming_games_input(args.join(' ').strip)

          team_id = BaseballDiscord::Utilities.find_team_by_name(
            name ? [name.downcase] : names_from_context
          )

          return react_to_message('❓') unless team_id

          upcoming_games_data team_id, number.clamp(1, 15)
        end

        def parse_upcoming_games_input(input)
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

        def upcoming_games_data(team_id, number)
          start_date = Time.now - 7200
          end_date = start_date + (number + 5) * 24 * 3600

          data = load_data_from_stats_api(
            SCHEDULE,
            team_id: team_id,
            start_date: start_date.strftime('%m/%d/%Y'),
            end_date: end_date.strftime('%m/%d/%Y')
          )

          upcoming_games_table extract_upcoming_games(data, team_id, number)
        end

        def upcoming_games_table(games)
          table = Terminal::Table.new(
            rows: upcoming_games_table_rows(games),
            headings: ['Date', '', 'Team', 'Time'],
            title: games.first[:team]
          )

          table.align_column(0, :right)
          table.align_column(3, :right)

          "```\n#{table}\n```"
        end

        def upcoming_games_table_rows(games)
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
            game[:date].strftime('%-I:%M %p')
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

        def extract_upcoming_games(data, team_id, number)
          games = []

          data['dates'].each do |date|
            next unless date['totalGames'].positive?

            date['games'].each do |game|
              status = game.dig('status', 'abstractGameState')

              next unless PREGAME_STATUSES.include?(status)

              games << upcoming_game_data(game, team_id)
            end
          end

          games.first(number)
        end

        def upcoming_game_data(game, team_id)
          home_team = game.dig('teams', 'home', 'team', 'id') == team_id

          team = game.dig('teams', (home_team ? 'home' : 'away'))
          opponent = game.dig('teams', (home_team ? 'away' : 'home'))

          {
            home: home_team,
            opponent: opponent.dig('team', 'teamName'),
            team: team.dig('team', 'name'),
            date: BaseballDiscord::Utilities.parse_time(
              game['gameDate'],
              time_zone: team.dig('team', 'venue', 'timeZone', 'id')
            )
          }
        end
      end
    end
  end
end
