require 'redcloth'
require 'bluecloth'

module Spreadhead
  module Render

    def self.included(controller) # :nodoc:
      controller.send(:include, InstanceMethods)
      controller.class_eval do
        helper_method :spreadhead
        hide_action   :spreadhead
      end
    end

    module InstanceMethods
      # Show the contents of the specified page to be used when rendering. The 
      # page parameter can be either a string (the page url) or a Page object.
      #
      # @return The page text as a string
      def spreadhead(page)
        return '' unless page
        page = ::Page.find_by_url!(page) if page.is_a? String

        case page.formatting
          when 'markdown'
            BlueCloth.new(page.text).to_html
          when 'textile'
            r = RedCloth.new(page.text)
            r.hard_breaks = false
            r.to_html
          else
            page.text
        end        
      end
    end  
  end
end
