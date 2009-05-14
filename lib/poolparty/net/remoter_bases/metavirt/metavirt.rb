=begin rdoc
 The metavirt remoter base send all commands to a RESTful HTTP server that implements the commands
  
=end
require 'restclient'
require 'cgi'

module PoolParty
  module Remote
    class Metavirt < Remote::RemoterBase
      include Dslify
      
      default_options(
        # :machine_image => 'ubuntu-kvm',
        # :key       => lambda {Key.new},
        # :keypair_name  => lambda {key.basename},
        # :keypair_path  => lambda {key.full_filepath},
        # :public_key    => lambda { key.public_key.to_s },
        # :keypair       => nil,
        :keypair_name    => nil,
        :keypair_path    => nil,
        :authorized_keys => nil,
        :remote_base    => :vmrun,
        :server_config   => {},
        :provider        => :vmrun
      ) 
      
      def server
        if @server
          @server
        else
          opts = {:content_type =>'application/json', 
           :accept      => 'application/json',
           :host        => 'http://localhost',
           :port        => '3000'}.merge(server_config)
          @uri = "#{opts.delete(:host)}:#{opts.delete(:port)}"
          @server = RestClient::Resource.new( @uri, opts)
        end
      end
      
      def remoter_base_options
        dsl_options[:remoter_base_options] = remote_base.dsl_options.choose do |k,v|
          v && (v.respond_to?(:empty) ? !v.empty?: true)
        end
      end
      
      def self.launch_new_instance!(o={})
        new_instance(o).launch_new_instance!
      end
      def launch_new_instance!(o={})
        p remote_base.dsl_options[:vmx_files]
        opts =dsl_options.merge(:remoter_base_options=>remoter_base_options)
        result = JSON.parse(server['/run-instance'].put(opts.to_json)).symbolize_keys
        @id = result[:id]
        result
      end
      # Terminate an instance by id
      def self.terminate_instance!(o={})
        new(nil, o).terminate_instance!
      end
      def terminate_instance!(o={})
        raise "id or instance_id must be set before calling describe_instace" if !id(o)
        server["/instance/#{CGI.escape(id(o))}"].delete
      end

      # Describe an instance's status, must pass :vmx_file in the options
      def self.describe_instance(o={})
        new_instance(o).describe_instance
      end
      def describe_instance(o={})
        raise "id or instance_id must be set before calling describe_instace" if !id(o)
        JSON.parse(@server["/instance/#{CGI.escape(id(o))}"].get).symbolize_keys!
      end

      def self.describe_instances(o={})
        new_instance(o).describe_instances
      end
      def describe_instances(o={})
        JSON.parse( server["/instances/"].get ).collect{|i| i.symbolize_keys!}
      end
      
      # setup the contained remoter base
      # this is almost identical to cloud.using
      def provider(t, &block)
        return self.send(t) if self.respond_to? t
        if available_bases.include?(t.to_sym)
          klass_string = "#{t}".classify
          @remote_base_klass = "::PoolParty::Remote::#{klass_string}".constantize
          self.remote_base = @remote_base_klass.send :new, dsl_options, &block
          remote_base.instance_eval &block if block
          instance_eval "def #{t};remote_base;end"
        else
          raise "Unknown remote base: #{t}"
        end
      end
      
      private
      def id(o={})
        @id || o[:id] || dsl_options[:id] || o[:instance_id] || dsl_options[:instance_id]
      end
      
    end
  end
end