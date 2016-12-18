require './article'
require './rank_sentences'
require 'yaml'
require 'byebug'

class DomainDictionaryGenerator
  def initialize(source_path, destination_path = nil)
    self.source_path = source_path
    self.destination_path = destination_path || './dictionary.yml'
  end

  def generate_dictionary
    tokens_frequency = Hash.new(0)
    Dir.foreach(source_path) do |file|
      next if file == '.' || file == '..'
      article = Article.new(File.join(source_path, file))
      tokens_frequency = RankSentences.count_tokens(article.sentences_as_tokens.flatten, tokens_frequency)
    end
    dictionary = (tokens_frequency.sort { |a, b| b.last <=> a.last })[0..tokens_frequency.count/20]
    File.open(destination_path, 'w') {|f| f.write dictionary.to_h.to_yaml }
  end

  private

  attr_accessor :source_path, :destination_path
end