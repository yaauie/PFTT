
bootstrap = File.absolute_path File.join( File.dirname(__FILE__),'..','bootstrap.rb')
File.join(File.dirname(__FILE__),'../bootstrap.rb')
require bootstrap

# bundle exec ruby spec\host_spec.rb

def test_host(host)
#   puts host.line!("irb --help")
#   puts host.line!("irb --help")
  
#   puts host.posix?()
#   puts host.windows?()
#   host.mkdir 'test_dir'
# ####  
#   host.upload '_pftt.rb', 'test file.rb'
# ##  
#  puts "cwd "+host.cwd
# ##    
   puts host.join('php', '5.3.4')
    
#   init_cwd = host.cwd
  
#   begin
#     puts host.list('C:/Users')
    
#     host.cd('C:/')
#     host.cd(init_cwd)
#     host.pushd('C:/Windows')
#     host.pushd('C:/Windows/System32')
#     if host.peekd != 'C:/Windows/System32'
#       puts "peekd failed"
#       exit
#     end
#     host.popd
#     if host.cwd != 'C:/Windows'
#       puts "popd(1) failed"
#       exit
#     end
#     host.popd
#     if host.cwd != init_cwd
#       puts "popd(2) failed"
#       exit
#     end
#   rescue
#   end
#   begin
#     puts host.list('/usr/local')
    
#     host.cd('/')
#     host.cd(init_cwd)
#     host.pushd('/usr')
#     host.pushd('/usr/local/lib')
#     if host.peekd != '/usr/local/lib'
#       puts "peekd failed"
#       exit
#     end
#     host.popd
#     if host.cwd != '/usr'
#       puts "popd(1) failed"
#       exit
#     end
#     host.popd
#     if host.cwd != init_cwd
#       puts "popd(2) failed"
#       exit
#     end
#   rescue
#   end
#   puts host.list('.')
#   puts host.glob(host.cwd, '')#.rb')
#   puts host.exist?('test file.rb')
#   puts host.directory?('test file.rb')
#   puts host.directory?('test_dir')
#   host.download 'test file.rb', 'test file.rb'
#   host.copy 'test file.rb', 'test file2.rb'
#   host.move 'test file2.rb', 'test file3.rb'
# ##  
#   host.open_file 'test file.rb'
#   puts host.line!("irb --help")
#   puts host.line!("irb --help")
# ##  
#   host.delete 'test file3.rb'
#   host.delete 'test file.rb'
#   host.delete 'test_dir'
 
  puts host
end

test_host(Host::Ssh.new(:address=>'127.0.0.1', :username=>'administrator', :password=>'password01!'))
#test_host(Host::Ssh.new(:address=>'10.200.49.69', :username=>'root', :password=>'password01!'))
