require 'yaml'
require 'byebug'

class RankSentences
  WORD_FREQUENCY_AT_ARTICLE_WEIGHT = 2.freeze
  WORD_FREQUENCY_AT_DICTIONARY_WEIGHT = 0.1.freeze
  TITLE_TOKENS_WEIGHT = 10.freeze
  SENTENCE_POSITION_WEIGHT = 4.freeze
  CUE_WORDS_WEIGHT = 5.freeze
  DICTIONARY = YAML::load_file('./dictionary.yml')

  PREMIUM_POSITION_RATIO = 0.1.freeze

  CUE_WORDS = YAML::load_file('./cue_words.yml')

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
  

  def count_points_for_sentence(sentence, index, tokens, tokens_frequency, sentences_count, title_tokens)
    points = 0
    tokens.each do |token|
      points += tokens_frequency[token] * WORD_FREQUENCY_AT_ARTICLE_WEIGHT
      points += TITLE_TOKENS_WEIGHT if title_tokens.include? token
      points += DICTIONARY[token].to_i * WORD_FREQUENCY_AT_DICTIONARY_WEIGHT
    end
    if sentence_is_at_premium_position?(index, sentences_count)
      points += SENTENCE_POSITION_WEIGHT 
    end
    CUE_WORDS.each do |cue_word|
      points += CUE_WORDS_WEIGHT if sentence.include? cue_word
    end
    points
  end

  def sentence_is_at_premium_position?(index, sentences_count)
    index <= PREMIUM_POSITION_RATIO * sentences_count ||
    index >= (1 - PREMIUM_POSITION_RATIO) * sentences_count
  end

  def choose_best_sentences(sentences_ranking, sentences, article_length)
    sentences_ranking = (sentences_ranking.sort { |a, b| b.last <=> a.last })
    summary_length = 0
    summary = []
    sentences_ranking.each do |ranked_sentence|
      summary.push(ranked_sentence)
      summary_length += sentences[ranked_sentence.first].length
      break if summary_length > 0.1 * article_length
    end
    summary.sort  { |a, b| a.first <=> b.first }  
    summary.map { |ranked_sentence| sentences[ranked_sentence.first] }
  end
end