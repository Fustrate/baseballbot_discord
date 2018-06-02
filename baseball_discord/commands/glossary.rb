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

          definition = terms[args.join(' ').downcase]

          return react_to_message '❓' unless definition

          embed = {
            title: definition['title'],
            description: definition['description'],
            url: definition['link'],
            author: { name: 'FanGraphs', url: 'https://www.fangraphs.com/' },
            color: 5_287_462 # FanGraphs Green
          }

          bot.send_message(channel, nil, false, embed)

          nil
        end

        protected

        def terms
          @terms ||= YAML.safe_load(
            File.open(
              File.expand_path(__dir__ + '/../../config/glossary.yml')
            ).read
          ).dig('glossary')
        end
      end
    end
  end
end
