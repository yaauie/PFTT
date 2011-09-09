
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
  # TODO require ruby version 1.9 (on ruby 1.8 File.absolute_path doesn't work)
  
  if not system("bundle install")
    puts "PFTT: 'bundle install' failed!"
  end
end


desc "Installs the PFTT Controller"
task :install => [:generate_shell_script, :host_install] do
  # installs the local host (:host_install), then installs the PFTT controller
  
  puts "PFTT: installed"
  # so the only thing PFTT depends on you to do is have Windows/Linux installed and have Git and have ruby1.9 installed
  # PFTT should take care of the rest (PFTT requires that remote hosts have ssh server already installed)
  
  # TODO ensure git is installed (msysgit on windows)
  
  puts "PFTT: you'll now need to run 'rake host_install' for each host (run from this controller)"
end

desc "Installs a remote or local PFTT Host"
task :host_install => [:install_deps] do
  # TODO rake host_install should also be able to accept CLI args (so user can re-use it in their own script)
  
  # TODO if running as a dependency of :install, install as localhost (don't ask for host info)
  #      otherwise install as a remote host using SSH
  #      ask user to input information about the host (and then ask user if that host should be added to the list)
  #      or ask the user to choose a host from the list of hosts (config file)
  # TODO Windows: ensure this is at least Windows XP SP3
  # TODO Linux or Windows: ensure Apache installed?
  #          Windows, use EasyPHP (GPL, http://www.easyphp.org/) ??
  #          Linux:  use yum, emerge, apt-get?
  #              what about installing apache and php in home directory? (just for this user)
  # TODO Windows: disable firewall
  # netsh firewall set opmode disable
  #
  # TODO Windows: disable Dr Watson
  # (registry key)
  # use 'regedit [file to import]' or:
  # regchg "software\control key\installed version" REG_SZ 1.00 
  #
  #
  # TODO Windows: ensure IIS7.5 installed
  # pkgmgr /n:scripts/iis_unattend.xml 
  # see: http://learn.iis.net/page.aspx/133/using-unattended-setup-to-install-iis-70/
  #
  # TODO Windows: ensure VC++ redistributable x86 and x64 installed (if x64 OS, need both!)
  # vc9_redist_x86.exe /passive
  # vc9_redist_x64.exe /passive
  #  both are needed for PHP (vc9) to work
  #  should install here (rather than in middleware) because it just needs to be done once
  #
  # Later, may need to install SVN CLI client (for :get_tests ?),
  #   on Windows, use: Win32SVN from http://sourceforge.net/projects/win32svn/
  #   on Linux(Gentoo), use: emerge svn
  #   on Linux(Debian(Ubuntu)), use: apt-get install svn
  #   on Linux(Redhat|Fedora), use: yum install svn
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

desc "Installs JScript interface to PHP Group's Release Management Tools (RMTools)"
task :get_php_revision_get do
  # TODO get from http://github.com/OSTC/php-revision-get
end

desc "Updates this copy of PFTT to the latest version"
task :update_pftt do
  # TODO this should be a checkout of the master branch of PFTT
  #      just run git to update it (therefore master branch contents must be stable)
end

desc "Downloads PHP Tests from PHP.net (SVN)"
task :get_tests do
  # TODO args for branch and version
  # store in pftt-phps directory
end

desc "Downloads PHP Binary from PHP.net"
task :get_php do
  # TODO args for branch and version
  # store in php-builds directory
  #
  # use php-revision-git
end

desc "Downloads newest PHP Tests from PHP.net (SVN)"
task :get_newest_tests do
  # TODO
end

desc "Downloads newest PHP Binary from PHP.net"
task :get_newest_php do
  # TODO
end
