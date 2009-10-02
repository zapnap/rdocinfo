module Spreadhead
  class PagesController < ApplicationController
    unloadable
    before_filter :filter, :except => [:show]
    
    def new
      @page = ::Page.new    
    end

    def index 
      @pages = ::Page.find(:all)
    end

    def show
      @page = ::Page.published.find_by_url!(params[:url].to_a.join('/'))  
    end
    
    def edit
      @page = ::Page.find(params[:id])
    end

    def create
      @page = ::Page.new(params[:page])
      respond_to do |format|
        if @page.save
          format.html { redirect_to pages_url }
          format.xml  { head :created, :location => pages_url }
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @page.errors.to_xml }
        end
      end
    end
    
    def update
      @page = ::Page.find(params[:id])
      respond_to do |format|
        if @page.update_attributes(params[:page])
          format.html { redirect_to pages_url }
          format.xml  { head :ok }
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => @page.errors.to_xml }
        end
      end
    end
    
    def destroy
      @page = ::Page.find(params[:id])
      @page.destroy
      respond_to do |format|
        format.html { redirect_to pages_url }
        format.xml  { head :ok }
      end
    end
    
  private
    def filter
      Spreadhead::PagesAuth.filter(self)    
    end
  end
end