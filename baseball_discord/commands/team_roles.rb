# frozen_string_literal: true

module BaseballDiscord
  module Commands
    module TeamRoles
      extend Discordrb::Commands::CommandContainer

      command(
        :team,
        description: 'Change your team tag',
        min_args: 1,
        usage: 'team [name]'
      ) do |event, *args|
        TeamRolesCommand.new(event, *args).update_member_role
      end

      command(:teams, help_available: false) do |event, *args|
        TeamRolesCommand.new(event, *args).update_member_roles
      end

      class TeamRolesCommand < Command
        NOT_A_MEMBER = <<~PM
          You must be a member of the baseball server to use this command.
        PM

        NOT_VERIFIED = <<~PM
          You must verified on the baseball server to use this command. Use `!verify baseball` to do this.
        PM

        TEAM_ROLES = {
          108 => ['LAA', 448_515_259_561_541_632], # Los Angeles Angels
          109 => ['ARI', 448_515_130_632_831_005], # Arizona Diamondbacks
          110 => ['BAL', 448_515_245_812_613_121], # Baltimore Orioles
          111 => ['BOS', 448_515_246_949_138_443], # Boston Red Sox
          112 => ['CHC', 448_515_249_268_588_554], # Chicago Cubs
          113 => ['CIN', 448_515_251_483_443_200], # Cincinnati Reds
          114 => ['CLE', 448_515_252_615_905_322], # Cleveland Indians
          115 => ['COL', 448_515_253_366_685_707], # Colorado Rockies
          116 => ['DET', 448_515_254_771_646_475], # Detroit Tigers
          117 => ['HOU', 448_515_255_686_135_819], # Houston Astros
          118 => ['KC',  448_515_257_019_793_418], # Kansas City Royals
          119 => ['LAD', 448_515_263_965_691_906], # Los Angeles Dodgers
          120 => ['WAS', 448_517_695_948_980_224], # Washington Nationals
          121 => ['NYM', 448_515_313_546_559_488], # New York Mets
          133 => ['OAK', 448_515_319_007_281_162], # Oakland Athletics
          134 => ['PIT', 448_515_386_522_992_670], # Pittsburgh Pirates
          135 => ['SD',  448_517_669_948_227_594], # San Diego Padres
          136 => ['SEA', 448_517_678_693_351_434], # Seattle Mariners
          137 => ['SF',  448_517_675_270_930_442], # San Francisco Giants
          138 => ['STL', 448_517_681_818_239_006], # St. Louis Cardinals
          139 => ['TB',  448_517_685_047_853_086], # Tampa Bay Rays
          140 => ['TEX', 448_517_687_962_763_265], # Texas Rangers
          141 => ['TOR', 448_517_693_470_146_561], # Toronto Blue Jays
          142 => ['MIN', 448_515_311_314_927_626], # Minnesota Twins
          143 => ['PHI', 448_515_321_473_662_976], # Philadelphia Phillies
          144 => ['ATL', 448_515_244_143_280_138], # Atlanta Braves
          145 => ['CWS', 448_515_250_422_153_226], # Chicago White Sox
          146 => ['MIA', 448_515_265_882_226_688], # Miami Marlins
          147 => ['NYY', 448_515_316_360_937_472], # New York Yankees
          158 => ['MIL', 448_515_267_384_049_674]  # Milwaukee Brewers
        }.freeze

        def update_member_role
          check_member_of_baseball

          find_and_assign_role [args.join(' ')]
        rescue UserError => error
          send_pm error.message
        end

        def update_member_roles
          check_member_of_baseball

          find_and_assign_role multiple_inputs
        end

        protected

        def check_member_of_baseball
          @baseball = bot.server 400_516_567_735_074_817

          @member = @baseball.member(user.id)

          raise UserError, NOT_A_MEMBER unless @member
          raise UserError, NOT_VERIFIED unless member_verified?
        end

        def multiple_inputs
          args.join(' ')
            .split(%r{(?:[,&+\|/]|\s+and\s+)})
            .map(&:strip)
            .reject(&:empty?)
            .first(2)
        end

        def find_and_assign_role(inputs)
          team_ids = inputs.map do |input|
            BaseballDiscord::Utilities.find_team_by_name [input]
          end

          return react_to_message('❓') unless team_ids.any?

          role_ids = team_ids.map { |team_id| TEAM_ROLES.dig(team_id, 1) }

          add = @baseball.roles.select { |role| role_ids.include?(role.id) }

          # Add the proper team role(s), remove all others
          @member.modify_roles add, all_team_roles_on_server

          update_nickname(team_ids)

          react_to_message '✅'
        end

        def update_nickname(team_ids)
          abbrs = team_ids.map { |team_id| TEAM_ROLES.dig(team_id, 0) }
            .compact
            .map { |abbr| "[#{abbr}]" }

          base_name = @member.display_name.gsub(/ \[.*\]\z/, '')

          return unless abbrs.count > 1

          @member.nick = "#{base_name} #{abbrs.join('')}"
        rescue Discordrb::Errors::NoPermission
          @bot.logger.info "Couldn't update name for #{@member.distinct}"
        end

        def all_team_roles_on_server
          all_snowflakes = TEAM_ROLES.map { |_, data| data[1] }

          @baseball.roles.select { |role| all_snowflakes.include?(role.id) }
        end

        def member_verified?
          return true unless bot.config.verification_enabled?(@member.server.id)

          @member.roles.map(&:id).include?(
            bot.config.verified_role_id(@member.server.id)
          )
        end
      end
    end
  end
end
