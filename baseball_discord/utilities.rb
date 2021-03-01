# frozen_string_literal: true

require 'yaml'

module BaseballDiscord
  module Utilities
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

    PLAYER_LOOKUP = 'http://lookup-service-prod.mlb.com/json/named.search_player_all.bam?' \
                    'sport_code=%%27mlb%%27&name_part=%%27%<name>s%%25%%27'

    def self.parse_date(date)
      date.strip == '' ? Time.now : Chronic.parse(date)
    end

    def self.parse_time(utc, time_zone: 'America/New_York')
      time_zone = TZInfo::Timezone.get(time_zone) if time_zone.is_a? String

      utc = Time.parse(utc).utc unless utc.is_a? Time

      period = time_zone.period_for_utc(utc)

      Time.parse "#{(utc + period.utc_total_offset).strftime('%FT%T')} #{period.zone_identifier}"
    end

    def self.find_team_by_name(names)
      Array(names).map { |name| name.downcase.gsub(/[^a-z ]/, '') }
        .each do |name|
          teams_by_name.each do |id, potential_names|
            return id if potential_names.include?(name)
          end
        end

      nil
    end

    def self.look_up_player(name)
      players = JSON.parse(
        URI.parse(format(PLAYER_LOOKUP, name: CGI.escape(name.upcase))).open.read
      ).dig('search_player_all', 'queryResults', 'row')

      players = [players] if players.is_a? Hash

      players.max_by do |player|
        [player['active_sw'] == 'Y' ? 1 : 0, player['pro_debut_date']]
      end
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
      match = Regexp.new("#{team_names_regexp}(?<date>.*)").match(input.downcase)

      if match && match[:team]
        # yay we got a team
        [match[:team], date_for_match(match[:date])]
      else
        # no team :(
        [nil, Chronic.parse(input, context: :past).to_date]
      end
    end

    def self.date_for_match(date)
      return Time.now unless date && !date.strip.empty?

      Chronic.parse(date, context: :past).to_date
    end

    def self.team_names_regexp
      @team_names_regexp ||= Regexp.new("\\A(?<team>#{teams_by_name.values.flatten.join('|')})")
    end

    def self.teams_by_name
      @teams_by_name ||= ::YAML
        .safe_load(File.open(File.expand_path("#{__dir__}/../config/team_names.yml")).read)
    end
  end
end
