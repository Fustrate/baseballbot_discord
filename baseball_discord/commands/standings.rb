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
        STANDINGS = '/v1/standings/regularSeason?leagueId=103,104&season=%<year>d&t=%<t>d&date=%<date>s&hydrate=team'

        IGNORE_CHANNELS = [452550329700188160].freeze

        def run
          return react_to_message('🚫') if IGNORE_CHANNELS.include?(channel.id)

          team_name, date = parse_team_and_date

          division_id = find_division_id(team_name)

          return react_to_message('❓') unless division_id

          rows = standings_data(date, division_id)
            .sort_by { _1['divisionRank'] }
            .map { team_standings_data(_1) }

          standings_table(rows)
        end

        protected

        def standings_data(date, division_id)
          clamped_date = clamp_date_to_regular_season(date)

          load_data_from_stats_api(STANDINGS, date: clamped_date)['records']
            .find { _1.dig('division', 'id') == division_id }['teamRecords']
        end

        def find_division_id(team_name)
          team_id = BaseballDiscord::Utilities
            .find_team_by_name(team_name.empty? ? names_from_context : [team_name])

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

        def december_first(year) = Date.civil(year.to_i, 12, 1)

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
