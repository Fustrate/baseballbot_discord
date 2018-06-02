# frozen_string_literal: true

module BaseballDiscord
  module Commands
    # Output definitions along with a link
    module Glossary
      extend Discordrb::Commands::CommandContainer

      command(:glossary, help_available: false) do |event, *args|
        GlossaryCommand.new(event, *args).define_term
      end

      # Prints some basic info to the log file
      class GlossaryCommand < Command
        def define_term
          unless user.id == BaseballDiscord::Bot::ADMIN_ID
            return react_to_message '🔒'
          end

          embed = {
            title: 'Test Embed',
            description: 'Description of the term',
            url: 'https://baseballbot.io/',
            color: 16_777_215
          }

          send_message(channel, 'content!', false, embed)

          nil
        end
      end
    end
  end
end
