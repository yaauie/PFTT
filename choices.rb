require 'choice'
Choice.options do
  option :hosts do
    long '--hosts=[*<HOST>]'
    short 'h'

    action do |value|
      puts "setting hosts: #{value.inspect}"
    end
  end

  option :php_platform do
    long '--php-platform=*<platform>'

    action do |value|
      puts "setting hosts: #{value.inspect}"
    end
  end
end