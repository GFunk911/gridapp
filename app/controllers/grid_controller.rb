class Column
  attr_accessor :column
end

class GridController < ApplicationController
  def index
    @tables = ['people','cities','columns']
  end
  def table_setup_js
    #@columns = Move.first.attributes.keys
    @columns = CouchTable.new(params[:table]).keys
    @table = params[:table]
    render :partial => 'table_setup_js', :locals => {:table_id => @table, :table => @table}
  end
  def grid_data
    #@rows = Move.all
    #@columns = Move.first.attributes.keys
    c = CouchTable.new(params[:table])
    @rows = c.docs
    @columns = c.keys
    render :partial => 'grid_data'
  end
  def new_doc
    res = CouchRest::Document.new
    res.database = CouchTable.new('abc').db
    res
  end
  def update
    respond_to do |format|
      format.js do
        puts params.inspect
        obj = (params[:id] and params[:id] != '_empty') ? CouchTable.new(params[:table]).docs.find { |x| x.id == params[:id] } : new_doc
        params.delete(:id)
        params.delete(:authenticity_token)
        params.delete(:action)
        params.delete(:controller)
        raise "nil obj" unless obj
        params.each { |k,v| obj[k] = v }
        obj.save
        render :text => 'sup'
      end
    end
  end
  def new_column
    col = params[:column][:column]
    CouchTable.new(params[:table]).db.save_doc(col => "")
    redirect_to :controller => 'grid', :action => 'index'
  end
  def remove_column
    col = params[:column][:column]
    CouchTable.new(params[:table]).remove_column(col)
    redirect_to :controller => 'grid', :action => 'index'
  end
end
