#!/usr/bin/env ruby
# disasm_wordcloud : Generate a wordcloud image (using R) for the symbols or
# instruction mnemonics in a binary. The binary is disassembled with
#    objdump -DRTgrstx 
# and symbols are counted only if they are referenced as an instruction operand.
# (c) Copyright 2014 mkfs <https://github.com/mkfs>
# Examples:
#   generate wordcloud image 'a.out.png' for library symbols:
#     disasm_wordcloud.rb /tmp/a.out
#   write output to file '/tmp/wordcloud.png' instead:
#     disasm_wordcloud.rb -o /tmp/wordcloud.png /tmp/a.out
#   generate wordcloud image for instruction mnemonics:
#     disasm_wordcloud.rb -m /tmp/a.out
#   invert frequencies of mnemonics so least-used appear larger:
#     disasm_wordcloud.rb -m -i /tmp/a.out

require 'ostruct'
require 'optparse'

load File.join(File.dirname(__FILE__), "r_interface.rb")

$DEBUG = false

def disasm(path, opts)
  if `which objdump`.empty?
    raise "objdump not found!"
  end

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

  puts terms.inspect if $DEBUG
  terms.join(" ")
end

def output_filename(path, opts)
  filename = File.basename(path) + '.png'
  if opts.filename
    if opts.targets.length == 1
      return opts.filename
    else
      opts.filename + '.' + filename
    end
  end
  filename
end

def disasm_wordcloud(path, opts)
  img_path = output_filename path, opts
  terms = disasm(path, opts)

  begin
    $stderr.puts "Evaluating: Corpus(VectorSource('#{terms}')" if $DEBUG
    $r.eval_R("corpus <- Corpus(VectorSource('#{terms}'))")

    $stderr.puts "Evaluating: TermDocumentMatrix(corpus)" if $DEBUG
    $r.eval_R("tdm <- TermDocumentMatrix(corpus)")

    $stderr.puts "Evaluating: sort(rowSums(as.matrix(tdm)))" if $DEBUG
    $r.eval_R("vec <- sort(rowSums(as.matrix(tdm)), decreasing=TRUE)")

    if opts.invert
      $stderr.puts "Evaluating: (max(vec) + 1) - vec" if $DEBUG
      $r.eval_R("vec <- (max(vec) + 1) - vec")
    end

    $stderr.puts "Evaluating: data.frame(word=names(vec), freq=vec)" if $DEBUG
    $r.eval_R("df <- data.frame(word=names(vec), freq=vec)")

    trans = opts.trans ? ", bg='transparent'" : ""
    $stderr.puts "Evaluating: png(file='#{img_path}'#{trans})" if $DEBUG
    $r.eval_R("png(file='#{img_path}'#{trans})")

    $stderr.puts "Evaluating: wordcloud(df$word, df$freq)" if $DEBUG
    $r.eval_R("wordcloud(df$word, df$freq, min.freq=#{opts.min})")

    $stderr.puts "Evaluating: dev.off()" if $DEBUG
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
  options.filename = nil
  options.mnemonic = false
  options.trans = false
  options.invert = false
  options.min = 1

  opts = OptionParser.new do |opts|
    opts.banner = "Usage: #{File.basename $0} TARGET [...]"
    opts.separator ""

    opts.on('-f', '--min-freq', 'Minimum frequency (1)') { |num| 
      options.min = Integer(num) } 
    opts.on('-i', '--invert', 'Invert frequency counts') { 
      options.invert = true } 
    opts.on('-m', '--mnemonic', 'Use mnemonics instead of symbols') { 
      options.mnemonic = true } 
    opts.on('-o', '--output', 'Outout filename') { |str| 
      options.filename = str } 
    opts.on('-t', '--trans', 'Transparent image background') { 
      options.trans = true } 
    opts.on('--r-dir str', 'Top-level directory of R installation') { |str|
      options.r_dir = str }

    opts.on('-d', '--debug', 'Print debug output') { $DEBUG = true } 
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
  $stderr.puts "Initializing R" if $DEBUG
  $r = RInterface.init options.r_dir

  $stderr.puts "Loading package 'tm'" if $DEBUG
  $r.eval_R("suppressMessages(library('tm'))")

  $stderr.puts "Loading package 'wordcloud'" if $DEBUG
  $r.eval_R("suppressMessages(library('wordcloud'))")

  options.targets.each do |path|
    $stderr.puts "Processing target '#{path}'" if $DEBUG
    disasm_wordcloud( path, options )
  end
end
