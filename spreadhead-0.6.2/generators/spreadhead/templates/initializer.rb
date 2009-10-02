# Spreadhead Initializer
#
# In this file you can do any kind of initialization you need but it is mainly
# for controlling which users get access to create, edit, destroy and update
# pages. By default, any user can modify the pages. If only logged in users can 
# do this, while everyone else can view the  pages then you can add a before 
# filter. If you are using a toolkit like Clearance, then you can use the 
# following:
#
#   module Spreadhead
#     module PagesAuth
#       def self.filter(controller)
#         controller.send(:redirect_to, '/') unless controller.send(:signed_in?)
#       end
#     end  
#   end    
#
# By default all access to creating an modifying pages is forbidden. You need
# to make sure you trust the people creating pages because they can easily
# inject malicious scripts using this tool.
module Spreadhead
  module PagesAuth
    def self.filter(controller)
      controller.send(:head, 403)
    end
  end  
end    