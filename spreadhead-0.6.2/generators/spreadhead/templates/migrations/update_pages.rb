class SpreadheadUpdatePages < ActiveRecord::Migration
  def self.up
<% 
      existing_columns = ActiveRecord::Base.connection.columns(:pages).collect { |each| each.name }
      columns = [
        [:text,             't.text   :text, :null => false'],
        [:url,              't.string :url, :null => false'],
        [:title,            't.string :title, :null => false'],
        [:keywords,         't.string :keywords'],
        [:description,      't.string :description'],
        [:category,         't.string :category'],
        [:formatting,       't.string :formatting, :default => "plain", :null => false'],
        [:published,        't.boolean :published, :default => false, :null => false']
      ].delete_if {|c| existing_columns.include?(c.first.to_s)} 
-%>
    change_table(:pages) do |t|
<% columns.each do |c| -%>
      <%= c.last %>
<% end -%>
    end
    
<%
    existing_indexes = ActiveRecord::Base.connection.indexes(:pages)
    index_names = existing_indexes.collect { |each| each.name }
    new_indexes = [
      [:index_pages_on_id_and_url_and_published, 'add_index :pages, [:id, :url, :published]']
    ].delete_if { |each| index_names.include?(each.first.to_s) }
-%>
<% new_indexes.each do |each| -%>
    <%= each.last %>
<% end -%>
  end
  
  def self.down
    change_table(:pages) do |t|
<% unless columns.empty? -%>
      t.remove <%= columns.collect { |each| ":#{each.first}" }.join(',') %>
<% end -%>
    end
  end
end
