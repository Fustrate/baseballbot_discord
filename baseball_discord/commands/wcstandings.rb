# frozen_string_literal: true

module BaseballDiscord
  module Commands
    module WCStandings
      extend Discordrb::Commands::CommandContainer

      COMMAND = :wcstandings
      DESCRIPTION = 'Displays the wildcard standings for a team'
      USAGE = 'wcstandings [team]'

      command(
        COMMAND,
        description: DESCRIPTION,
        usage: USAGE
      ) do |event, *args|
        WCStandingsCommand.new(event, *args).run
      end

      class WCStandingsCommand < Command
        STATS_STANDINGS = \
          'https://statsapi.mlb.com/api/v1/standings/regularSeason?' \
          'leagueId=103,104&season=%<year>d&t=%<t>d&date=%<date>s'

        def run
          team_name, date = parse_team_and_date

          league_id = find_league_id(team_name)

          return react_to_message('❓') unless league_id

          rows = standings_data(date, league_id)
            .sort_by { |team| team['wildCardRank'].to_i }
            .map { |team| team_standings_data(team) }

          standings_table(rows)
        end

        protected

        def standings_data(date, league_id)
          load_data_from_stats_api(STATS_STANDINGS, date: date)
            .dig('records')
            .select { |division| division.dig('league', 'id') == league_id }
            .flat_map { |division| division['teamRecords'] }
        end

        def find_league_id(team_name)
          team_id = BaseballDiscord::Utilities.find_team_by_name(
            team_name.empty? ? names_from_context : [team_name]
          )

          return unless team_id

          BaseballDiscord::Utilities.league_for_team(team_id)
        end

        # This should be expanded upon to allow for more date formats
        def parse_team_and_date
          input = args.join(' ').downcase

          if input.empty?
            input = bot.config.dig(server.id, 'default_team') || ''
          end

          case input
          when /\A(.*)\s*(\d{4})\z/
            team_name = Regexp.last_match[1].strip
            date = Date.civil(Regexp.last_match[2].to_i, 12, 1)
          when /\A\d{4}\z/
            team_name = nil
            date = Date.civil(input.to_i, 12, 1)
          else
            team_name = input
            date = Time.now
          end

          [team_name, date]
        end

        def team_standings_data(team)
          r_diff_sign = team['runDifferential'].negative? ? '' : '+'

          [
            team.dig('team', 'name'),
            team['wins'],
            team['losses'],
            team['wildCardGamesBack'],
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
      end
    end
  end
end
