module Host
  class Local < Base
    def exec command, opts={}
      watcher = Thread.start do
        o,e,w = Open3.capture3( command, opts )
      end
    end

    def copy src, dest
      FileUtils.cp_r src, dest
    end
    alias :upload, :copy
    alias :download, :copy

    def exist? file
      File.exist? file
    end

    def directory? path
      exist? path && File.directory? path
    end

    def open_file path, &block
      File.open path, &block
    end

    # list the immediate children of the given path
    def list path
      Dir.entries( dir ).map do |entry|
        next nil if ['.','..'].include? entry
        File.join( path, entry )
      end.compact
    end

    def glob spec, &block
      Dir.glob spec, &block
    end

    protected

    def _delete path
      File.delete path
    end

    def _mkdir path
      Dir.mkdir path
    end
  end
end