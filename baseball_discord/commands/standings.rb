# frozen_string_literal: true

module BaseballDiscord
  module Commands
    module Standings
      def self.register(bot)
        bot.application_command(:standings) { StandingsCommand.new(_1).run }
      end

      class StandingsCommand < SlashCommand
        STANDINGS = '/v1/standings/regularSeason?leagueId=103,104&season=%<year>d&t=%<t>d&date=%<date>s&hydrate=team'

        IGNORE_CHANNELS = [452550329700188160].freeze

        def run
          date = parse_date
          division_id = find_division_id

          return error_message('Could not determine a division to show.') unless division_id

          rows = standings_data(date, division_id)
            .sort_by { _1['divisionRank'] }
            .map { team_standings_data(_1) }

          respond_with content: standings_table(rows), ephemeral: IGNORE_CHANNELS.include?(channel.id)
        end

        protected

        def standings_data(date, division_id)
          clamped_date = clamp_date_to_regular_season(date)

          load_data_from_stats_api(STANDINGS, date: clamped_date)['records']
            .find { _1.dig('division', 'id') == division_id }['teamRecords']
        end

        def find_division_id
          input = Array(options['team']&.downcase || bot.config.dig(server.id, 'default_team') || names_from_context)

          team_id = BaseballDiscord::Utilities.find_team_by_name(input)

          BaseballDiscord::Utilities.division_for_team(team_id) if team_id
        end

        def parse_date = BaseballDiscord::Utilities.parse_date(options['date']&.strip)

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
          table = Terminal::Table.new(
            rows:,
            headings: %w[Team W L GB % rDiff STRK],
            style: { border: :unicode }
          )

          table.align_column(1, :right)
          table.align_column(2, :right)
          table.align_column(3, :right)
          table.align_column(5, :right)

          format_table table
        end

        def clamp_date_to_regular_season(date)
          formatted = date.strftime('%F')

          data = load_data_from_stats_api(
            '/v1/seasons?sportId=1&season=%<season>d',
            season: date.year
          )

          end_date = data.dig('seasons', 0, 'regularSeasonEndDate')
          start_date = data.dig('seasons', 0, 'regularSeasonStartDate')

          return Time.parse(end_date) if formatted > end_date
          return Time.parse(start_date) if formatted < start_date

          date
        end
      end
    end
  end
end
