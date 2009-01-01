require 'fileutils'

module Branches
  module Setup
    class << self
      def setup_config_repo(path, key)
        path = File.expand_path(path)
        key = File.expand_path(key)
        FileUtils.mkdir(path)
        Dir.chdir(path) do
          %x[git init]
          FileUtils.mkdir(File.join(path, 'keys'))
          FileUtils.cp(key, File.join(path, 'keys', 'admin'))
          open(File.join(path, 'config.rb'), 'w') do |f|
            f.write <<-EOS
Branches.config do
  keydir 'keys'

  global do |g|
    g.write = 'admin'
  end
end
EOS
          end
          %x[git add *]
          %x[git commit -m 'Initial configuration']
        end
      end

      def generate_authorized_keys(home_path, config_path)
        # load the configuration
        puts "config: #{File.join(config_path, 'config.rb')}"
        load File.join(config_path, 'config.rb')

        # create the file
        FileUtils.mkdir(File.join(home_path, '.ssh')) unless File.exist?(File.join(home_path, '.ssh'))
        open(File.join(home_path, '.ssh', 'authorized_keys'), 'w') do |f|
          f.write "### autogenerated by Branches\n"

          # loop the keys
          puts "keydir: #{Branches.keydir}"
          Dir.glob(File.join(config_path, Branches.keydir, '*')) do |k|
            puts "key: #{k}"
            f.write "command=\"branches --config=#{File.join(config_path, 'config.rb')} --user=#{File.basename(k)}\",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty #{File.read(k).chomp}\n"
          end
        end
      end
    end # class
  end # Setup
end # Branches