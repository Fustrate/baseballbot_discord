# frozen_string_literal: true

module BaseballDiscord
  module Commands
    # Output definitions along with a link
    module Glossary
      extend Discordrb::Commands::CommandContainer

      command(
        %i[define glossary],
        description: 'Look up a term from FanGraphs',
        usage: 'glossary [term]',
        min_args: 1
      ) do |event, *args|
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
          definition = terms[raw_args.downcase]

          return react_to_message '❓' unless definition

          bot.send_message(channel, nil, false, embed_for_term(definition))

          nil
        end

        protected

        def embed_for_term(definition)
          {
            title: "#{definition['title']} (#{definition['abbr']})",
            description: definition['description'],
            url: definition['link'],
            fields: fields_for_term(definition),
            author: FANGRAPHS,
            color: 5_287_462 # FanGraphs Green
          }
        end

        def fields_for_term(definition)
          return [] unless definition['see_also']

          [{ name: 'See Also:', value: definition['see_also'].join(', ') }]
        end

        def terms
          @terms ||= YAML.safe_load(
            File.open(File.expand_path("#{__dir__}/../../config/glossary.yml")).read
          )['glossary'].map do |abbr, data|
            [abbr.downcase, data.merge('abbr' => abbr)]
          end.to_h
        end
      end
    end
  end
end
