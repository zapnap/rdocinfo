module Spreadhead
  module PagesAuth
    def self.filter(controller)
      controller.send(:head, 403)
    end
  end  
end