#!/usr/bin/env Rscript
# Example of using the R wordcloud and textmining packages
# (c) Copyright 2014 mkfs <https://github.com/mkfs>

library(tm)

# function to remove contractions in an English-language source
fix.contractions <- function(doc) {
	# "won't" is a special case as it does not expand to "wo not"
	doc <- gsub("won't", "will not", doc)
	doc <- gsub("n't", " not", doc)
	doc <- gsub("'ll", " will", doc)
	doc <- gsub("'re", " are", doc)
	doc <- gsub("'ve", " have", doc)
	doc <- gsub("'m", " am", doc)
	# 's could be 'is' or could be possessive: it has no expansion
	doc <- gsub("'s", "", doc)
	return(doc)
}

# function to combine single and plural variants in a term-frequency vector
aggregate.plurals <- function (v) {
	aggr_fn <- function(v, singular, plural) {
		if (! is.na(v[plural])) {
			v[singular] <- v[singular] + v[plural]
			v <- v[-which(names(v) == plural)]
		}
		return(v)
	}
	for (n in names(v)) {
		n_pl <- paste(n, 's', sep='')
		v <- aggr_fn(v, n, n_pl)
		n_pl <- paste(n, 'es', sep='')
		v <- aggr_fn(v, n, n_pl)
	}
	return(v)
}

# ----------------------------------------------------------------------
# inane sample data
input.data = c( "The dog is happy.",
    "They milked the cows, and then they made cheese and butter.",
    "The dog, which is eating the bone, is happy, but the cat is sad.",
    "Is the dog happy?", "That dog is the happiest dog I have ever seen!",
    "Give the dog a bone.", "The sky is blue.", "Today is Monday.",
    "Tomorrow is Tuesday.", "The baby is smiling.", "This is the road to take.",
    "Read a book about the history of America.",
    "There are beautiful flowers growing in the garden.",
    "The cushions are new and I can experience the comfort well." )

# From directory of plaintext documents:
#wc_corpus <- Corpus(DirSource('/tmp/wc_documents'))
# From directory of PDF documents:
#wc_corpus <- Corpus(DirSource('/tmp/wc_documents'), readerControl=readPDF)
# From character vector:
wc_corpus <- Corpus(VectorSource(input.data))
#print(summary(wc_corpus))

# convert all text to lowercase
wc_corpus <- tm_map(wc_corpus, tolower)
# remove all_contractions
wc_corpus <- tm_map(wc_corpus, fix.contractions)
# remove all punctuation
wc_corpus <- tm_map(wc_corpus, removePunctuation)
# remove all "noise words"
wc_corpus <- tm_map(wc_corpus, removeWords, stopwords('english'))
# stem the words in the corpus
# wc_corpus <- tm_map(wc_corpus, stemDocument)

td_mtx <- TermDocumentMatrix(wc_corpus, control = list(minWordLength = 3))

# create sorted list of words in document along with their frequency count
v <- sort(rowSums(as.matrix(td_mtx)), decreasing=TRUE)

# combine singular and plural forms of words
v <- aggregate.plurals(v)

# create a data frame for passing to the wordcloud package
df <- data.frame(word=names(v), freq=v)
# print(df$word)

# invoke wordcloud!
library(wordcloud)
wordcloud(df$word, df$freq, min.freq=1)

# save wordcloud to PNG file:
#png(file='wordcloud.png', bg='transparent')
#wordcloud(df$word, df$freq, min.freq=3)
#dev.off()
