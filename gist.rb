require 'chef/knife'

class Chef
  class Knife
    class Gist < Knife
      banner "Example: knife gist GIST_ID role:webservers"
      deps do
        require 'chef/knife/ssh'
        Chef::Knife::Ssh.load_deps
      end

      option :attribute,
        :short => "-a ATTR",
        :long => "--attribute ATTR",
        :description => "The attribute to use for opening the connection - default depends on the context",
        :proc => Proc.new { |key| Chef::Config[:knife][:ssh_attribute] = key.strip }

      option :identity_file,
        :short => "-i IDENTITY_FILE",
        :long => "--identity-file IDENTITY_FILE",
        :description => "The SSH identity file used for authentication"


      option :gist_args,
        :short => "-g ARGUMENTS",
        :long => "--gist-args ARGUMENTS",
        :description => "Arguments to be passed to the gist"

      def run
        self.config = Chef::Config.merge!(config) 


        if name_args.length < 1
          show_usage
          ui.fatal("No gist name given")
          exit 1
        end

        if name_args.length < 2
          show_usage
          ui.fatal("No search query")
          exit 1
        end

        gist = name_args.first
        search = name_args.last

        gist_uri = "https://gist.github.com/#{gist}.txt"
        gist_file = "$HOME/#{gist}.gist"

        ui.msg("Executing Gist #{gist_uri} on Search results from #{search}")

        r = Array.new
        q = Chef::Search::Query.new
        @action_nodes = q.search(:node, search)[0]
        if @action_nodes.length == 0
          ui.fatal("No nodes returned from search!")
        end
        @action_nodes.each do |item|
          next if item.nil?
          if config[:attribute].nil?
            r.push(item.name)
          else
            r.push((item)[config[:attribute]])
          end
        end

        config[:server_name] = r.join("\n")
        config[:ssh_command] = "curl -L -s -o #{gist_file} #{gist_uri} && chmod 755 #{gist_file} && #{gist_file}"
        if config[:gist_args]
          config[:ssh_command] += " " + config[:gist_args]
        end

        begin 
          knife_ssh.run
        end
    end

      def knife_ssh
        ssh = Chef::Knife::Ssh.new
        ssh.ui = ui
        ssh.name_args = [ config[:server_name], config[:ssh_command] ]
        ssh.config[:ssh_user] = Chef::Config[:knife][:ssh_user] || config[:ssh_user]
        ssh.config[:ssh_password] = config[:ssh_password]
        ssh.config[:ssh_port] = Chef::Config[:knife][:ssh_port] || config[:ssh_port]
        ssh.config[:ssh_gateway] = Chef::Config[:knife][:ssh_gateway] || config[:ssh_gateway]
        ssh.config[:identity_file] = Chef::Config[:knife][:identity_file] || config[:identity_file]
        ssh.config[:manual] = true
        ssh.config[:host_key_verify] = Chef::Config[:knife][:host_key_verify] || config[:host_key_verify]
        ssh.config[:on_error] = :raise
        ssh
      end
    end
  end
end
