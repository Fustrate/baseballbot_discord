# frozen_string_literal: true

require 'date'
require 'json'
require 'open-uri'
require 'securerandom'
require 'terminal-table'
require 'tzinfo'
require 'yaml'

require 'honeybadger'

require_relative '../discord_bot'

require_relative '../shared/slash_command'
require_relative '../shared/utilities'

# Require all commands and events
Dir.glob("#{__dir__}/{commands,events}/*").each { require_relative it }

module BaseballDiscord
  class Bot < DiscordBot
    # ID of the user allowed to administrate the bot
    ADMIN_ID = 429364871121993728

    INTENTS = %i[
      servers server_members server_messages server_message_reactions direct_messages direct_message_reactions
    ].freeze

    def initialize
      super(
        client_id: ENV.fetch('DISCORD_CLIENT_ID'),
        token: ENV.fetch('DISCORD_TOKEN'),
        prefix: '!',
        intents: INTENTS
      )
    end

    def load_commands
      BaseballDiscord::Commands.constants.each { BaseballDiscord::Commands.const_get(it).register(self) }

      BaseballDiscord::Events.constants.each { include! BaseballDiscord::Events.const_get(it) }
    end

    protected

    def event_loop; end
  end

  class UserError < RuntimeError; end
end
