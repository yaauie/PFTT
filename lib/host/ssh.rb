module Host
  class Ssh < Base
    instantiable 'ssh'

    def initialize opts={}
      options = opts.dup
      @credentials = {
        :host_name => options.delete(:address),
        :user => options.delete(:username),
        :password => options.delete(:password)
      }
      super options
    end

    def exec command, opts={}
      wrap! command unless ( opts.delete(:nowrap) || false )
      
      Thread.start do
        
        stdout, stderr = '',''
        exit_code = -254
        
        @ssh.open_channel do |channel|
          unless success
            exit_code = -255
            raise "could not execute command #{command}"
          end

          channel.on_request 'exit-status' do |ch, data| 
            exit_code = data.read_long
          end 

          channel.on_request 'exit-signal' do |ch, data|
            # if remote process killed, etc... won't get a normal exit code
            # instead, try to generate exit_code from optional exit-signal
            exit_code = case
            when data.inspect.include?('KILL') then 9  # SIGKILL
            when data.inspect.include?('SEGV') then 11 # SIGSEGV (crash)
            when data.inspect.include?('TERM') then 15 # SIGTERM
            when data.inspect.include?('HUP')  then 1  # SIGHUP
            when exit_code == -254 then data.inspect
            else exit_code
            end
          end

          channel.on_data do |ch, data|
            stdout += data.inspect
          end

          channel.on_extended_data do |ch, type, data|
            case type
            when 1 then stderr += data.inspect
            end
          end

          channel.wait # cause this thread to wait
        end

        [stdout, stderr, exit_code]
      end
    end

    def copy src, dest
      make_absolute! src, dest
      dir = directory? dest
      exec! case
      when posix? then %Q{cp -R "#{src}" "#{dest}"}
      else %Q{CMD /C copy "#{src}" "#{dest}"}
      end
      ( dir ? File.join( dest, File.basename(src) ) : dest )
    end

    def deploy local_file, remote_path
      make_absolute! remote_path
      sftp.upload local_file, remote_path
    end

    def directory? path
      make_absolute! path
      sftp.file.directory? path
    end

    def exist? path
      make_absolute! path
      sftp.stat!(path).exists?
    end

    def list(path)
      make_absolute! path
      sftp.dir.entries(path).map do |entry| 
        next nil if ['.','..'].include? entry.name
        File.join( path, entry.name )
      end.compact
    end

    def glob spec, &blk
      make_absolute! spec
      matches sftp.glob( cwd, spec ).map do |entry|
        next nil if ['.','..'].include? entry.name
        File.absolute_path( entry.name, cwd )
      end.compact
      if block_given?
        matches.each &blk
        nil
      else
        matches
      end
    end

    def open_file path, flags='r',&block
      make_absolute! path
      sftp.file.open path, flags, &block
    end

    def upload local_file, remote_path
      make_absolute! remote_path
      dir = directory? remote_path
      sftp.upload! local_file, remote_path
      ( dir ? File.join( remote_path, File.basename(local_file) ) : remote_path )
    end

    def download remote_file, local_path
      make_absolute! remote_file
      dir = File.directory? local_path
      sftp.download! remote_file, local_path
      ( dir ? File.join( local_path, File.basename(remote_file) ) : local_path )
    end

    protected

    def _delete path
      make_absolute! path
      @sftp.delete! path
    end

    def _mkdir path
      make_absolute! path
      @sftp.mkdir! path
    end

    private
     
    def ssh
      @ssh ||= Net::SSH.start( nil, nil, @credentials )
    end

    def sftp
      @sftp ||= Net::SFTP::Session.new ssh
      @sftp.loop { sftp.opening? }
    end
  end
end
