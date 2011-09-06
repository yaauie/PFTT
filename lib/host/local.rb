require 'fileutils'

module Host
  class Local < Base
    instantiable 'local'

    def exec command, opts={}
      wrap! command unless ( opts.delete(:nowrap) || false )
      puts %Q{running> #{command}}
      watcher = Thread.start do
        retries = 3
        begin
          o,e,w = Open3.capture3( command, opts )
        rescue
          if (retries-=1) >= 0
            sleep 2
            retry
          end
          raise $!
        end
      end
    end

    def copy src, dest
      make_absolute! src, dest
      #puts %Q{copy( #{src.inspect}, #{dest.inspect} )}
      # copy does this normally, but we will ensure it 
      # happens consistently before we descend
      if directory? dest
        dest = File.join( dest, File.basename(src) )
      end
      
      FileUtils.cp_r( src, dest, :preserve=>false )

      return dest
    end
    alias :upload :copy
    alias :download :copy

    def exist? file
      make_absolute! file
      File.exist? file
    end

    def directory? path
      make_absolute! path
      exist?(path) && File.directory?(path)
    end

    def open_file path, flags='r', &block
      make_absolute! path
      File.open path, flags, &block
    end
    
    # list the immediate children of the given path
    def list path
      make_absolute! path
      Dir.entries( path ).map do |entry|
        next nil if ['.','..'].include? entry
        entry
      end.compact
    end

    def glob spec, &block
      make_absolute! spec
      Dir.glob spec, &block
    end

    protected

    def _delete path
      make_absolute! path
      File.delete path
    end

    def _mkdir path
      make_absolute! path
      Dir.mkdir path
    end
  end
end