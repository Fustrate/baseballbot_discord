# frozen_string_literal: true

module BaseballDiscord
  module Commands
    module Scoreboard
      extend Discordrb::Commands::CommandContainer

      COMMAND = :scoreboard
      DESCRIPTION = 'Shows scores and stuff'
      USAGE = 'scoreboard [today|yesterday|tomorrow|Date]'

      command(COMMAND, description: DESCRIPTION, usage: USAGE) do |event, *args|
        ScoreboardCommand.run(event, *args)
      end

      class ScoreboardCommand < Command
        SCHEDULE = \
          'https://statsapi.mlb.com/api/v1/schedule?sportId=1&date=%<date>s&' \
          'hydrate=game(content(summary)),linescore,flags,team&t=%<t>d'

        PREGAME_STATUSES = [
          'Preview', 'Warmup', 'Pre-Game', 'Delayed Start', 'Scheduled'
        ].freeze

        POSTGAME_STATUSES = [
          'Final', 'Game Over', 'Postponed', 'Completed Early'
        ].freeze

        def run
          date = BaseballDiscord::Bot.parse_date(@args.join(' '))

          return react_to_message('❓') unless date

          data = load_data_from_stats_api(SCHEDULE, date: date)

          return react_to_message('👎') if data['totalGames'].zero?

          scores_table(data, date)
        end

        protected

        def scores_table(data, date)
          table = Terminal::Table.new(
            rows: scores_table_rows(data.dig('dates', 0, 'games')),
            title: date.strftime('%B %-d, %Y')
          )

          table.align_column(1, :right)
          table.align_column(4, :right)

          "```\n#{table}\n```"
        end

        def scores_table_rows(games)
          rows = []

          games.map { |game| process_game(game) }.each_slice(2) do |pair|
            append_game_rows(rows, pair)

            rows << :separator
          end

          # Remove the last separator
          rows.pop

          rows
        end

        def append_single_game_rows(rows, game)
          rows << [
            game[:away_name], game[:away_score], game[:status], '', '', ''
          ]

          rows << [
            game[:home_name], game[:home_score], '', '', '', ''
          ]
        end

        def append_game_rows(rows, games)
          return append_single_game_rows(rows, games[0]) if games.length == 1

          rows << [
            games[0][:away_name], games[0][:away_score], games[0][:status],
            games[1][:away_name], games[1][:away_score], games[1][:status]
          ]

          rows << [
            games[0][:home_name], games[0][:home_score], '',
            games[1][:home_name], games[1][:home_score], ''
          ]
        end

        def process_game(game)
          status = game.dig('status', 'abstractGameState')

          return future_game(game) if PREGAME_STATUSES.include?(status)

          {
            away_name: game.dig('teams', 'away', 'team', 'abbreviation'),
            away_score: game.dig('teams', 'away', 'score'),
            home_name: game.dig('teams', 'home', 'team', 'abbreviation'),
            home_score: game.dig('teams', 'home', 'score'),
            status: game_status(game)
          }
        end

        def future_game(game)
          {
            away_name: game.dig('teams', 'away', 'team', 'abbreviation'),
            away_score: '',
            home_name: game.dig('teams', 'home', 'team', 'abbreviation'),
            home_score: '',
            status: game_status(game)
          }
        end

        def game_status(game)
          status = game.dig('status', 'detailedState')

          case status
          when 'In Progress'   then game_inning game
          when 'Postponed'     then 'PPD'
          when 'Delayed Start' then delay_type game
          when 'Delayed'       then "#{delay_type game} #{game_inning game}"
          when 'Warmup'        then 'Warmup'
          else
            pre_or_post_game_status(game, status)
          end
        end

        def delay_type(game)
          game.dig('status', 'reason') == 'Rain' ? '☂' : 'Delay'
        end

        def game_inning(game)
          (game.dig('linescore', 'isTopInning') ? '▲' : '▼') +
            game.dig('linescore', 'currentInning').to_s
        end

        def pre_or_post_game_status(game, status)
          if POSTGAME_STATUSES.include?(status)
            innings = game.dig('linescore', 'currentInning')

            return innings == 9 ? 'F' : "F/#{innings}"
          end

          BaseballDiscord::Bot.parse_time(game['gameDate']).strftime('%-I:%M')
        end
      end
    end
  end
end
