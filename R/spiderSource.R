#!/usr/bin/env Rscript
# (c) Copyright 2014 mkfs <https://github.com/mkfs>
# spiderSource: a replacement for tm.plugin.webmining WebSource which
#               spiders URLs instead of simply downloading them.

library(XML)
library(RCurl)
library(tm)
library(tm.plugin.webmining)

uri.domain <- function(url) {
  hostname <- tryCatch(
		       strsplit(gsub("^[[:alpha:]]+://", "", url), "/")[[1]][1],
		       error=function(e) { return("") }
		       )

  if ( nchar(hostname) == 0 ) return("")
  
  # this removes all components < 3 letters from start of hostname
  arr <- strsplit(hostname, "[.]")[[1]]
  n <- which(sapply(arr, function(x) nchar(x) > 3 ))[1]
  if ( is.na(n) ) n <- 1
  
  return( paste(arr[ n:length(arr) ], collapse='.') )
}

clean.url <- function(urls) {
    urls <- gsub( "^//", "", urls )
    urls <- gsub( "/$", "", urls )
    # remove in-page references
    urls <- urls[grep("^[^#]", urls)]
    urls <- urls[grep("^javascript", urls, invert=TRUE)]
    return( urls )
}

# this is a replacement for WebSource
spiderSource <- function(feedurls, class = "WebXMLSource", parser = NULL, 
			                   encoding = "UTF-8", cross.domains = FALSE, 
			                   depth = 10, vectorized = FALSE, 
                         curlOpts = curlOptions(followlocation = TRUE,
                                                maxconnects = 20, 
                                                maxredirs = 10, 
                                                timeout = 30, 
                                                connecttimeout = 30) ) {
  
  if ( is.null(parser) ) {
    parser <- function(x) try(parse(x, useInternalNodes=T, type='HTML'))
  }
  
  next.urls <- feedurls   # URLs to be downloaded
  fetched.urls <- c()     # URLs downloaded so far
  visited.domains <- c()  # maintain list of hosts visited
  out.edges <- list()     # out-edges for each URL
  parsed.content <- c()   # parsed XML trees
  
  if (depth < 1) depth <- 1
  for ( i in 1:depth ) {
    if ( length(next.urls) < 1 ) next
    
    # TODO: replace with per-url loop
    html.raw <- list()
    for (url in next.urls) {
      html.raw[[url]] <- tryCatch(
        getURLContent(url, binary=NA, .opts = curlOpts),			
        # On CURL error, return a blank HTML page
        error=function(e) { warning(paste("ERROR DOWNLOADING", url)); 
                            warning(e);
                            return("<html>\n</html>\n"); 
                          } 
      )
    }
    
    # store domains that have been visited
    domains <- sapply(next.urls, uri.domain)
    visited.domains <- unique( c(visited.domains, domains) )
    # store visited URLs
    fetched.urls <- c(fetched.urls, next.urls)
    
    # parse HTML
    html.tree <- lapply( html.raw, parser )
    
    # save parsed HTML content for output
    parsed.content <- c(parsed.content, html.tree)
    
    # extract HREF elements from A tags
    urls <- lapply(html.tree, function(x) xpathSApply(x, "//a/@href"))
    urls <- lapply(urls, clean.url)
    # remove self-references
    for (n in names(urls)) {
      vec <- urls[[n]]
      urls[[n]] <- vec[ vec != n ]
    }
    
    if (! cross.domains ) {
      for (n in names(urls)) {
        vec <- urls[[n]]
        urls[[n]] <- vec[ which( sapply(vec, uri.domain) %in% visited.domains ) ]

      }
    }

    # queue all URLs that have not yet been downloaded
    out.edges <- c(out.edges, urls)
    next.urls <- unique(unlist(lapply(urls,
                 function (vec) vec[which(! vec %in% fetched.urls)] )))
    
  }
  
  obj <- tm:::.Source(NULL, encoding, length(parsed.content), FALSE, NULL, 0, 
                      vectorized, class = class)
  obj$Content <- parsed.content
  obj$Feedurls <- feedurls
  obj$Parser <- parser
  obj$CurlOpts <- curlOpts
  obj$DepthOption <- depth
  obj$CrossDomainsOption <- cross.domains
  obj$OutEdges <- out.edges

  obj
}
