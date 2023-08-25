# frozen_string_literal: true

module OutputHelpers
  def squish(text) = text.gsub(/\s{2,}/, ' ').strip

  def titleize(text) = text&.tr('_', ' ')&.gsub(/\b[a-z]/, &:capitalize)

  def format_table(table) = "```\n#{table}\n```"
end
