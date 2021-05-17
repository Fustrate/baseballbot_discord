# frozen_string_literal: true

module BaseballDiscord
  module Commands
    module Scoreboard
      extend Discordrb::Commands::CommandContainer

      command(
        :scores,
        description: 'Shows scores and stuff',
        usage: 'scores [today|yesterday|tomorrow|Date]',
        aliases: %i[scoreboard]
      ) do |event, *args|
        ScoreboardCommand.new(event, *args).run
      end

      class ScoreboardCommand < Command
        SCHEDULE = '/v1/schedule?sportId=1&date=%<date>s&t=%<t>d&hydrate=game(content(summary)),linescore,flags,team'

        PREGAME_STATUSES = /Preview|Warmup|Pre-Game|Delayed Start|Scheduled/
        POSTGAME_STATUSES = /Final|Game Over|Postponed|Completed Early/

        IGNORE_CHANNELS = [452550329700188160].freeze

        def run
          return react_to_message('🚫') if IGNORE_CHANNELS.include?(channel.id)

          date = BaseballDiscord::Utilities.parse_date raw_args

          return react_to_message('❓') unless date

          data = load_data_from_stats_api(SCHEDULE, date: date)

          return react_to_message('👎') if data['totalGames'].zero?

          scores_table(data, date)
        end

        protected

        def scores_table(data, date)
          table = Terminal::Table.new(
            rows: scores_table_rows(data.dig('dates', 0, 'games')),
            title: date.strftime('%B %-d, %Y'),
            style: { border: :unicode }
          )

          table.align_column(1, :right)
          table.align_column(4, :right)

          format_table table
        end

        def scores_table_rows(games)
          rows = []

          games.map { |game| process_game(game) }.each_slice(2) do |pair|
            append_game_rows(rows, pair)

            rows << :separator
          end

          # Remove the last separator
          rows[0...-1]
        end

        def append_game_rows(rows, games)
          first_game = game_rows(games[0])
          second_game = game_rows(games[1])

          rows << (first_game[0] + second_game[0])
          rows << (first_game[1] + second_game[1])
        end

        def game_rows(game)
          return [['', '', ''], ['', '', '']] unless game

          [
            [game[:away_name], game[:away_score], game[:status]],
            [game[:home_name], game[:home_score], '']
          ]
        end

        def process_game(game)
          status = game.dig('status', 'abstractGameState')

          return future_game(game) if PREGAME_STATUSES.match?(status)

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

        def linescore(game) = game['linescore']

        def delay_type(game) = (game.dig('status', 'reason') == 'Rain' ? '☂' : 'Delay')

        def game_inning(game) = "#{top_of_inning?(game) ? '▲' : '▼'} #{game.dig('linescore', 'currentInning')}"

        def top_of_inning?(game) = game.dig('linescore', 'isTopInning')

        def pre_or_post_game_status(game, status)
          if POSTGAME_STATUSES.match?(status)
            innings = game.dig('linescore', 'currentInning')

            return innings == 9 ? 'F' : "F/#{innings}"
          end

          BaseballDiscord::Utilities.parse_time(game['gameDate']).strftime('%-I:%M')
        end
      end
    end
  end
end
