# frozen_string_literal: true

module BaseballDiscord
  module Commands
    module WCStandings
      extend Discordrb::Commands::CommandContainer

      command(
        :wcstandings,
        description: 'Displays the wildcard standings for a team',
        usage: 'wcstandings [team]',
        aliases: %i[wildcard]
      ) do |event, *args|
        WCStandingsCommand.new(event, *args).run
      end

      class WCStandingsCommand < Command
        STANDINGS = '/v1/standings/regularSeason?leagueId=103,104&season=%<year>d&t=%<t>d&date=%<date>s&hydrate=team'

        TABLE_HEADERS = %w[Team W L GB % rDiff STRK].freeze

        IGNORE_CHANNELS = [452550329700188160].freeze

        def run
          return react_to_message('🚫') if IGNORE_CHANNELS.include?(channel.id)

          team_name, date = parse_team_and_date

          league_id = find_league_id(team_name)

          return react_to_message('❓') unless league_id

          leaders, others = standings_data(date, league_id)
            .sort_by { |team| team['wildCardRank'].to_i }
            .partition { |team| team['divisionRank'] == '1' }

          standings_table(leaders, others)
        end

        protected

        def standings_data(date, league_id)
          load_data_from_stats_api(STANDINGS, date: date)['records']
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
            team['wildCardGamesBack'],
            team.dig('leagueRecord', 'pct'),
            "#{r_diff_sign}#{team['runDifferential']}",
            team.dig('streak', 'streakCode')
          ]
        end

        def standings_table(leaders, others)
          leader_rows = leaders.map { |team| team_standings_data(team) }
          other_rows = others.map { |team| team_standings_data(team) }

          table = Terminal::Table.new(
            rows: (leader_rows + [:separator] + other_rows),
            headings: TABLE_HEADERS,
            style: { border: :unicode }
          )

          align_standings_table_columns(table)

          format_table table
        end

        def align_standings_table_columns(table)
          table.align_column(1, :right)
          table.align_column(2, :right)
          table.align_column(3, :right)
          table.align_column(5, :right)
        end
      end
    end
  end
end
