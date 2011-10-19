#require "xmlrpc/client"
#
## Make an object to represent the XML-RPC server.
#server = XMLRPC::Client.new( "xmlrpc-c.sourceforge.net", "/api/sample.php")
#
## Call the remote server and get our result
#result = server.call("sample.sumAndDifference", 5, 3)
#
#sum = result["sum"]
#difference = result["difference"]
#
#puts "Sum: #{sum}, Difference: #{difference}"
# 


class PfttClient
  def xmlrpc_server
    return '10.200.50.51'
  end
  def dep_server
  end
  def phpt_server
  end
  def phpbuild_server
  end
  def database_server
  end
  def config_server
  end
  def update_server
  end
  def lock(host_name)
    # add to list
    # ensure heartbeat thread is running
    # will need to renew each lock every 5 minutes
  end
  def lock_renew(host_name, lock_id)
  end
  def release(host_name, lock_id)
  end
  def view
    return [
      {:host_name=>'OI1-PHP-WDW-10', :status=>:ready, :platform=>'Windows 2003r2 SP0', :arch=>'x64', :ip_address=>'10.200.30.11'},
      {:host_name=>'OI1-PHP-WDW-25', :status=>:locked, :platform=>'Windows Vista SP2', :arch=>'x86', :ip_address=>'10.200.30.12'},
      {:host_name=>'OI1-PHP-WDW-29', :status=>:ready, :platform=>'Windows 8 Client M3', :arch=>'x86', :ip_address=>'10.200.30.13'},
      {:host_name=>'PBS-0', :status=>:ready, :platform=>'Gentoo Linux', :arch=>'x64', :ip_address=>'10.200.30.14'},
      {:host_name=>'PBS-1', :status=>:locked, :platform=>'Gentoo Linux', :arch=>'x64', :ip_address=>'10.200.30.15'},
      {:host_name=>'PBS-2', :status=>:ready, :platform=>'Gentoo Linux', :arch=>'x64', :ip_address=>'10.200.30.16'},
      {:host_name=>'AZ-WEB-PHP-0', :status=>:ready, :platform=>'Azure Web 2008', :arch=>'x64', :ip_address=>'157.60.40.11'},
      {:host_name=>'AZ-VM-PHP-0', :status=>:ready, :platform=>'Azure VM 2008', :arch=>'x64', :ip_address=>'157.60.40.12'},
      {:host_name=>'AZ-WKR-PHP-0', :status=>:ready, :platform=>'Azure Worker 2008', :arch=>'x64', :ip_address=>'157.60.40.13'},
      {:host_name=>'AZ-WEB-PHP-1', :status=>:locked, :platform=>'Azure Web 2008r2', :arch=>'x64', :ip_address=>'157.60.40.14'},
      {:host_name=>'AZ-VM-PHP-1', :status=>:ready, :platform=>'Azure VM 2008r2', :arch=>'x64', :ip_address=>'157.60.40.15'},
      {:host_name=>'AZ-WKR-PHP-1', :status=>:ready, :platform=>'Azure Worker 2008r2', :arch=>'x64', :ip_address=>'157.60.40.16'}
        ]
  end
end
