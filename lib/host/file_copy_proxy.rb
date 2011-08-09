module Host
  class FileProxyCopy
    def initialize host, path
      @host = host
      @path = path
    end

    def to host, path #path must be a directory here.
      # ensure that the base path exists
      if path.end_with? '/'
        to = { 
          :path => path,
          :name => File.basename @path
        }
      else
        raise Exception, 'Destination must be a directory spec (trailing slash). <#{path}> was given.'
      end

      host.mkdir( to[:path] )
      case
      when @host == host
        host.copy( @path, File.join(to[:path],to[:name]) )
      when @host.ssh? and host.ssh? and false
        # there has to be a better way
      else 
        Open3.pipeline(
          @host._tar( @path,true ),
          host._untar( to[:path],true )
        )
        return File.join( to[:path], to[:name] )
      end
    end
  end
end