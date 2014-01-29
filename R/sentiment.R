#!/usr/bin/env Rscript
# Example of using the R textmining sentiment plugin
# (c) Copyright 2014 mkfs <https://github.com/mkfs>

library(tm)
library(tm.plugin.sentiment)

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
the.corpus <- Corpus(VectorSource(input.data))
#print(summary(wc_corpus))

# invoke sentiment!
the.corpus <- score(the.corpus)
sentiment.scores <- meta(the.corpus)

# produce report
print(paste("Polarity (p - n / p + n):", 
            str(sentiment.scores$polarity, vec.len=20)))
print(paste("Subjectivity (p + n / N):", 
            str(sentiment.scores$subjectivity, vec.len=20)))
print(paste("Positive Refs Per-Ref (p / N):", 
            str(sentiment.scores$pos_refs_per_ref, vec.len=20)))
print(paste("Negative Refs Per-Ref (n / N):", 
            str(sentiment.scores$neg_refs_per_ref, vec.len=20)))
print(paste("Sentiment Differences Per-Ref (p - n / N) :", 
            str(sentiment.scores$senti_diffs_per_ref, vec.len=20)))