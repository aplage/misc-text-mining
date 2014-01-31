#!/usr/bin/env ruby
# (c) Copyright 2014 mkfs <https://github.com/mkfs>
# Interface to RsRuby (https://github.com/alexgutteridge/rsruby)

require 'rubygems'
require 'rsruby'


=begin rdoc
R_HOME : top-level directory of the R installation to run
=end

module RInterface
  def self.init(dir=nil)
    # set R_HOME to location of R install
    ENV['R_HOME'] ||= (dir || detect_r)
    if ! (File.exist? ENV['R_HOME'].to_s)
      raise "Set R_HOME env-var to R install directory"
    end

    r = RSRuby.instance
    fix_graphics(r)
    r
  end

=begin rdoc
Detect the install location of R on *NIX using the `which` command.
=end
  def self.detect_unix_r
    path = `which R`
    return nil if (! path) || path.empty?

    path = File.join( path.split('/bin/R')[0], 'lib', 'R' )
    (File.exist? path) ? path : nil
  end

=begin rdoc
Return the top-level directory of the system R installation.
=end
  def self.detect_r
    case RUBY_PLATFORM
    when /win32/ 
      'C:/Program Files/R'  # probably wrong
    when /linux/, /freebsd/
      detect_unix_r || '/usr/lib/R'
    when /darwin/
      '/Library/Frameworks/R.framework/Resources'
    when /freebsd/
      detect_unix_r || '/usr/local/lib/R'  # probably wrong
    else
      nil
    end
  end

=begin rdoc
Some R graphics subsystems don't play nice on the command line. This fixes that.

Note: This is only necessary if plotting to a widget.
=end
  def self.fix_graphics(r)
    fix = nil
    case RUBY_PLATFORM
    when /linux/, /freebsd/
      fix = 'graphics.off(); X11.options(type="Xlib")'
    when /darwin/
      fix = 'graphics.off(); X11.options(type="nbcairo")'
    end
    r.eval_R(fix) if fix
  end
end
