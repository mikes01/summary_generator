require './article'
require './rank_sentences'
require './domain_dictionary_generator'
require 'optparse'
require 'table_print'
require 'word_wrap'
require 'word_wrap/core_ext'

def summary_fraction(article_length, results, fraction)
  summary_length = 0
  summary = []
  results.each do |ranked_sentence|
    summary.push(ranked_sentence)
    summary_length += ranked_sentence.last[:sentence].length
    break if summary_length > 0.1 * article_length
  end
  summary
end

def summary_sentences(results, sentences_count)
  summary_length = 0
  summary = []
  results.each do |ranked_sentence|
    summary.push(ranked_sentence)
    summary_length += 1
    break if summary_length >= sentences_count
  end
  summary
end

options = {}
summary_length = 0.1
summary_type = :fraction

OptionParser.new do |opts|
  opts.banner = "Usage: run.rb [options]"

  opts.on("-a path", "--article path", String, "Mandatory path to the article") do |path|
    options[:article_path] = path
  end

  opts.on("-d path", "--dictionary path", String, "Path to the dictionary") do |path|
    options[:dictionary_path] = path
  end

  opts.on("-c path", "--cue-words path", String, "Path to the list of cue words") do |path|
    options[:cue_words_path] = path
  end

  opts.on("-a path", "--article path", String, "Path to article") do |path|
    options[:article_path] = path
  end

  opts.on("-f N", "--article-weight N", Float, "Weight points for the frequency of occurrence in the article.") do |n|
    options[:word_frequency_at_article_weight] = n
  end

  opts.on("-i N", "--dictionary-weight N", Float, "Weight points for the frequency of occurrence in the dictionary.") do |n|
    options[:word_frequency_at_dictionary_weight] = n
  end

  opts.on("-t N", "--title-weight N", Float, "Weight points for the occurrence in the title.") do |n|
    options[:title_tokens_weight] = n
  end

  opts.on("-p N", "--position-weight N", Float, "Weight points for the premium position at the article.") do |n|
    options[:sentence_position_weight] = n
  end

  opts.on("-u N", "--cue-weight N", Float, "Weight points for the cue words occurrence.") do |n|
    options[:cue_words_weights] = n
  end

  opts.on("-r N", "--position-ratio N", Float, "The ratio of premium position sentences.") do |n|
    options[:sentence_position_weight] = n
  end

  opts.on("-l N", "--length N", Float, "The length of summary.") do |n|
    summary_length = n
  end

  opts.on("--type [TYPE]", [:sentences, :fraction],
          "Select summary length type (sentences or fraction)") do |t|
    summary_type = t
  end

  opts.on("-g", "--dictionary-destination path", String, "Path to the dictionary destination.") do |n|
    options[:dictionary_destination] = path
  end

  opts.on("-b", "--base-articles path", String, "Path to the base articles dir.") do |path|
    options[:base_articles] = path
  end

  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!

if options[:base_articles].nil?
  raise OptionParser::MissingArgument if options[:article_path].nil?

  article = Article.new(options[:article_path])
  ranker = RankSentences.new(options)

  results = ranker.rank(article)
  format = 'word frequency at article: %s %-5s %-5s %-5s %-5s %-5s'

  results.values.each do |sentence|
    p sentence[:sentence]
    p "word_frequency_at_article: #{sentence[:word_frequency_at_article]} word_frequency_at_dictionary: #{sentence[:word_frequency_at_dictionary]} "\
      "title_tokens: #{sentence[:title_tokens]} cue_words: #{sentence[:cue_words]} position: #{sentence[:position]} "\
      "total: #{sentence[:total]}"
    puts ""
  end

  results = results.sort  { |a, b| b.last[:total] <=> a.last[:total] }

  summary = summary_type == :fraction ? summary_fraction(article.length, results, summary_length) : summary_sentences(results, summary_length)

  summary = summary.sort  { |a, b| a.first <=> b.first }

  puts "\n\n\n ***SUMMARY***"
  summary.each { |sentence| puts "#{sentence.last[:sentence]} POINTS: #{sentence.last[:total]}" }

else
  DomainDictionaryGenerator.new(options[:base_articles], options[:dictionary_destiantion]).generate_dictionary
end
