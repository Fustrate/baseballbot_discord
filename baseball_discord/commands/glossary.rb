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
        FANGRAPHS = {
          name: 'FanGraphs',
          url: 'https://www.fangraphs.com/',
          icon_url: 'https://cdn.fangraphs.com/blogs/wp-content/uploads/2016/04/flat_fg_green.png'
        }.freeze

        def define_term
          definition = terms[args.join(' ').downcase]

          return react_to_message '❓' unless definition

          bot.send_message(channel, nil, false, embed_for_term(definition))

          nil
        end

        def embed_for_term(definition)
          {
            title: definition['title'],
            description: definition['description'],
            url: definition['link'],
            author: FANGRAPHS,
            color: 5_287_462 # FanGraphs Green
          }
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
