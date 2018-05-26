# frozen_string_literal: true

module BaseballDiscord
  module Commands
    module Standings
      extend Discordrb::Commands::CommandContainer

      COMMAND = :standings
      DESCRIPTION = 'Displays the standings for a division'
      USAGE = 'standings [division]'

      command(
        COMMAND,
        min_args: 1,
        description: DESCRIPTION,
        usage: USAGE
      ) do |event, *args|
        StandingsCommand.new(event, *args).run
      end

      class StandingsCommand < Command
        STATS_STANDINGS = \
          'https://statsapi.mlb.com/api/v1/standings/regularSeason?' \
          'leagueId=103,104&season=%<year>d&t=%<t>d&date=%<date>s'

        DIVISIONS = {
          200 => %w[alw alwest],
          201 => %w[ale aleast],
          202 => %w[alc alcentral],
          203 => %w[nlw nlwest],
          204 => %w[nle nleast],
          205 => %w[nlc nlcentral]
        }.freeze

        def run
          division_id, date = parse_standings_args

          return react_to_message('❓') unless division_id

          rows = load_data_from_stats_api(STATS_STANDINGS, date: date)
            .dig('records')
            .find { |record| record.dig('division', 'id') == division_id }
            .dig('teamRecords')
            .sort_by { |team| team['divisionRank'] }
            .map { |team| team_standings_data(team) }

          standings_table(rows)
        end

        protected

        # This should be expanded upon to allow for more date formats
        def parse_standings_args
          input = args.join('').downcase

          if input =~ /\A([a-z]+)(\d{4})\z/
            division_id = find_division(Regexp.last_match[1])
            date = DateTime.civil(Regexp.last_match[2].to_i, 12, 1)
          else
            division_id = find_division(input)
            date = Time.now
          end

          [division_id, date]
        end

        def team_standings_data(team)
          r_diff_sign = team['runDifferential'].negative? ? '' : '+'

          [
            team.dig('team', 'name'),
            team['wins'],
            team['losses'],
            team['gamesBack'],
            team.dig('leagueRecord', 'pct'),
            "#{r_diff_sign}#{team['runDifferential']}",
            team.dig('streak', 'streakCode')
          ]
        end

        def standings_table(rows)
          table = Terminal::Table.new(
            rows: rows,
            headings: %w[Team W L GB % rDiff STRK]
          )

          table.align_column(1, :right)
          table.align_column(2, :right)
          table.align_column(3, :right)
          table.align_column(5, :right)

          "```\n#{table}\n```"
        end

        def find_division(input)
          DIVISIONS.find { |_, value| value.include?(input) }&.first
        end
      end
    end
  end
end
