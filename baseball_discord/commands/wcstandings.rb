# frozen_string_literal: true

module BaseballDiscord
  module Commands
    module WCStandings
      def self.register(bot)
        bot.application_command(:wcstandings) { WCStandingsCommand.new(_1).run }
      end

      class WCStandingsCommand < SlashCommand
        STANDINGS = '/v1/standings/regularSeason?leagueId=103,104&season=%<year>d&t=%<t>d&date=%<date>s&hydrate=team'

        TABLE_HEADERS = %w[Team W L GB % rDiff STRK].freeze

        IGNORE_CHANNELS = [452550329700188160].freeze

        def run
          league_id = find_league_id

          unless league_id
            return error_message('Could not determine league - please use "/wcstandings AL" or "/wcstandings NL"')
          end

          date = parse_date

          leaders, others = leaders_and_others(date, league_id)

          respond_with content: standings_table(leaders, others), ephemeral: IGNORE_CHANNELS.include?(channel.id)
        end

        protected

        def leaders_and_others(date, league_id)
          load_data_from_stats_api(STANDINGS, date:)['records']
            .select { _1.dig('league', 'id') == league_id }
            .flat_map { _1['teamRecords'] }
            .sort_by { _1['wildCardRank'].to_i }
            .partition { _1['divisionRank'] == '1' }
        end

        def find_league_id
          case options['league']&.upcase
          when 'AL' then 103
          when 'NL' then 104
          else
            default = bot.config.dig(server.id, 'default_team')

            team_id = BaseballDiscord::Utilities.find_team_by_name(default.empty? ? names_from_context : [default])

            BaseballDiscord::Utilities.league_for_team(team_id) if team_id
          end
        end

        def parse_date = BaseballDiscord::Utilities.parse_date(options['date']&.strip)

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
          leader_rows = leaders.map { team_standings_data(_1) }
          other_rows = others.map { team_standings_data(_1) }

          table = Terminal::Table.new(
            rows: (leader_rows + [:separator] + other_rows),
            headings: TABLE_HEADERS,
            style: { border: :unicode }
          )

          %i[left right right right left right].each.with_index { |alignment, n| table.align_column(n, alignment) }

          format_table table
        end
      end
    end
  end
end
