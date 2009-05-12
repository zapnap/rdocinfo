$github = {}
$github[:project] = ENV['GH_PROJECT']
$github[:user] = ENV['GH_USER']
$github[:commit] = ENV['GH_COMMIT']

# This is just not cool
module YARD
  module Generators
    class FullDocGenerator < Base
      def generate_index
        if format == :html && serializer
          serializer.serialize '../../index.html', render(:redirect)
          serializer.serialize 'index.html', render(:index)
          serializer.serialize '/namespaces/index.html', render(:all_namespaces)
          serializer.serialize '/methods/index.html', render(:all_methods)

          if readme_file_exists?
            @contents = File.read(readme_file)
            serializer.serialize 'index.html', render(:readme)
          end  
        end
        true
      end
    end
  end    
end