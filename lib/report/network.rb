
module Report
  class Network < Base
    def write_text
      puts
      puts ' PFTT Server: '+$client.xmlrpc_server
      puts
      puts ' Statistics Browser: ' # TODO http:// URL
      puts ' Central PHP Build Store: ' # TODO UNC path
      puts
    
      # contact PFTT server to get list
      $host_infos = $client.view
    
      # continue display
      puts ' Host(s): '+$host_infos.length.to_s
      puts
    
      cm = Util::ColumnManager::Text.new(6)
    
      cm.add_row('', 'Host', 'Status', 'OS SKU(Platform)', 'Arch', 'IP Address')
    
      $host_infos.each{|host_info|
      
      # can use --platform and/or --host to filter net_view list
      skip = false
      unless CONFIG[:php,:filters,:platform].empty?
        CONFIG[:php,:filters,:platform].each{|plat|
          if host_info[:platform].include?(plat)
            skip = true
          end
        }
      end
      unless CONFIG[:hosts].empty?
        CONFIG[:hosts].each{|host_name|
          if host_info[:host_name].include?(host_name)
            skip = true
          end
        }
      end
      #
      unless skip
        status = host_info[:status].to_s
        if status=='locked'
          status = 'LOCKED' # make this stand out
        end
        # make list easier to read by shortening all the occurances of 'Windows' (many of them)
        platform = host_info[:platform].to_s.sub('Windows', 'Win')
      
        cm.add_row({:row_number=>true}, host_info[:host_name], status, platform, host_info[:arch], host_info[:ip_address])
      end
    }
    
    puts cm.to_s
    end
  end
end
