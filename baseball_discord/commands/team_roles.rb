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

      class TeamRolesCommand < Command
        NOT_A_MEMBER = <<~PM
          You must be a member of the baseball server to use this command.
        PM

        NOT_VERIFIED = <<~PM
          You must verified on the baseball server to use this command. Use `!verify baseball` to do this.
        PM

        TEAM_ROLES = {
          108 => 448_515_259_561_541_632, # Los Angeles Angels
          109 => 448_515_130_632_831_005, # Arizona Diamondbacks
          110 => 448_515_245_812_613_121, # Baltimore Orioles
          111 => 448_515_246_949_138_443, # Boston Red Sox
          112 => 448_515_249_268_588_554, # Chicago Cubs
          113 => 448_515_251_483_443_200, # Cincinnati Reds
          114 => 448_515_252_615_905_322, # Cleveland Indians
          115 => 448_515_253_366_685_707, # Colorado Rockies
          116 => 448_515_254_771_646_475, # Detroit Tigers
          117 => 448_515_255_686_135_819, # Houston Astros
          118 => 448_515_257_019_793_418, # Kansas City Royals
          119 => 448_515_263_965_691_906, # Los Angeles Dodgers
          120 => 448_517_695_948_980_224, # Washington Nationals
          121 => 448_515_313_546_559_488, # New York Mets
          133 => 448_515_319_007_281_162, # Oakland Athletics
          134 => 448_515_386_522_992_670, # Pittsburgh Pirates
          135 => 448_517_669_948_227_594, # San Diego Padres
          136 => 448_517_678_693_351_434, # Seattle Mariners
          137 => 448_517_675_270_930_442, # San Francisco Giants
          138 => 448_517_681_818_239_006, # St. Louis Cardinals
          139 => 448_517_685_047_853_086, # Tampa Bay Rays
          140 => 448_517_687_962_763_265, # Texas Rangers
          141 => 448_517_693_470_146_561, # Toronto Blue Jays
          142 => 448_515_311_314_927_626, # Minnesota Twins
          143 => 448_515_321_473_662_976, # Philadelphia Phillies
          144 => 448_515_244_143_280_138, # Atlanta Braves
          145 => 448_515_250_422_153_226, # Chicago White Sox
          146 => 448_515_265_882_226_688, # Miami Marlins
          147 => 448_515_316_360_937_472, # New York Yankees
          158 => 448_515_267_384_049_674  # Milwaukee Brewers
        }.freeze

        def update_member_role
          @baseball = bot.server 400_516_567_735_074_817

          @member = @baseball.member(user.id)

          raise UserError, NOT_A_MEMBER unless @member
          raise UserError, NOT_VERIFIED unless member_verified?

          find_and_assign_role
        rescue UserError => error
          send_pm error.message
        end

        def find_and_assign_role
          input = args.join(' ')

          team_id = BaseballDiscord::Utilities.find_team_by_name [input]

          raise UserError, TEAM_NOT_FOUND unless team_id

          add = @baseball.roles.find { |role| role.id == TEAM_ROLES[team_id] }

          # Add the proper team role, remove all others
          @member.modify_roles add, all_team_roles_on_server

          react_to_message '✅'
        end

        def all_team_roles_on_server
          @baseball.roles.find { |role| TEAM_ROLES.key(role.id) }
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
