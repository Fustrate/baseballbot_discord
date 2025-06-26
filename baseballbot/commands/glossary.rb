# frozen_string_literal: true

module BaseballDiscord
  module Commands
    # Output definitions along with a link
    module Glossary
      FANGRAPHS = {
        name: 'FanGraphs',
        url: 'https://www.fangraphs.com/',
        icon_url: 'https://cdn.fangraphs.com/blogs/wp-content/uploads/2016/04/flat_fg_green.png'
      }.freeze

      def self.register(bot)
        bot.application_command(:define) { DefineCommand.new(it).define_term }
      end

      class DefineCommand < SlashCommand
        def define_term
          definition = terms[options['term'].downcase]

          if definition
            respond_with embed: embed_for_term(definition)
          else
            error_message "Unknown term: #{options['term']}"
          end
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
          @terms ||= YAML.safe_load_file(File.expand_path("#{__dir__}/../../config/glossary.yml"))['glossary']
            .to_h { |abbr, data| [abbr.downcase, data.merge('abbr' => abbr)] }
        end
      end
    end
  end
end
