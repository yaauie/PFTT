
desc "Generates a Shell script or Batch script to run PFTT"
task :generate_shell_script do
  # TODO use Host::Base::posix?
  @is_posix = File.exist?("/usr/local")
  @is_windows = !@is_posix

  if @is_posix
    File.open("pftt", "wb") do |f|
      f.puts("#!/bin/bash")
      # $* in bash scripts refers to all arguments
      f.puts("bundle exec ruby _pftt.rb $*")
      f.close()

      # make script executable
      system("chmod +x pftt")
    end
  else
    File.open("pftt.bat", "wb") do |f|
      
      f.puts("@echo off")

      # %* in batch scripts refers to all arguments
      f.puts("bundle exec ruby _pftt.rb %*")
      f.close()
    end
  end # if
end # task

desc "Installs things PFTT depends on"
task :install_deps do
  # TODO fail or warn if ruby version is less than 1.9 (ex: on ruby 1.8 File.absolute_path doesn't work)
  
  if not system("bundle install")
    puts "PFTT: 'bundle install' failed!"
  end
end


desc "Installs the PFTT Controller"
task :install => [:generate_shell_script, :host_install] do
  # installs the local host (:host_install), then installs the PFTT controller
  
  puts "PFTT: installed"
  # so the only thing PFTT depends on you to do is have Windows/Linux installed and have ruby1.9 installed
  # PFTT should take care of the rest
  puts "PFTT: you'll now need to run 'rake host_install' on each host"
end

desc "Installs the PFTT Host"
task :host_install => [:install_deps] do
  # TODO Windows: ensure this is at least Windows XP
  #             which service pack? SP3? SP0(rtm), SP1, SP2?
  # TODO Linux or Windows: ensure Apache installed?
  #          Windows, use EasyPHP (GPL, http://www.easyphp.org/) ??
  #          Linux: 
  #              what about installing apache and php in home directory? (just for this user)
  # TODO Windows: disable firewall
  # netsh firewall set opmode disable
  #
  # TODO Windows: disable Dr Watson
  # (registry key)
  #
  # TODO Windows: ensure SSHD installed
  # SSHD\install.bat 
  #
  # TODO Windows: ensure IIS7.5 installed
  # pkgmgr /n:scripts/iis_unattend.xml 
  # see: http://learn.iis.net/page.aspx/133/using-unattended-setup-to-install-iis-70/
  #
  # TODO Windows: ensure VC++ redistributable x86 and x64 installed (if x64 OS, need both!)
  # vc9_redist_x86.exe /passive
  # vc9_redist_x64.exe /passive
  #
  # Later, may need to install SVN CLI client (for :get_php or :get_tests),
  #   on Windows, use: Win32SVN from http://sourceforge.net/projects/win32svn/
  #   on Linux(Gentoo), use: emerge svn
  #   on Linux(Debian(Ubuntu)), use: apt-get install svn
  #   on Linux(Redhat), use: yum install svn
  #
  # Later, CoApp(Windows) will take care of installing PHP so DLLs between PHP versions won't get mixed up
  # like what happened in PHP bug #51307
end

# NOTE: get php binary snapshots from: http://windows.php.net/qa/
# NOTE: get php tests from: http://www.php.net/svn.php
# NOTE: recommend getting Console2 from http://sourceforge.net/projects/console/ instead of Windows cmd.exe
#
# example run:
#
# pftt --func --phpt-tests pftt-phps\5.4.0
#

desc "Downloads PHP Tests from PHP.net (SVN)"
task :get_tests do
  # TODO args for branch and version
  # store in pftt-phps directory
end

desc "Downloads PHP Binary from PHP.net"
task :get_php do
  # TODO args for branch and version
  # store in php-builds directory
end

desc "Downloads newest PHP Tests from PHP.net (SVN)"
task :get_newest_tests do
  # TODO
end

desc "Downloads newest PHP Binary from PHP.net"
task :get_newest_php do
  # TODO
end
