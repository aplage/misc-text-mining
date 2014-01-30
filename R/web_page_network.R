#!/usr/bin/env Rscript
# (c) Copyright 2014 mkfs <https://github.com/mkfs>

# NOTE: this assumes that spiderSource.R is in the current directory
source("spiderSource.R")

input.urls <- c(
  # docs:
  "http://www.rdatamining.com/examples/text-mining",
  "http://www.rdatamining.com/examples/time-series-clustering-classification",
  "http://www.statsoft.com/Textbook/Text-Mining",
  "http://www.togaware.com/datamining/survivor/Contents.html",
  # blogs:
  "http://blog.revolutionanalytics.com/2014/01/topological-data-analysis-with-r.html",
  "http://www.r-bloggers.com/word-cloud-in-r/",
  "https://stackoverflow.com/questions/439526/thinking-in-vectors-with-r",
  "http://onertipaday.blogspot.com/2011/11/weather-forecast-and-good-development.html",
  "http://matchesmalone.com/?p=52",
  "http://www.r-bloggers.com/simple-text-mining-with-r/",
  # misc:
  "https://www.kaggle.com/competitions",
  "http://visual.ly/",
  "http://www.findthedata.org/"
)

# ----------------------------------------------------------------------

print("Downloading content...")
the.source <- spiderSource(input.urls)
print(summary(the.source))
# TODO: custom parser

print("Creating Corpus...")
the.corpus <- Corpus(the.source)
print(summary(the.corpus))
