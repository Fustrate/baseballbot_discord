# frozen_string_literal: true

module BaseballDiscord
  module Utilities
    # rubocop:disable Metrics/LineLength
    TEAMS_BY_NAME = {
      # These must be in largest-to-smallest match order for the regexp to work
      108 => ['los angeles angels of anaheim', 'los angeles angels', 'la angels', 'angels', 'anaheim', 'ana', 'laaa', 'laa'],
      109 => ['arizona diamondbacks', 'diamondbacks', 'arizona', 'ari', 'az', 'dbacks'],
      110 => ['baltimore orioles', 'orioles', 'baltimore', 'bal'],
      111 => ['boston red sox', 'red sox', 'boston', 'bos', 'bosox', 'bo sox'],
      112 => ['chicago cubs', 'cubs', 'chc'],
      113 => ['cincinatti reds', 'cincinatti', 'reds', 'cin'],
      114 => ['cleveland indians', 'indians', 'cleveland', 'cle'],
      115 => ['colorado rockies', 'rockies', 'colorado', 'col', 'co'],
      116 => ['detroit tigers', 'tigers', 'detroit', 'det', 'beisbolcats'],
      117 => ['houston astros', 'astros', 'houston', 'hou'],
      118 => ['kansas city royals', 'kc royals', 'royals', 'kansas city', 'kc', 'kcr', 'kansas'],
      119 => ['los angeles dodgers', 'los angeles', 'la dodgers', 'dodgers', 'lad', 'la'],
      120 => ['washington nationals', 'nationals', 'washington', 'wsh', 'was', 'dc', 'natinals', 'nats'],
      121 => ['new york mets', 'mets', 'nym'],
      133 => ['oakland athletics', 'athletics', 'oakland', 'oak', 'as', 'oakland as'],
      134 => ['pittsburgh pirates', 'pirates', 'pittsburgh', 'pittsburg', 'buccos', 'pit'],
      135 => ['san diego padres', 'sd padres', 'padres', 'san diego', 'sd', 'sdp'],
      136 => ['seattle mariners', 'mariners', 'seattle', 'sea'],
      137 => ['san francisco giants', 'sf giants', 'giants', 'san francisco', 'san fran', 'gigantes', 'sfg', 'sf'],
      138 => ['st louis cardinals', 'cardinals', 'stl', 'st louis', 'salad eaters', 'cards'],
      139 => ['tampa bay rays', 'devil rays', 'rays', 'tampa bay', 'tbr', 'tb'],
      140 => ['texas rangers', 'rangers', 'texas', 'tex'],
      141 => ['toronto blue jays', 'blue jays', 'toronto', 'tor', 'bluejays', 'jays', 'canada'],
      142 => ['minnesota twins', 'twins', 'minnesota', 'min'],
      143 => ['philadelphia phillies', 'phillies', 'philadelphia', 'philly', 'phils', 'phi'],
      144 => ['atlanta braves', 'braves', 'atlanta', 'atl', 'barves'],
      145 => ['chicago white sox', 'white sox', 'cws', 'chw', 'chisox', 'chi sox'],
      146 => ['miami marlins', 'marlins', 'miami', 'mia', 'florida', 'fla'],
      147 => ['new york yankees', 'yankees', 'nyy', 'bronx bombers'],
      158 => ['milwaukee brewers', 'brewers', 'milwaukee', 'mil']
    }.freeze
    # rubocop:enable Metrics/LineLength

    DIVISION_TEAMS = {
      200 => [108, 136, 117, 140, 133], # AL West
      201 => [110, 111, 139, 141, 147], # AL East
      202 => [114, 116, 118, 142, 145], # AL Central
      203 => [109, 115, 119, 135, 137], # NL West
      204 => [120, 121, 143, 144, 146], # NL East
      205 => [112, 113, 134, 138, 158]  # NL Central
    }.freeze

    LEAGUE_TEAMS = {
      # AL
      103 => DIVISION_TEAMS[200] + DIVISION_TEAMS[201] + DIVISION_TEAMS[202],
      # NL
      104 => DIVISION_TEAMS[203] + DIVISION_TEAMS[204] + DIVISION_TEAMS[205]
    }.freeze

    PLAYER_LOOKUP = 'http://lookup-service-prod.mlb.com/json/named.' \
                    'search_player_all.bam?sport_code=%%27mlb%%27&' \
                    'name_part=%%27%<name>s%%25%%27'

    def self.parse_date(date)
      return Time.now if date.strip == ''

      Chronic.parse(date)
    end

    def self.parse_time(utc, time_zone: 'America/New_York')
      time_zone = TZInfo::Timezone.get(time_zone) if time_zone.is_a? String

      utc = Time.parse(utc).utc unless utc.is_a? Time

      period = time_zone.period_for_utc(utc)
      with_offset = utc + period.utc_total_offset

      Time.parse "#{with_offset.strftime('%FT%T')} #{period.zone_identifier}"
    end

    def self.find_team_by_name(names)
      Array(names).map { |name| name.downcase.gsub(/[^a-z ]/, '') }
        .each do |name|
          TEAMS_BY_NAME.each do |id, potential_names|
            return id if potential_names.include?(name)
          end
        end

      nil
    end

    def self.look_up_player(name)
      players = JSON.parse(
        URI.parse(
          format(PLAYER_LOOKUP, name: CGI.escape(name.upcase))
        ).open.read
      ).dig('search_player_all', 'queryResults', 'row')

      players = [players] if players.is_a? Hash

      players.sort_by! do |player|
        [player['active_sw'] == 'N', player['pro_debut_date']]
      end.reverse.first
    end

    def self.division_for_team(team_id)
      DIVISION_TEAMS.find { |_, team_ids| team_ids.include?(team_id) }&.first
    end

    def self.league_for_team(team_id)
      LEAGUE_TEAMS.find { |_, team_ids| team_ids.include?(team_id) }&.first
    end

    # @param [String] The user-provided input that may have a date at the end
    # @return [Array<String, DateTime>] The remaining input and a date
    def self.extract_date(input)
      match = Regexp.new("#{team_names_regexp}(?<date>.*)")
        .match(input.downcase)

      if match && match[:team]
        # yay we got a team
        if match[:date] && !match[:date].strip.empty?
          [match[:team], Chronic.parse(match[:date], context: :past).to_date]
        else
          [match[:team], Time.now]
        end
      else
        # no team :(
        [nil, Chronic.parse(input, context: :past).to_date]
      end
    end

    def self.team_names_regexp
      @team_names_regexp ||= Regexp.new(
        '\\A(?<team>' + TEAMS_BY_NAME.values.flatten.join('|') + ')'
      )
    end
  end
end
