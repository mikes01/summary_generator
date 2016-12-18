require './article'
require './rank_sentences'
require './domain_dictionary_generator'

filename = 'articles/01'
article = Article.new(filename)
ranker = RankSentences.new
puts ranker.rank(article)

#DomainDictionaryGenerator.new('./articles').generate_dictionary