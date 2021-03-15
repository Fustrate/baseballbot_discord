# frozen_string_literal: true

module GameChatBot
  # Keeps track of all team logo emojis for the /r/baseball discord server.
  module Emoji
    TEAM_EMOJI = {
      'laa' => ':laa:451995933086056448',
      'ari' => ':ari:452001179191345153',
      'bal' => ':bal:451991444614414336',
      'bos' => ':bos:451982161260838913',
      'chc' => ':chc:451974212828004362',
      'cin' => ':cin:451984903416971277',
      'cle' => ':cle:452004927430983681',
      'col' => ':col:452002448845045771',
      'det' => ':det:451995351008673802',
      'hou' => ':hou:451992912058908673',
      'kc' => ':kc:452005836873662476',
      'lad' => ':lad:452534629237391402',
      'was' => ':was:452529607468646402',
      'wsh' => ':was:452529607468646402',
      'nym' => ':nym:451996936631746560',
      'oak' => ':oak:451987003551121408',
      'pit' => ':pit:452001844848492555',
      'sd' => ':sd:821095786624450610',
      'sea' => ':sea:451987673821872129',
      'sf' => ':sf:451976480407420928',
      'stl' => ':stl:821096182705029133',
      'tb' => ':tb:452006979263660043',
      'tex' => ':tex:451989186958983168',
      'tor' => ':tor:821095786624450610',
      'min' => ':min:452531083335041054',
      'phi' => ':phi:821095786624450610',
      'atl' => ':atl:452001161227010048',
      'cws' => ':cws:452003611598258176',
      'mia' => ':mia:451984131912630273',
      'nyy' => ':nyy:821096182705029133',
      'mil' => ':mil:451999627655380994'
    }.freeze

    def self.team_emoji(abbreviation)
      "<#{TEAM_EMOJI[abbreviation.downcase]}>"
    end
  end
end
