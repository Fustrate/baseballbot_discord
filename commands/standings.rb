# frozen_string_literal: true

class BaseballDiscordBot
  module Commands
    module Standings
      STATS_STANDINGS = \
        'https://statsapi.mlb.com/api/v1/standings/regularSeason?' \
        'leagueId=103,104&season=%<year>d&t=%<t>d&date=%<date>s'

      DIVISIONS = {
        200 => ['alw', 'alwest'],
        201 => ['ale', 'aleast'],
        202 => ['alc', 'alcentral'],
        203 => ['nlw', 'nlwest'],
        204 => ['nle', 'nleast'],
        205 => ['nlc', 'nlcentral']
      }

      def self.add_to(discord_bot, baseballbot)
        discord_bot.command(
          :standings,
          min_args: 1,
          description: 'Displays the standings for a division',
          usage: 'standings [division]'
        ) do |event, *args|
          baseballbot.standings(event, *args)
        end
      end

      def standings(_event, *args)
        division_id, date = parse_standings_args(args)

        return react_to_event(event, "\u274c") unless division_id

        rows = load_data_from_stats_api(STATS_STANDINGS, date: date)
          .dig('records')
          .find { |record| record.dig('division' ,'id') == division_id }
          .dig('teamRecords')
          .sort_by { |team| team['divisionRank'] }
          .map { |team| team_standings_data(team) }

        standings_table(rows)
      end

      protected

      # This should be expanded upon to allow for more date formats
      def parse_standings_args(args)
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
        rDiffSign = team['runDifferential'].negative? ? '' : '+'

        [
          team.dig('team', 'name'),
          team['wins'],
          team['losses'],
          team['gamesBack'],
          team.dig('leagueRecord', 'pct'),
          "#{rDiffSign}#{team['runDifferential']}",
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
        DIVISIONS.find { |key, value| value.include?(input) }&.first
      end
    end
  end
end
