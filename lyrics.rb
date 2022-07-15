#!/usr/bin/env ruby
require "pry"
require "json"
require_relative "logging"

include Logging

# simple divide
divide = "-" * 50

# TODO: logging
# TODO: validate the syllables make sure they have no 0

# methods {{{1

# The function is based upon these simple rules outlined here:
# Each vowel (a, e, i, o, u, y) in a word counts as one syllable subject to the following sub-rules:
# Ignore final -ES, -ED, -E (except for -LE)
# Words of three letters or less count as one syllable
# Consecutive vowels count as one syllable.
#
def syllable_count(word)
  word.downcase!
  return 1 if word.length <= 3
  word.sub!(/(?:[^laeiouy]es|ed|[^laeiouy]e)$/, "")
  word.sub!(/^y/, "")
  word.scan(/[aeiouy]{1,2}/).size
end

# pass in the object to be colored and it is wrapped by the hex color
#
def blue(term)
  "\e[34m#{term}\e[0m"
end

# Creates and array of absolute filepaths. Glob the absolute path passed in
def sub_dir(directory_location)
  raise ArgumentError, "Argument must be a String" unless directory_location.class == String
  Dir.glob(directory_location + "/**/*").select { |f| File.file? f }
end

def color_title(term)
  divide = "-" * 50
  puts "#{divide}"
  puts "#{blue(term)}"
  puts "#{divide}"
end

# result hash
lines_hash = Hash.new { |h, k| h[k] = Hash.new(0) }

# }}}
# user input {{{1

# log to question.log file
logger = logger_output("lyrics.log")
logger.info("Program started...")

# Create a lyrics file variable
root = "/Users/shadowchaser/Code/Ruby/Projects/lyrics"

# Get all files from the directory we have passed in
# if directory is empty brek program
local_files = sub_dir(root)

# If the files array is empty exit
exit if local_files.nil?
logger.info("created a lyrics option list")

# Loop over files generated from the local_files method and print only JSON files
color_title("Lyrics files found")

# Permanently remove the filepaths from the Array that are not JSON
pre = local_files.count
local_files.keep_if { |f| File.extname(f) == ".json" }
pro = local_files.count
logger.info("Found: #{pro} lyrics files. Removed:#{(pre - pro)} files")

# Print the filenames as an option once they has been trimmed
local_files.each_with_index { |f, i| puts "#{i})" + " " + "#{f.split(/\//)[-1]}" }
puts "#{divide}"

# Set a boolean value to break the loop
looper = true

# Run a loop until the correct name has been passed in
while looper == true

  # Get user input
  puts "Please select the number of the file you want to use"

  # Chomp off the new line char
  index = gets.chomp

  # If the index is a number and the number is in the Array
  if (/[0-9]/).match(index) && local_files.include?(local_files[index.to_i])
    looper = false
  end

end

# Set the absolute path to the file variable
#
file = local_files[index.to_i]

# Read the lyrics in via json read catch the error if the file is empty or
# unreadable and print the Exception to loggin. Then exit.
#
begin
  data = JSON.parse(File.read(file))
rescue JSON::ParserError => e
  logger.error("Message: #{e.message}")
  logger.error("Backtrace: #{e.backtrace}")
  logger.error("Exiting Program")
  exit
end

# log
logger.info("created sentences from #{file.split(/\//)[-1]}")

# }}}
# main {{{1

# Array used for a count
lines_order = []

# Create a default base int for longest syllable. Increment will then work
lines_hash["longest_syllable"] = 0

# Count all words (join lines then split into a words Array). Count lines
lines_hash["lines_count"] = data["lyrics"].count
lines_hash["words_count"] = data["lyrics"].join(" ").split.count
logger.info("There were #{lines_hash["lines_count"]} lines created")

# loop over each line creating a word count and syllable count.
data["lyrics"].each_with_index do |line, index|
  # split the line creating an Arrray of words
  words_array = line.split

  # Count the words per line and add to the lines_order Array
  lines_order << words_array.count

  # Count syllables over three letters long
  words_array.each do |word|
    if word.length > 3
      # Create a syllable key then a nested key. This nested key is each
      # category of syllable count (1-2-3-4). Increment the count as needed.
      lines_hash["syllables"]["#{syllable_count(word)}"] += 1
      lines_hash["syllables_count"]["total"] += syllable_count(word)

      # Create a Key from the index of the line Array. Add the full line
      lines_hash[index]["line"] = line

      # Add the count of each word per line. WordsArray created on line 138
      lines_hash[index]["words_count"] = words_array.count

      # Add the per word syllable count created using the syllable_count method
      lines_hash[index][word] = syllable_count(word)

      # The Hash is created with a default value of zero. The condition is
      # then tested to see if 'syllable count' is larger than zero. If the
      # new number is larger it will increment the count
      if lines_hash["longest_syllable"] < syllable_count(word)
        lines_hash["longest_syllable"] = syllable_count(word)
      end
    else
      # Create a key and incremnt the count
      lines_hash["syllables"]["#{syllable_count(word)}"] += 1
    end
  end
end

# }}}
# create percetages of syllables {{{1

# Duplicate the hash. This is done because we use it within itself
per = lines_hash.dup

# Take the value (the syllable count) and divide it by the sum of all words then
# multiply by 100 for the percetage
lines_hash["syllables"].each { |k, v| lines_hash["percentages"][k] = (v / per["words_count"].to_f) * 100 }
logger.info("created syllable percentages for #{lines_hash["percentages"].count} syllable groups")

# }}}
# output line and syllables per line {{{1

# The blacklist is a list of symbols to use to later test keys are valid
blacklist = ["syllables", "lines_count", "words_count", "longest_syllable", "syllable_count", "percentages"]

# Get the top level keys from the hash. Test they are not included in the
# blacklist array. If they are not, loop over them, putting there key value
# pairs
#
lines_hash.keys.each do |main_key|
  unless blacklist.include?(main_key)
    lines_hash[main_key].each do |key, value|
      puts "#{key} -> #{value}"
    end
  end
  puts "#{divide}"
end

# }}}
# formatted counts {{{1
# lyrics with a line count {{{2
data["lyrics"].each_with_index { |line, i| puts "#{blue(i)}) #{line}" }
logger.info("created the lyrics with a count")
# }}}
#------------------------------------------------------------------------------
puts "#{color_title("lyrics results")}"
#------------------------------------------------------------------------------
# formatted words count {{{2
puts "word count: #{lines_hash["words_count"]}"
logger.info("formatting word count")
# }}}
# formatted lines count {{{2
puts "#{divide}" + "\n" + "line count: #{lines_hash["lines_count"]}"
logger.info("formatting line count")
# }}}
# formatted longest syllable {{{2
puts "#{divide}" + "\n" + "longest syllable: #{lines_hash["longest_syllable"]}"
logger.info("formatting longest syllable")
# }}}
# formatted sumtotal syllable {{{2
puts "#{divide}" + "\n" + "sumtotal syllables: #{lines_hash["syllables_count"]["total"]}"
logger.info("formatting sumtotal syllables")
# }}}
# }}}
# readability and grade {{{1
# words / sentces & words / sumtotal syllables {{{2
first = (lines_hash["words_count"].to_f / lines_hash["lines_count"].to_f)
# words / sumtotal syllables
second = (lines_hash["syllables_count"]["total"].to_f / lines_hash["words_count"].to_f)
# }}}
# readability test {{{2
score = (206.835 - 1.015 * first - 84.6 * second)
logger.info("created readability score")

# flesch kincaid formatted results
puts "#{divide}" + "\n" + "reading ease: #{score.round(4)}"
# }}}
# grade level {{{2
score = (0.39 * first + 11.8 * second - 15.59)
logger.info("created grade level score")

# flesch-kincaid grade level
puts "#{divide}" + "\n" + "grade level: #{score.round(4) }"
# }}}
# }}}
# formatted syllables and percentages {{{1
# formatted syllable count {{{2
puts "#{divide}" + "\n" + "#{blue("syllable count")}"

order_lines = lines_hash["syllables"].each { |k, v| k }
order_lines.each { |k, v| puts "#{k} -> #{v}" }

# }}}
# formatted syllable percentages {{{2
puts "#{divide}" + "\n" + "#{blue("syllable percentage")}"

order_per = lines_hash["percentages"].sort_by { |k, v| k }
order_per.each { |k, v| puts "#{k} syllable -> #{v.round(3)} %" }

# }}}
# }}}
# words per line {{{1
# formatted words per line array
puts "#{divide}" + "\n" + "#{blue("words per line")} \n #{lines_order}"

# }}}
