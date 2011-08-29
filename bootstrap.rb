#bootstrap.rb
require "rubygems"
require "bundler"
Bundler.setup

require 'active_support/dependencies'

APPROOT = File.absolute_path( File.dirname( __FILE__ ) ) 
libdir = File.join( APPROOT, 'lib' )
ActiveSupport::Dependencies.autoload_paths << libdir
$: << libdir
