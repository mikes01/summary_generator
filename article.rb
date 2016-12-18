require 'pragmatic_segmenter'
require 'pragmatic_tokenizer'
require 'lemmatizer'

class Article
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
    PragmaticSegmenter::Segmenter.new(text: text).segment[0..-2]
  end

  def tokenizer
    PragmaticTokenizer::Tokenizer.new(
      remove_stop_words: true, expand_contractions: true, remove_emoji: true,
      remove_urls: true, remove_emails: true, remove_domains: true,
      hashtags: :keep_and_clean, mentions: :keep_and_clean, clean: true,
      classic_filter: true, punctuation: :none, minimum_length: 3
    )
  end
end