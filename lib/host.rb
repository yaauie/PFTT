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

    def wrap! command
      command.replace( wrap command )
    end

    def wrap command
      %Q{pushd #{cwd} > /dev/null 2>&1 && #{command} && popd > /dev/null 2>&1}
    end

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

    def windows?
      # avoids having to check for c:\windows|c:\winnt if we've already found /usr/local
      true #@is_windows ||= ( !posix? and ( exist? "C:\\Windows" or exist? "C:\\WinNT" ) )
    end

    def posix?
      false #@posix ||= self.properties[:platform] == :posix
    end

    # executes command or program on the host
    #
    # can be a DOS command, Shell command or a program to run with options to pass to it
    def cmd! cmdline
      if windows?
        cmdline = "CMD /C #{cmdline}"
      end
      return exec!(cmdline)
    end
    
    # executes command using cmd! returning the first line of output (STDOUT) from the command,
    # with the new line character(s) chomped off
    def line! cmdline
      cmd!(cmdline)[0].chomp
    end

   def make_absolute! *paths
      paths.map do |path|
        #escape hatch for already-absolute windows paths
        return path if windows? && path =~ /\A[A-Za-z]:\// 
        
        path.replace( File.absolute_path( path, cwd ) )
        path
      end
    end
        
    # changes the current working directory 
    def cd path, hsh
      make_absolute! path
      if not path
        # popd may have been called when @dir_stack empty
        raise "path not specified"
      end
      # e-z, same command on posix and windows
      cmd!("cd \"#{path}\"")
      
      # @cwd is cleared at start of exec, so while in exec, @cwd will be empty unless cwd() called in another thread
      @cwd = path
      
      @dir_stack.clear unless hsh.delete(:no_clear) || false
      
      return path
    end
    
    def pushd path
      cd(path, {:no_clear=>true})
      @dir_stack.push(path)
    end
    
    def popd
      cd(@dir_stack.pop, {:no_clear=>true})
    end
    
    def peekd
      @dir_stack.last
    end
    
    def join *path_array
      path_array.join(separator)
    end
    
    # returns the directory path separator character for the host platform
    def separator
      if windows?
        return '\\'
      else
        return '/'
      end  
    end
    
    # deletes the given file, directory or matching glob pattern
    def delete glob_or_path
      if directory?(p)
       _delete_glob(p, '')
      else
        _delete_glob(cwd, glob_or_path)
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

    # makes the given directory if it is not already a directory (if it is, this fails silently)
    def mkdir path
      make_absolute! path
      parent = File.dirname path
      mkdir parent unless directory? parent
      if not directory? path
        _mkdir path
      end
    end

    def mktmpdir path
      make_absolute! path
      tries = 10
      begin
        dir = join( path, String.random(16) )
        raise 'exists' if directory? dir
        mkdir dir
      rescue
        retry if (tries -= 1) > 0
        raise $!
      end
      dir
    end

    def sane? path
      make_absolute! path
      insane = case
      when posix?
        /\A\/(bin|var|etc|dev|Windows)\Z/
      else
        /\AC:(\/(Windows)?)?\Z/
      end =~ path
      !insane
    end

    class << self
      # create a way for a class to register itself as instantiable by the Factory function
      def instantiable name
        Host.hosts.merge! name => self
      end
    end

    private

    def _delete_glob p, q
      make_absolute! p
      glob(p, q ) do |path|
        raise Exception unless sane? path
        if directory? path
          cmd! case
          when posix? then %Q{rm -rf \""#{path}\""}
          else %Q{RMDIR /S /Q \""#{path}\""}
          end
        end
        _delete path #implementation specific
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
