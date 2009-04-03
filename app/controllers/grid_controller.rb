class Column
  attr_accessor :column
end

class GridController < ApplicationController
  def index
    @tables = CouchTable.tables.sort
  end
  def table_setup_js
    #@columns = Move.first.attributes.keys
    @columns = CouchTable.get(params[:table]).keys + ["edit_link"]
    @columns = @columns.reject { |x| x.to_s == 'table' }
    @table = params[:table]
    render :partial => 'table_setup_js', :locals => {:table_id => @table, :table => @table}
  end
  def grid_data
    #@rows = Move.all
    #@columns = Move.first.attributes.keys
    c = CouchTable.get(params[:table])
    @rows = c.docs
    @columns = c.keys + ['edit_link']
    @columns = @columns.reject { |x| x.to_s == 'table' }
    render :partial => 'grid_data'
  end
  def new_doc
    res = CouchRest::Document.new
    res.database = CouchTable.get('abc').db
    res
  end
  def update
    respond_to do |format|
      format.js do
        puts params.inspect
        obj = (params[:id] and params[:id] != '_empty') ? CouchTable.get(params[:table]).docs.find { |x| x.id == params[:id] } : new_doc
        params.delete(:id)
        params.delete(:authenticity_token)
        params.delete(:action)
        params.delete(:controller)
        params.delete(:oper)
        raise "nil obj" unless obj
        params.each { |k,v| obj[k] = v }
        obj.save
        render :text => 'sup'
      end
    end
  end
  def new_column
    col = params[:column][:column]
    CouchTable.get(params[:table]).add_column(col)
    redirect_to :controller => 'grid', :action => 'index'
  end
  def remove_column
    col = params[:column]
    CouchTable.get(params[:table]).remove_column(col)
    redirect_to :controller => 'grid', :action => 'index'
  end
  def show
    @table = CouchTable.get(params[:table])
    @row = @table.docs.find { |x| x.id == params[:id] }
  end
  def new_table
    table = params[:table][:column]
    CouchTable.get(table).create!
    redirect_to :controller => 'grid', :action => 'index'
  end
end
