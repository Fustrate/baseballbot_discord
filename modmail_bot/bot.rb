# frozen_string_literal: true

require 'time'

require_relative '../discord_bot'

require_relative '../shared/discordrb_forum_threads'
require_relative '../shared/output_helpers'
require_relative '../shared/slash_command'
require_relative '../shared/utilities'

# Require all commands
Dir.glob("#{__dir__}/{commands}/*").each { require_relative _1 }

module ModmailBot
  class Bot < DiscordBot
    INTENTS = %i[servers server_messages server_message_reactions].freeze

    def initialize
      super(
        client_id: ENV.fetch('DISCORD_MODMAIL_CLIENT_ID'),
        token: ENV.fetch('DISCORD_MODMAIL_TOKEN'),
        command_doesnt_exist_message: nil,
        help_command: false,
        prefix: '!',
        intents: INTENTS
      )
    end

    protected

    def load_commands
      ModmailBot::Commands::Archive.register self
    end

    def event_loop
      @check_modmail ||= ModmailBot::CheckModmail.new(self)

      @check_modmail.check!
    end
  end
end
