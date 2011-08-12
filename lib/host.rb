require 'timeout'
require 'Open3'

module Host
  class Base
    include TestBenchFactor
    include PhpIni::Inheritable

    # ensure we have access to all of them
    def self.new(*args)
      host = super
      @@hosts||=[]
      @@hosts << host
      host
    end

    def [](property)
      @properties[property.to_sym]
    end

    def initialize(properties={})
      @properties = properties.dup
    end

    def exec command, opts={}
      # wrap the command
      command = _wrap command

      watcher = Thread.start do
        o,e,w = Open3.capture3( command, opts )
      end
    end

    def exec! command, opts={}
      timeout_sec = opts.delete(:timeout)
      timeout timeout_sec do
      timeout timeout_sec do # hackish double-timeout per this bug report http://redmine.ruby-lang.org/issues/4681
          o,e,w = exec( command, opts ).value
      end # end hackish double-timeout
      end
    end
    alias :exec_and_wait :exec!

    def copy( from, to )
      exec "cp #{from} #{to}"
    end

    def move( from, to )
      exec "mv #{from} #{to}"
    end

    def delete( path )
      case path
      when /\A(\/(bin|var|etc|dev)?)\Z/
        raise Exception, "cannot delete #{path}"
      else 
        exec "rm -rf path"
      end
    end

    def mkdir( path )
      exec "mkdir -p #{path}"
    end

    # returns Host::FileCopyProxy
    def deploy(file)
      Host::FileCopyProxy(self,file)
    end

    def _tar( file_or_dir, compress=false )
      "tar -c#{ compress ? 'z' : ''} #{file_or_dir}"
    end

    def _untar( path, decompress=false )
      "tar -C #{path} -x#{ compress ? 'z' : ''}"
    end

    def _wrap( command )
      command
    end
  end
end