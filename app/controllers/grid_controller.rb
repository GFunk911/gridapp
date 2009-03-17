class GridController < ApplicationController
  def table_setup_js
    @table_id = "list"
    #@columns = Move.first.attributes.keys
    @columns = %w(orig dest cat)
    render :partial => 'table_setup_js'
  end
  def grid_data
    @rows = Move.all
    #@columns = Move.first.attributes.keys
    @columns = %w(orig dest cat)
    render :partial => 'grid_data'
  end
  def update
    respond_to do |format|
      format.js do
        obj = Move.find(params[:id])
        params.delete(:id)
        params.delete(:authenticity_token)
        params.each { |k,v| obj.send("#{k}=",v) if obj.respond_to?("#{k}=") }
        obj.save!
        render :text => 'sup'
      end
    end
  end
end
