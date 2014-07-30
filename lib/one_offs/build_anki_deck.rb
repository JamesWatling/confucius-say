class OneOffs
  class BuildAnkiDeck < Base
    require 'csv'

    IMPORT_FILE = "cantonese_l1.txt"
    EXPORT_FILE = "anki_deck_canto_l1.csv"

    def read_file
      IO.readlines(Rails.root + "tmp" + IMPORT_FILE)
    end

    def process_data(lines)
      app_controller = ApplicationController.new

      lines.map do |line|
        # Split
        char = line.split(/\s/).first
        # Lookup Char
        word = Word.includes(:compounds).where("chars_trad = ? OR chars_simp = ?", char, char).first

        chars_simp = word.chars_trad != word.chars_simp ? "(#{word.chars_simp})" : nil

        # Example handler
        sorted = word.compounds.sort!{|a,b|
          b.chars_trad.size <=> a.chars_trad.size
        }
        begin
          example = sorted[(sorted.count - 1)/2]

          example_chars = example.chars_trad
          example_english = example.english
          example_jyutping = example.jyutping
          example_url = "http://cantodictionary.com#{app_controller.word_path(example)}"

        rescue => e
          example_chars = nil
          example_english = nil
          example_jyutping = nil
          example_url = nil
        end
        sound = word.jyutping.split(/[\s\/]/).map{ |jyutping|
          "[sound:#{jyutping}.wav]"
        }.join("")
        #Isolate

        # Build char, simplified, pronouce, meaning, example, sound
        [
          word.chars_trad.try(:strip),
          chars_simp.try(:strip),
          word.jyutping.try(:strip),
          word.english.try(:strip),
          word.english_2.try(:strip),
          "http://cantodictionary.com#{app_controller.word_path(word)}",
          example_chars.try(:strip),
          example_jyutping.try(:strip),
          example_english.try(:strip),
          example_url,
          sound
        ]

      end #map
    end

    def write_file(data)
      CSV.open(Rails.root + "tmp" + EXPORT_FILE, "w") do |csv|
        data.each do |line|
          csv << line
        end
      end
    end

    #OneOffs::BuildAnkiDeck.go
    def self.go
      ActiveRecord::Base.logger.level = 1

      builder = BuildAnkiDeck.new

      lines = builder.read_file
      data = builder.process_data(lines)
      builder.write_file(data)

      ''
    end
  end
end
