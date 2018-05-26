# frozen_string_literal: true

module BaseballDiscord
  module Commands
    module NextTen
      extend Discordrb::Commands::CommandContainer

      COMMAND = :next
      DESCRIPTION = 'Display the next N games for a team'
      USAGE = 'next [N=10] [team]'

      command(COMMAND, description: DESCRIPTION, usage: USAGE) do |event, *args|
        NextTenCommand.run(event, *args)
      end

      class NextTenCommand < Command
        SCHEDULE = \
          'http://statsapi.mlb.com/api/v1/schedule?teamId=%<team_id>d&' \
          'startDate=%<start_date>s&endDate=%<end_date>s&sportId=1&' \
          'eventTypes=primary&scheduleTypes=games&hydrate=team' \
          '(venue(timezone)),game(content(summary)),linescore,broadcasts(all)'

        PREGAME_STATUSES = [
          'Preview', 'Warmup', 'Pre-Game', 'Delayed Start', 'Scheduled'
        ].freeze

        def run
          input = args.join(' ').strip

          $stdout << "[Command] !next #{input}"

          number, name = parse_upcoming_games_input(input)

          potential_names = name ? [name.downcase] : names_from_context

          team_id = find_team_by_name(potential_names)

          return react_to_message('❓') unless team_id

          number = (number || 10).clamp 1, 15

          next_ten_data(team_id, number)
        end

        def parse_upcoming_games_input(input)
          case input
          when /\A(\d+)\s+(.+)\z/
            [Regexp.last_match[1].to_i, Regexp.last_match[2]]
          when /\A(\D+)\z/
            [10, Regexp.last_match[1]]
          when /\A(\d+)\z/
            [Regexp.last_match[1].to_i, nil]
          else
            [10, nil]
          end
        end

        def next_ten_data(team_id, number)
          start_date = Time.now - 7200
          end_date = start_date + (number + 5) * 24 * 3600

          data = load_data_from_stats_api(
            SCHEDULE,
            team_id: team_id,
            start_date: start_date.strftime('%m/%d/%Y'),
            end_date: end_date.strftime('%m/%d/%Y')
          )

          upcoming_games_table extract_next_ten_games(data, team_id, number)
        end

        def upcoming_games_table(games)
          table = Terminal::Table.new(
            rows: upcoming_games_table_rows(games),
            headings: ['Date', '', 'Team', 'Time'],
            title: games.first[:team]
          )

          table.align_column(0, :right)
          table.align_column(3, :right)

          "```\n#{table}\n```"
        end

        def upcoming_games_table_rows(games)
          rows = []

          separate_games_into_series(games).each do |series|
            first_game = true

            series.each do |game|
              rows << game_row(game, first_game)

              first_game = false
            end

            rows << :separator
          end

          # The last row is a separator
          rows[0...-1]
        end

        def game_row(game, first_game)
          versus_or_at = game[:home] ? 'vs' : '@'

          [
            game[:date].strftime('%-m/%-d'),
            first_game ? versus_or_at : '',
            game[:opponent],
            game[:date].strftime('%-I:%M %p')
          ]
        end

        def separate_games_into_series(games)
          series = []
          last_series = nil

          games.map do |game|
            key = "#{game[:home] ? 'vs' : '@'} #{game[:opponent]}"

            series << [] unless key == last_series

            series.last << game

            last_series = key
          end

          series
        end

        def extract_next_ten_games(data, team_id, number)
          games = []

          data['dates'].each do |date|
            next unless date['totalGames'].positive?

            date['games'].each do |game|
              status = game.dig('status', 'abstractGameState')

              next unless PREGAME_STATUSES.include?(status)

              games << upcoming_game_data(game, team_id)
            end
          end

          games.first(number)
        end

        def upcoming_game_data(game, team_id)
          home_team = game.dig('teams', 'home', 'team', 'id') == team_id

          team = game.dig('teams', (home_team ? 'home' : 'away'))
          opponent = game.dig('teams', (home_team ? 'away' : 'home'))

          {
            home: home_team,
            opponent: opponent.dig('team', 'teamName'),
            team: team.dig('team', 'name'),
            date: BaseballDiscord::Bot.parse_time(
              game['gameDate'],
              time_zone: team.dig('team', 'venue', 'timeZone', 'id')
            )
          }
        end

        def find_team_by_name(names)
          names.each do |name|
            MLB::TEAMS_BY_NAME.each do |id, potential_names|
              return id.to_i if potential_names.include?(name)
            end
          end

          nil
        end
      end
    end
  end
end

class MLB
  # rubocop:disable Metrics/LineLength
  TEAMS_BY_NAME = {
    '108' => ['angels', 'anaheim', 'ana', 'laa', 'laaa', 'la angels', 'los angeles angels', 'los angeles angels of anaheim', 'los angeles angels'],
    '109' => ['diamondbacks', 'arizona', 'ari', 'az', 'dbacks', 'd-backs', 'arizona diamondbacks'],
    '110' => ['orioles', 'baltimore', 'bal', 'baltimore orioles'],
    '111' => ['red sox', 'boston', 'bos', 'bosox', 'bo sox', 'boston red sox'],
    '112' => ['cubs', 'chicago cubs', 'chc'],
    '113' => ['reds', 'cincinatti', 'cin', 'cincinatti reds'],
    '114' => ['indians', 'cleveland', 'cle', 'cleveland indians'],
    '115' => ['rockies', 'colorado', 'col', 'co', 'colorado rockies'],
    '116' => ['tigers', 'detroit', 'det', 'detroit tigers'],
    '117' => ['astros', 'houston', 'hou', 'houston astros'],
    '118' => ['royals', 'kansas city', 'kc', 'kcr', 'kansas', 'kansas city royals'],
    '119' => ['dodgers', 'los angeles', 'la', 'lad', 'la dodgers', 'los angeles dodgers'],
    '120' => ['nationals', 'washington', 'wsh', 'was', 'dc', 'natinals', 'nats', 'washington nationals'],
    '121' => ['mets', 'new york mets', 'nym'],
    '133' => ['athletics', 'oakland', 'oak', 'as', 'oakland athletics', 'oakland as'],
    '134' => ['pirates', 'pittsburgh', 'pittsburg', 'buccos', 'pit', 'pittsburgh pirates'],
    '135' => ['padres', 'san diego', 'sd', 'sd padres', 'sdp', 'san diego padres'],
    '136' => ['mariners', 'seattle', 'sea', 'seattle mariners'],
    '137' => ['giants', 'san francisco', 'san fran', 'gigantes', 'sf', 'sfg', 'sf giants', 'san francisco giants'],
    '138' => ['cardinals', 'stl', 'st louis', 'salad eaters', 'st louis cardinals'],
    '139' => ['rays', 'tampa bay', 'tb', 'tbr', 'devil rays', 'tampa bay rays'],
    '140' => ['rangers', 'texas', 'tex', 'texas rangers'],
    '141' => ['blue jays', 'toronto', 'tor', 'bluejays', 'jays', 'canada', 'toronto blue jays'],
    '142' => ['twins', 'minnesota', 'min', 'minnesota twins'],
    '143' => ['phillies', 'philadelphia', 'philly', 'phi', 'philadelphia phillies'],
    '144' => ['braves', 'atlanta', 'atl', 'atlanta braves'],
    '145' => ['white sox', 'chicago white sox', 'cws', 'chw', 'chisox', 'chi sox'],
    '146' => ['marlins', 'miami', 'mia', 'florida', 'fla', 'miami marlins'],
    '147' => ['yankees', 'new york yankees', 'nyy', 'bronx bombers'],
    '158' => ['brewers', 'milwaukee', 'mil', 'milwaukee brewers']
  }.freeze
  # rubocop:enable Metrics/LineLength
end
