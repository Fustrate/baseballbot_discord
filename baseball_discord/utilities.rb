# frozen_string_literal: true

module BaseballDiscord
  module Utilities
    # rubocop:disable Metrics/LineLength
    TEAMS_BY_NAME = {
      108 => ['angels', 'anaheim', 'ana', 'laa', 'laaa', 'la angels', 'los angeles angels', 'los angeles angels of anaheim', 'los angeles angels'],
      109 => ['diamondbacks', 'arizona', 'ari', 'az', 'dbacks', 'd-backs', 'arizona diamondbacks'],
      110 => ['orioles', 'baltimore', 'bal', 'baltimore orioles'],
      111 => ['red sox', 'boston', 'bos', 'bosox', 'bo sox', 'boston red sox'],
      112 => ['cubs', 'chicago cubs', 'chc'],
      113 => ['reds', 'cincinatti', 'cin', 'cincinatti reds'],
      114 => ['indians', 'cleveland', 'cle', 'cleveland indians'],
      115 => ['rockies', 'colorado', 'col', 'co', 'colorado rockies'],
      116 => ['tigers', 'detroit', 'det', 'detroit tigers', 'beisbolcats'],
      117 => ['astros', 'houston', 'hou', 'houston astros'],
      118 => ['royals', 'kansas city', 'kc', 'kcr', 'kansas', 'kansas city royals'],
      119 => ['dodgers', 'los angeles', 'la', 'lad', 'la dodgers', 'los angeles dodgers'],
      120 => ['nationals', 'washington', 'wsh', 'was', 'dc', 'natinals', 'nats', 'washington nationals'],
      121 => ['mets', 'new york mets', 'nym'],
      133 => ['athletics', 'oakland', 'oak', 'as', 'oakland athletics', 'oakland as'],
      134 => ['pirates', 'pittsburgh', 'pittsburg', 'buccos', 'pit', 'pittsburgh pirates'],
      135 => ['padres', 'san diego', 'sd', 'sd padres', 'sdp', 'san diego padres'],
      136 => ['mariners', 'seattle', 'sea', 'seattle mariners'],
      137 => ['giants', 'san francisco', 'san fran', 'gigantes', 'sf', 'sfg', 'sf giants', 'san francisco giants'],
      138 => ['cardinals', 'stl', 'st louis', 'salad eaters', 'st louis cardinals', 'cards'],
      139 => ['rays', 'tampa bay', 'tb', 'tbr', 'devil rays', 'tampa bay rays'],
      140 => ['rangers', 'texas', 'tex', 'texas rangers'],
      141 => ['blue jays', 'toronto', 'tor', 'bluejays', 'jays', 'canada', 'toronto blue jays'],
      142 => ['twins', 'minnesota', 'min', 'minnesota twins'],
      143 => ['phillies', 'philadelphia', 'philly', 'phi', 'philadelphia phillies', 'phils'],
      144 => ['braves', 'atlanta', 'atl', 'atlanta braves', 'barves'],
      145 => ['white sox', 'chicago white sox', 'cws', 'chw', 'chisox', 'chi sox'],
      146 => ['marlins', 'miami', 'mia', 'florida', 'fla', 'miami marlins'],
      147 => ['yankees', 'new york yankees', 'nyy', 'bronx bombers'],
      158 => ['brewers', 'milwaukee', 'mil', 'milwaukee brewers']
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
      names.map { |name| name.downcase.gsub(/[^a-z ]/, '') }.each do |name|
        TEAMS_BY_NAME.each do |id, potential_names|
          return id if potential_names.include?(name)
        end
      end

      nil
    end

    def self.division_for_team(team_id)
      DIVISION_TEAMS.find { |_, teams| teams.include?(team_id) }&.first
    end
  end
end
