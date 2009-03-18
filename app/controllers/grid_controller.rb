class Column
  attr_accessor :column
end

class GridController < ApplicationController
  def table_setup_js
    @table_id = "list"
    #@columns = Move.first.attributes.keys
    @columns = CouchTable.new.keys
    render :partial => 'table_setup_js'
  end
  def grid_data
    #@rows = Move.all
    #@columns = Move.first.attributes.keys
    c = CouchTable.new
    @rows = c.docs
    @columns = c.keys
    render :partial => 'grid_data'
  end
  def update
    respond_to do |format|
      format.js do
        obj = CouchTable.new.docs.find { |x| x.id == params[:id] }
        params.delete(:id)
        params.delete(:authenticity_token)
        params.delete(:action)
        params.delete(:controller)
        params.each { |k,v| obj[k] = v }
        obj.save
        render :text => 'sup'
      end
    end
  end
  def new_column
    col = params[:column][:column]
    CouchTable.new.db.save_doc(col => "")
    redirect_to :controller => 'grid', :action => 'index'
  end
  def remove_column
    col = params[:column][:column]
    CouchTable.new.remove_column(col)
    redirect_to :controller => 'grid', :action => 'index'
  end
end
