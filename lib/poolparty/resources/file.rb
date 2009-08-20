=begin rdoc rdoc
== File

The file resource is used to describe a file that should be present on all of the instances.

== Usage

  has_file(:name => '...') do
    # More options. 
    # This block is optional
  end

== Options

* <tt>name</tt> Describe the location of the file with the name
* <tt>mode</tt> Describe the mode of the file (default: 644)
* <tt>owner</tt> The owner of the file (default: poolparty user)
* <tt>content</tt> The contents of the file
* <tt>source</tt> Used to describe a file that is hosted on the master instance.
* <tt>template</tt> The file contents are described with the template. The location given must be readable
  
To write a file to the template directory, use:

  copy_template_to_storage_directory(filepath)

== Example
  has_file(:name => '/etc/motd', :content => 'Hey and welcome to your node today!')
=end
module PoolParty
  module Resources
    
    class FileResource < Resource
      has_searchable_paths
      
      default_options(
        :content  => "# File generated by PoolParty",
        :mode     => "0644",
        :backup   => 5,
        :owner    => "root"
      )

      def after_loaded
        requires get_user(owner) if owner && owner != "root"
      end
      
      def after_loaded
        requires get_user(owner) if owner != "root"
      end
      
      def self.has_method_name
        "file"
      end
      
      def print_to_chef
        <<-EOE
template "<%= name %>" do
  source "<%= name %>.erb"
  action :<%= exists? ? :create : :delete %>
  backup <%= backup %>
  mode <%= print_variable(mode) %>
  owner <%= print_variable(owner) %>
end
        EOE
      end
      
      def template(*arg)
        if arg.empty?
          @template
        else
          file = arg.first
          @template = if File.file?(b = File.expand_path(file))
            b
          elsif f = search_in_known_locations(file)
            f
          else
            raise PoolParty::PoolPartyError.create("TemplateNotFound", "The template #{file} could not be found when creating the file #{name}. Please check that it exists")
          end
        end
      end
      
      # A convenience helper to point to the path of the file
      def path
        name
      end
      
    end
    
  end
end
