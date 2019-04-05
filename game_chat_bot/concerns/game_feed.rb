# frozen_string_literal: true

module GameChatBot
  module GameFeed
    def lineups
      away_abbrev = @feed.game_data.dig('teams', 'away', 'abbreviation')
      home_abbrev = @feed.game_data.dig('teams', 'home', 'abbreviation')

      <<~MESSAGE
        **#{away_abbrev}:** #{lineup_for_team('away')}
        **#{home_abbrev}:** #{lineup_for_team('home')}
      MESSAGE
    end

    def team_lineup(input)
      case BaseballDiscord::Utilities.find_team_by_name(input)
      when @feed.game_data.dig('teams', 'away', 'id')
        lineup_for_team('away')
      when @feed.game_data.dig('teams', 'home', 'id')
        lineup_for_team('home')
      else
        false
      end
    end

    def fields_for_umpires
      @feed.boxscore['officials'].map do |umpire|
        {
          name: umpire['officialType'],
          value: umpire.dig('official', 'fullName'),
          inline: true
        }
      end
    end

    protected

    def lineup_for_team(flag)
      ids = @feed.boxscore.dig('teams', flag, 'battingOrder')
        .map { |id| "ID#{id}" }

      lineup_positions(flag, ids)
        .zip(lineup_names(ids))
        .map { |pos, name| "#{name} *#{pos}*" }.join(' | ')
    end

    def lineup_names(ids)
      @feed.game_data['players'].values_at(*ids)
        .map { |player| player['lastName'] }
    end

    def lineup_positions(flag, ids)
      @feed.boxscore.dig('teams', flag, 'players')
        .values_at(*ids)
        .map { |player| player.dig('position', 'abbreviation') }
    end
  end
end
