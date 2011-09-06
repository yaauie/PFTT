
require 'net/ssh'
require 'net/sftp'

# Supported SSH Servers:
# * OpenSSH on Linux (sshd)
# * PFTT's SSHD for Windows - based on Apache SSHD
#

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
    
    def alive?
      begin
        return exist?(cwd())
      rescue
        closed_sftp
        return false
      end
    end 
    
    def to_s
      if posix?
        "Remote Posix "+@credentials[:host_name]
      else
        "Remote Windows "+@credentials[:host_name]
      end
    end

    def exec command, opts={}
      @cwd = nil # clear cwd cache
      
      Thread.start do
        
        stdout, stderr = '',''
        exit_code = -254 # assume error unless success
        
        ssh.open_channel do |channel|
          channel.exec(command) do |channel, success|
            unless success
              exit_code = -255
              raise "could not execute command #{command}"
            end
            channel.on_data do |ch, data|
              # important: don't do data.inspect!
              # that'll replace \ characters with \\ and \r\n with \\r\\n (bad!!)
              stdout += data
            end
            
            channel.on_extended_data do |ch, type, data|
              case type
              when 1 then stderr += data
              end
            end
                        
            channel.on_request 'exit-status' do |ch, data|
              exit_code = data.read_long
            end

            channel.on_request 'exit-signal' do |ch, data|
              # if remote process killed, etc... might not get a normal exit code
              # instead, try to generate exit_code from exit-signal (which might not be provided either)
              exit_code = case
              when data.inspect.include?('KILL') then 9  # SIGKILL
              when data.inspect.include?('SEGV') then 11 # SIGSEGV (crash)
              when data.inspect.include?('TERM') then 15 # SIGTERM
              when data.inspect.include?('HUP')  then 1  # SIGHUP
              when exit_code == -254 then data.inspect
              else exit_code
              end
            end
            
          end # channel.exec
          
          channel.wait # cause this thread to wait
          
        end # open_channel
        ssh.loop
        
        @cwd = nil # clear cwd cache a 2nd time (in case it was set in another thread)

        [stdout, stderr, exit_code]
      end # Thread.start
    end # def

    def copy from, to
      make_absolute! from
      make_absolute! to

      cmd! case
      when posix? then %Q{cp -R \""#{from}"\" \""#{to}\""}
      else %Q{copy \""#{from}"\" \""#{to}\""}
      end
    end
    
    def move from, to
      make_absolute! from
      make_absolute! to

      cmd! case
      when posix? then %Q{mv \""#{from}"\" \""#{to}\""}
      else %Q{move \""#{from}"\" \""#{to}\""}
      end
    end

    def deploy local_file, remote_path
      make_absolute! local_file
      make_absolute! remote_path

      sftp.upload local_file, remote_path
    end

    def directory? path
      begin
        make_absolute! path

        a = sftp.stat!(path)

        return a.type == 2
      rescue
        closed_sftp
        return false
      end
    end

    def exist? path
      # see T_* constants in Net::SFTP::Protocol::V01::Attributes
      # v04 and v06 attributes don't have a directory? or file? method (which v01 does)
      # doing it this way will work for all 3 (v01, v04, v06 attributes)
      begin
        make_absolute! path

        a = sftp.stat!(path)
        
        # types: regular(1), directory(2), symlink, special, unknown, socket, char_device, block_device, fifo
        # if type is any of those, then path exists
        return ( a.type > 0 and a.type < 10 )
      rescue
        closed_sftp
        return false
      end
    end

    def list(path)
      make_absolute! path
      return sftp.dir.entries(path).map do |entry| 
        next nil if ['.','..'].include? entry.name
        join( path, entry.name )
      end.compact
    end

    def glob dir_path, spec, &blk
      make_absolute! dir_path
      matches = list( dir_path ).map do |name|
        if name == '.' or name == '..'
          nil
        elsif not spec or spec.length == 0
          name
        elsif name.include? spec
          name
        else
          nil
        end
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
      make_absolute! local_file
      make_absolute! remote_path
      sftp.upload! local_file, remote_path
    end

    def download remote_file, local_path
      make_absolute! remote_file
      make_absolute! local_path
      sftp.download! remote_file, local_path
    end

    protected

    def _delete path
      make_absolute! path
      if windows?
        cmd!("DEL /Q /F \"#{path}\"")
      else
        exec!("rm -rf \"#{path}\"")
      end
    end

    def _mkdir path
      make_absolute! path
      sftp.mkdir! path
    end
    
    def closed_ssh
      @ssh = nil
    end
    
    def closed_sftp
      @sftp = nil
    end
     
    def ssh
      @ssh ||= Net::SSH.start( nil, nil, @credentials )
      @ssh
    end

    def sftp
      @sftp ||= Net::SFTP.start( nil, nil, @credentials )
      @sftp
    end
  end
end
