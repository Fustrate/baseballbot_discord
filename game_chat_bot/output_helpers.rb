# frozen_string_literal: true

module GameChatBot
  module OutputHelpers
    def squish(text)
      text.gsub(/\s{2,}/, ' ').strip
    end

    def titleize(text)
      text&.tr('_', ' ')&.gsub(/\b[a-z]/, &:capitalize)
    end

    def prettify_table(table)
      top_border, *middle, bottom_border = table.to_s.lines.map(&:strip)

      new_table = middle.map do |line|
        line[0] == '+' ? "├#{line[1...-1].tr('-+', '─┼')}┤" : line.tr('|', '│')
      end

      new_table.unshift "┌#{top_border[1...-1].tr('-+', '─┬')}┐"
      new_table.push "└#{bottom_border[1...-1].tr('-+', '─┴')}┘"

      # Move the T-shaped corners down two rows if there's a title
      if table.title
        new_table[0] = new_table[0].tr('┬', '─')
        new_table[2] = new_table[2].tr('┼', '┬')
      end

      new_table.join("\n")
    end
  end
end
