# frozen_string_literal: true

module BaseballDiscord
  module Commands
    module Standings
      extend Discordrb::Commands::CommandContainer

      command(
        :standings,
        description: 'Displays the division standings for a team',
        usage: 'standings [team]'
      ) do |event, *args|
        StandingsCommand.new(event, *args).run
      end

      class StandingsCommand < Command
        STATS_STANDINGS = \
          'https://statsapi.mlb.com/api/v1/standings/regularSeason?' \
          'leagueId=103,104&season=%<year>d&t=%<t>d&date=%<date>s&hydrate=team'

        def run
          team_name, date = parse_team_and_date

          division_id = find_division_id(team_name)

          return react_to_message('❓') unless division_id

          rows = standings_data(date, division_id)
            .sort_by { |team| team['divisionRank'] }
            .map { |team| team_standings_data(team) }

          standings_table(rows)
        end

        protected

        def standings_data(date, division_id)
          load_data_from_stats_api(STATS_STANDINGS, date: date)['records']
            .find { |record| record.dig('division', 'id') == division_id }['teamRecords']
        end

        def find_division_id(team_name)
          team_id = BaseballDiscord::Utilities.find_team_by_name(
            team_name.empty? ? names_from_context : [team_name]
          )

          return unless team_id

          BaseballDiscord::Utilities.division_for_team(team_id)
        end

        # This should be expanded upon to allow for more date formats
        def parse_team_and_date
          input = input_or_default_team

          case input
          when /\A(.*)\s*(\d{4})\z/
            [Regexp.last_match[1].strip, december_first(Regexp.last_match[2])]
          when /\A\d{4}\z/
            [nil, december_first(input)]
          else
            [input, Time.now]
          end
        end

        def input_or_default_team
          input = raw_args.downcase

          return bot.config.dig(server.id, 'default_team') || '' if input.empty?

          input
        end

        def december_first(year)
          Date.civil(year.to_i, 12, 1)
        end

        def team_standings_data(team)
          r_diff_sign = team['runDifferential'].negative? ? '' : '+'

          [
            team.dig('team', 'teamName'),
            team['wins'],
            team['losses'],
            team['gamesBack'],
            team.dig('leagueRecord', 'pct'),
            "#{r_diff_sign}#{team['runDifferential']}",
            team.dig('streak', 'streakCode')
          ]
        end

        def standings_table(rows)
          table = Terminal::Table.new rows: rows, headings: %w[Team W L GB % rDiff STRK]

          table.align_column(1, :right)
          table.align_column(2, :right)
          table.align_column(3, :right)
          table.align_column(5, :right)

          format_table table
        end
      end
    end
  end
end
