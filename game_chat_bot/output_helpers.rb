# frozen_string_literal: true

module GameChatBot
  module OutputHelpers
    def squish(text)
      text.gsub(/\s{2,}/, ' ').strip
    end

    def titleize(text)
      text&.tr('_', ' ')&.gsub(/\b[a-z]/, &:capitalize)
    end

    def format_table(table)
      "```\n#{prettify_table(table)}\n```"
    end

    def prettify_table(table)
      new_table = prettify_table_contents(table)

      # Move the T-shaped corners down two rows if there's a title
      if table.title
        new_table[0] = new_table[0].tr('┬', '─')
        new_table[2] = new_table[2].tr('┼', '┬')
      end

      new_table.join("\n")
    end

    protected

    def prettify_table_contents(table)
      top_border, *middle, bottom_border = table.to_s.lines.map(&:strip)

      new_table = middle
        .map { |line| line[0] == '+' ? "├#{line[1...-1].tr('-+', '─┼')}┤" : line.tr('|', '│') }

      new_table.unshift "┌#{top_border[1...-1].tr('-+', '─┬')}┐"
      new_table.push "└#{bottom_border[1...-1].tr('-+', '─┴')}┘"

      new_table
    end
  end
end
