
module TestBench
  class Wcat < Base
    def run(local_host, hosts, perf_case, target_host)
      # test with 8, 16, and 32 virtual clients for each physical host
      do_run(local_host, hosts, perf_case, target_host, 8)
      do_run(local_host, hosts, perf_case, target_host, 16)
      do_run(local_host, hosts, perf_case, target_host, 32)
      
      # TODO merge results
    end
    
    def do_run(local_host, hosts, perf_case, target_host, clients_per_host)
      # write settings.ubr and client.ubr to a temp file to feed to wcctl
      client_path = localhost.mktempfile('client.ubr', client(perf_case))
      settings_path = localhost.mktempfile('settings.ubr', settings(perf_case))
        
      # create temp file for the log fromm wcctl
      log_path = localhost.mktempfile("wcat_log_#{clients_per_host}.xml")
      
      # execute wcctl (WCAT) which will wait for wcclient from hosts to connect
      localhost.exec("#{wcat_path.convert_path}\wcctl.exe -t #{client_path} -f #{settings_path} -s #{target_host.host}:#{target_host.port} -v #{clients_per_host} -c 1 -o #{log_path} -x")
      
      # execute wcclient on each host which will connect to wcctl on this host and then begin
      # running the performance test
      hosts.each{|host|
        # exec wcclient in another thread
        host.exec("wcclient.exe #{wcat_controller_machine_name}") # TODO
      }
      
      TestResult::PerfResult.new(log_path)
    end
    
    def settings(perf_case)
      <<-SETTINGS
    settings
    {
        counters
        {
            interval = 10;
            counter = "Memory\\Available MBytes";
        }
    }
    SETTINGS
    end
    
    def client(perf_case)
      <<-CLIENT
    scenario
    {
        name    = "default_doc";
    
        warmup      = 30;
        duration    = 90;
        cooldown    = 30;
    
        default
        {
            setheader
            {
                name    = "Connection";
                value   = "keep-alive";
            }
            setheader
            {
                name    = "Accept";
                value   = "image/gif, image/x-xbitmap, image/jpeg, image/pjpeg, application/vnd.ms-excel, */*";
            }
            setheader
            {
                name    = "Accept-Language";
                value   = "en-us";
            }
            setheader
            {
                name    = "User-Agent";
                value   = "Mozilla/5.0 (compatible; MSIE 7.01; Windows NT 6.0";
            }
            setheader
            {
                name    = "Accept-Encoding";
                value   = "gzip, deflate";
            }
            setheader
            {
                name    = "Host";
                value   = server();
            }
            version     = HTTP11;
            statuscode  = 200;
            close       = ka;
        }
    
        transaction
        {
            id      = "default_doc";
            weight  = 100;
    
            request
            {
                url = #{perf_case.url.path};
            }
        }
    }
    CLIENT
    end
    
  end
end
