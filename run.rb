require './article'
require './rank_sentences'

filename = 'articles/25'

article = Article.new(filename)

ranker = RankSentences.new

puts ranker.rank(article)