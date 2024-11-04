# frozen_string_literal: true

module BaseballDiscord
  module Commands
    module TeamRoles
      def self.register(bot)
        bot.application_command(:team) { TeamRolesCommand.new(_1).update_member_roles }
      end

      class TeamRolesCommand < SlashCommand
        NOT_A_MEMBER = <<~PM
          You must be a member of the baseball server to use this command.
        PM

        NOT_VERIFIED = <<~PM
          You must be verified on the baseball server to use this command.

          Use `/verify baseball` to do this.
        PM

        TEAM_ROLES = {
          108 => ['LAA', 448515259561541632], # Los Angeles Angels
          109 => ['ARI', 448515130632831005], # Arizona Diamondbacks
          110 => ['BAL', 448515245812613121], # Baltimore Orioles
          111 => ['BOS', 448515246949138443], # Boston Red Sox
          112 => ['CHC', 448515249268588554], # Chicago Cubs
          113 => ['CIN', 448515251483443200], # Cincinnati Reds
          114 => ['CLE', 448515252615905322], # Cleveland Indians
          115 => ['COL', 448515253366685707], # Colorado Rockies
          116 => ['DET', 448515254771646475], # Detroit Tigers
          117 => ['HOU', 448515255686135819], # Houston Astros
          118 => ['KC',  448515257019793418], # Kansas City Royals
          119 => ['LAD', 448515263965691906], # Los Angeles Dodgers
          120 => ['WAS', 448517695948980224], # Washington Nationals
          121 => ['NYM', 448515313546559488], # New York Mets
          133 => ['ATH', 448515319007281162], # Nowhere Athletics
          134 => ['PIT', 448515386522992670], # Pittsburgh Pirates
          135 => ['SD',  448517669948227594], # San Diego Padres
          136 => ['SEA', 448517678693351434], # Seattle Mariners
          137 => ['SF',  448517675270930442], # San Francisco Giants
          138 => ['STL', 448517681818239006], # St. Louis Cardinals
          139 => ['TB',  448517685047853086], # Tampa Bay Rays
          140 => ['TEX', 448517687962763265], # Texas Rangers
          141 => ['TOR', 448517693470146561], # Toronto Blue Jays
          142 => ['MIN', 448515311314927626], # Minnesota Twins
          143 => ['PHI', 448515321473662976], # Philadelphia Phillies
          144 => ['ATL', 448515244143280138], # Atlanta Braves
          145 => ['CWS', 448515250422153226], # Chicago White Sox
          146 => ['MIA', 448515265882226688], # Miami Marlins
          147 => ['NYY', 448515316360937472], # New York Yankees
          158 => ['MIL', 448515267384049674]  # Milwaukee Brewers
        }.freeze

        def update_member_roles
          check_member_of_baseball

          find_and_assign_roles
        rescue UserError => e
          error_message e.message
        end

        protected

        def check_member_of_baseball
          @baseball = bot.server 400516567735074817

          @member = @baseball.member(user.id)

          raise UserError, NOT_A_MEMBER unless @member
          raise UserError, NOT_VERIFIED unless member_verified?
        end

        def find_and_assign_roles
          inputs = [options['team1'], options['team2']].compact

          team_ids = inputs
            .filter_map { BaseballDiscord::Utilities.find_team_by_name [_1] }
            .uniq

          team_ids.any? ? update_member(team_ids) : error_message('Team name(s) not found...')
        end

        # IDs passed to this message are known to be good
        def update_member(team_ids)
          # Only one role is actually assigned
          role_id = TEAM_ROLES.dig(team_ids.first, 1)

          add = @baseball.roles.select { role_id == _1.id }

          # Add the proper team role(s), remove all others
          @member.modify_roles add, all_team_roles_on_server

          update_nickname(team_ids)

          respond_with content: '✅', ephemeral: true
        end

        def update_nickname(team_ids)
          abbrs = team_ids.first(2).map { "[#{TEAM_ROLES.dig(_1, 0)}]" }

          # return unless abbrs.count > 1

          base_name = @member.display_name.gsub(/\s*\[.*\]\z/, '')

          @member.nick = "#{base_name} #{abbrs.join}"
        rescue Discordrb::Errors::NoPermission
          bot.logger.info "Couldn't update name for #{@member.distinct}"
        end

        def all_team_roles_on_server
          all_snowflakes = TEAM_ROLES.map { |_, data| data[1] }

          @baseball.roles.select { all_snowflakes.include?(_1.id) }
        end

        def member_verified?
          return true unless bot.config.verification_enabled?(@member.server.id)

          @member.roles.map(&:id).include? bot.config.verified_role_id(@member.server.id)
        end
      end
    end
  end
end
