require 'yaml'
require 'byebug'

class RankSentences
  def initialize(
    params
  )
    self.word_frequency_at_article_weight = params[:word_frequency_at_article_weight] || 2
    self.word_frequency_at_dictionary_weight = params[:word_frequency_at_dictionary_weight] || 0.1
    self.title_tokens_weight = params[:title_tokens_weight] || 10
    self.sentence_position_weight = params[:sentence_position_weight] || 4
    self.cue_words_weight = params[:cue_words_weight] || 5
    self.premium_position_ratio = params[:premium_position_ratio] || 0.1
    self.dictionary = YAML::load_file(params[:dictionary_path] || './dictionary.yml')
    self.cue_words = YAML::load_file(params[:cue_words_path] || './cue_words.yml')
  end

  def rank(article)
    tokens_frequency = self.class.count_tokens(article.sentences_as_tokens.flatten)
    ranked_sentences = {}
    article.sentences.each_with_index do |sentence, index|
      ranked_sentences[index] = count_points_for_sentence(
        sentence, index, article.sentences_as_tokens[index], tokens_frequency,
        article.sentences.count, article.title_tokens
      )
    end
    choose_best_sentences(ranked_sentences, article.sentences, article.length)
  end

  def self.count_tokens(tokens, tokens_frequency_hash = nil)
    (tokens_frequency_hash || Hash.new(0)).tap do |tokens_frequency|
      tokens.each do |token|
        tokens_frequency[token] += 1
      end
    end
  end

  private

  attr_accessor :word_frequency_at_article_weight, :word_frequency_at_dictionary_weight,
    :title_tokens_weight, :sentence_position_weight, :cue_words_weight, :premium_position_ratio,
    :dictionary, :cue_words
  

  def count_points_for_sentence(sentence, index, tokens, tokens_frequency, sentences_count, title_tokens)
    points = Hash.new 0
    points[:title_tokens] = 0
    tokens.each do |token|
      points[:word_frequency_at_article] += tokens_frequency[token] * word_frequency_at_article_weight
      points[:title_tokens] += title_tokens_weight if title_tokens.include? token
      points[:word_frequency_at_dictionary] += dictionary[token].to_i * word_frequency_at_dictionary_weight
    end
    points[:cue_words] = 0
    points[:position] = 0
    if sentence_is_at_premium_position?(index, sentences_count)
      points[:position] += sentence_position_weight 
    end
    cue_words.each do |cue_word|
      points[:cue_words] += cue_words_weight if sentence.include? cue_word
    end
    points.values.each do |value|
      points[:total] += value
    end
    points
  end

  def sentence_is_at_premium_position?(index, sentences_count)
    index <= premium_position_ratio * sentences_count ||
    index >= (1 - premium_position_ratio) * sentences_count
  end

  def choose_best_sentences(sentences_ranking, sentences, article_length)
    sentences_ranking.map do |ranked_sentence|
      ranked_sentence.last[:sentence] = sentences[ranked_sentence.first]
      ranked_sentence
    end.to_h
  end
end