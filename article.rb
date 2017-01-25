require 'pragmatic_segmenter'
require 'pragmatic_tokenizer'
require 'lemmatizer'

class Article
  SQL_QUERY_REGEXES = [/(INSERT INTO)(.*)(VALUES)(.*)(RETURNING)(.*)/,
    /(SELECT)(.*)(FROM)(.*)/,
    /(UPDATE)(.*)(SET)(.*)(WHERE)(.*)/,
    /(DELETE FROM)(.*)(WHERE)(.*)/].freeze

  def initialize(path, title = nil)
    text = File.read(path)
    self.sentences = extract_sentences(text)
    self.length = text.length
    self.lemmatizer = Lemmatizer.new
    self.title_tokens = sentence_to_tokens(title || sentences.shift.to_s)
  end

  attr_accessor :title_tokens, :sentences, :length

  def sentences_as_tokens
    @tokens ||= sentences.map do |sentence|
      sentence_to_tokens(sentence.to_s)
    end
  end

  private

  attr_accessor :lemmatizer

  def sentence_to_tokens(sentence)
    tokenizer.tokenize(sentence).map { |token| lemmatizer.lemma(token) }
  end

  def extract_sentences(text)
    sentences = PragmaticSegmenter::Segmenter.new(text: text).segment[0..-2]
    [].tap do |checked_sentences|
      sentences.each_with_index do |sentence, index|
        next if detect_sql_query(sentence) || detect_repeated_sentences(sentences, index, sentence)
        checked_sentences << sentence
      end
    end
  end

  def tokenizer
    PragmaticTokenizer::Tokenizer.new(
      remove_stop_words: true, expand_contractions: true, remove_emoji: true,
      remove_urls: true, remove_emails: true, remove_domains: true,
      hashtags: :keep_and_clean, mentions: :keep_and_clean, clean: true,
      classic_filter: true, punctuation: :none, minimum_length: 3
    )
  end

  def detect_sql_query(sentence)
    is_sql_query = false
    SQL_QUERY_REGEXES.each do |regex|
      is_sql_query = !regex.match(sentence).nil?
      break if is_sql_query
    end
    is_sql_query
  end

  def detect_repeated_sentences(sentences, index, sentence)
    sentences.each_with_index do |sentence_from_article, article_index|
      if index != article_index && sentence == sentence_from_article
        return true
      end
    end
    false
  end
end