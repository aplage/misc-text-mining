#!/usr/bin/env ruby
# (c) Copyright 2014 mkfs <https://github.com/mkfs>
# usage: target [target...]

require 'ostruct'
require 'optparse'

load File.join(File.dirname(__FILE__), "r_interface.rb")

$DEBUG = false

def disasm(path, opts)
  # TODO:
  #if ! `which objdump`.empty?

  terms = `objdump -DRTgrstx '#{path}'`.lines.inject([]) do |arr, line|
    if (opts.mnemonic)
      if line =~ /^\s*[[:xdigit:]]+:[[:xdigit:]\s]+\s+([[:alnum:]]+)\s*/
        arr << $1
      end
    else
      arr << $1 if line =~ /<([_[:alnum:]]+)(@[[:alnum:]]+)?>\s*$/
    end
    arr
  end

  # puts terms.inspect
  terms.join(" ")
end

def disasm_wordcloud(path, opts)
  img_path = File.basename(path) + '.png'
  terms = disasm(path, opts)

  begin
    $r.eval_R("corpus <- Corpus(VectorSource('#{terms}'))")
    $r.eval_R("tdm <- TermDocumentMatrix(corpus)")
    $r.eval_R("vec <- sort(rowSums(as.matrix(tdm)), decreasing=TRUE)")
    $r.eval_R("df <- data.frame(word=names(vec), freq=vec)")
    $r.eval_R("png(file='#{img_path}')")
    # TODO: transparent option
    #$r.eval_R("png(file='#{img_path}', bg='transparent')")
    $r.eval_R("wordcloud(df$word, df$freq, min.freq=1)")
    # TODO: min freq option
    #$r.eval_R("wordcloud(df$word, df$freq, min.freq=3)")
    $r.eval_R("dev.off()")
  rescue RException => e
    $stderr.puts e.message
    $stderr.puts e.backtrace[0,3]
  end
end

  # ----------------------------------------------------------------------

def handle_options(args)

  options = OpenStruct.new
  options.targets = []
  options.r_dir = nil
  options.mnemonic = false

  opts = OptionParser.new do |opts|
    opts.banner = "Usage: #{File.basename $0} TARGET [...]"
    opts.separator ""

    opts.separator "Summary Options:"
    opts.on('-m', '--mnemonic', 'Count mnemonics') {options.mnemonic = true} 

    opts.separator "Misc Options:"
    opts.on('-d', '--debug', 'Print debug output') { $DEBUG = true } 
    opts.on('--r-dir str', 'Top-level directory of R installation') { |str|
      options.r_dir = str }
    opts.on_tail('-h', '--help', 'Show help screen') { puts opts; exit 1 }
  end

  opts.parse! args

  while args.length > 0
    options.targets << args.shift
  end

  if options.targets.empty?
    $stderr.puts 'TARGET REQUIRED'
    puts opts
    exit -1
  end

  options
end

# ----------------------------------------------------------------------
if __FILE__ == $0
  options = handle_options(ARGV)
  $r = RInterface.init options.r_dir
  $r.eval_R("suppressMessages(library('tm'))")
  $r.eval_R("suppressMessages(library('wordcloud'))")
  options.targets.each do |path|
    disasm_wordcloud( path, options )
  end
end
