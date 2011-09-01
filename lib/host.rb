require 'Open3'

module Host
  class << self
    def Factory( options )
      (Host.hosts[options.delete('type')||'local']).new options
    end

    def hosts
      @@hosts||={}
    end
  end

  class Base
    include TestBenchFactor
    include PhpIni::Inheritable

    def initialize opts={}
      #set the opts as properties in the TestBenchFactor sense
      opts.each_pair do |key,value|
        property key => value
      end
    end

    def describe
      @description ||= self.properties.values.join('-').downcase
    end

    def exec! *args
      exec(*args).value
    end

    def posix?
      @posix ||= self.properties[:platform] == :posix
    end

    # caching this is dangerous, since we can change this pretty easily with exec,
    # but because we have to shell out *every time* we want to get this, it needs to
    # be cached somehow.
    def cwd 
      @cwd ||= [case
      when posix? then exec!('pwd')[0]
      else exec!(%Q{CMD /C ECHO %CD%})[0].gsub(/\r?\n\Z/,'')
      end]
      @cwd.last
    end

    def delete glob_or_path
      glob( glob_or_path ) do |path|
        raise Exception unless sane? path
        if directory? path
          exec! case
          when posix? then %Q{rm -rf "#{path}"}
          else %Q{CMD /C RMDIR /S /Q "#{path}"}
          end
        else
          _delete path #implementation specific
        end
      end
    end

    def escape(str)
      if !posix?
        s = str.dup
        s.replace %Q{"#{s}"} unless s.gsub!(/([>&^"])/,'\\\\\1').nil?
        s
      else
        raise NotImplementedYet
      end
    end

    def mkdir path
      parent = File.dirname path
      mkdir parent unless directory? parent
      _mkdir path
    end

    def mktmpdir path
      tries = 10
      begin
        dir = File.join( path, String.random(16) )
        raise 'exists' if directory? dir
        mkdir dir
      rescue
        retry if (tries -= 1) > 0
        raise $!
      end
      dir
    end

    def sane? path
      insane = case
      when posix?
        /\A\/(bin|var|etc|dev|Windows)\Z/
      else
        /\AC:(\/(Windows)?)?\Z/
      end =~ File.absolute_path( path, cwd )
      !insane
    end

    class << self
      # create a way for a class to register itself as instantiable by the Factory function
      def instantiable name
        Host.hosts.merge! name => self
      end
    end
  end

  require 'typed-array'
  
  class Array < TypedArray(Base)
    # make it filterable
    include TestBenchFactorArray


    def load( path )
      path = File.absolute_path( path )
      config = Hash.new
      return self unless File.exist? path or Dir.exist? path
      if File.directory? path
        Dir.glob( File.join( path, '**', '*.yaml' ) ) do |file|
          config[File.basename( file, '.yaml' )]= YAML::load( File.open file )
        end
      else
        config.merge! YAML::load( File.open path )
      end
      config.each_pair do |name,spec|
        self << Host::Factory( spec.merge(:name=>name) )
      end
      self
    end
  end
end

# Load up all of our middleware classes right away instead of waiting for the autoloader
# this way they are actually available in Middleware::All
# although it technically does not matter the order in which they are loaded (as they will trigger
# autoload events on missing constants), reverse tends to get shallow before deep and should improve
# performance, if only marginally.
Dir.glob(File.join( File.dirname(__FILE__), 'host/**/*.rb')).reverse_each &method(:require)
