
# infrastructure to support ext\mysql, ext\mysqli and ext\pdo_mysql tests
module Scenario
  module Database  
    module Mysql
    class Base < Base
      def deploy(host_info)
        # be aware that a single run of all mysql tests has been observed to put a mysql server into an
        # unusable state
        #
        # therefore, this should (re)start mysql when a test run starts
        #
        # /etc/init.d/mysql restart
#        if @host.posix?
#          @host.exec!('/etc/init.d/mysql start')
#        elsif @host.windows?
#          # LATER
#        end
#        
    
        # edit /etc/mysql/my.cnf
        # bind-address = 0.0.0.0
        #
        #
        # from mysql:
        # use mysql
        # INSERT INTO user (Host,User,Password) VALUES('%', 'root', PASSWORD('password01!'))
        # must do FLUSH PRIVILEGES or user will not have access
        # FLUSH PRIVILEGES
        #
      end
      def teardown(host_info)
        # leave mysql server running in case someone wants to use it for something
      end
      # script_type => :skipif, :test, :clean
      def execute_script_start(env, test, script_type, deployed_script, deployed_php, php_build_info, php_ini, host_info)
        # ensure mysql and mysqli extensions are enabled in the INI
        # (PhpIni ensures that extension_dir is set)
        if host_info.posix?
          php_ini.insert(PhpIni.new("extension=mysqli.so
            extension=mysql.so
            extension=pdo_mysql.so
            extension=pdo.so"))
        else
          php_ini.insert(PhpIni.new("extension=php_mysqli.dll
            extension=php_mysql.dll
            extension=php_pdo_mysql.dll"))
        end
    
        # TODO read from config file
        db_name = 'test'
        user = 'root'
        password = 'password01!'
        host = '10.200.49.222'
        #host = '192.168.1.156'
        port = 3306
    
        dsn = "mysql:host=#{host};port=#{port};dbname=#{db_name}"
        # PHPT tests use environment variables to get configuration information
        # vars for ext\mysql and ext\mysqli
        env['MYSQL_TEST_HOST'] = host
        env['MYSQL_TEST_PORT'] = port.to_s
        env['MYSQL_TEST_USER'] = user
        env['MYSQL_TEST_PASSWD'] = password
        env['MYSQL_TEST_DB'] = db_name
        env['MYSQL_TEST_DSN'] = dsn
        # vars for ext\pdo_mysql
        env['PDO_MYSQL_TEST_HOST'] = host
        env['PDO_MYSQL_TEST_PORT'] = port.to_s
        env['PDO_MYSQL_TEST_USER'] = user
        env['PDO_MYSQL_TEST_PASSWD'] = password
        env['PDO_MYSQL_TEST_PASS'] = password
        env['PDO_MYSQL_TEST_DB'] = db_name
        env['PDO_MYSQL_TEST_DSN'] = dsn
        env['PDOTEST_USER'] = user
        env['PDOTEST_PASS'] = password
        env['PDOTEST_DSN'] = dsn
      end
    end # 
  end #
  end
end
