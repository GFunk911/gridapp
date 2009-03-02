class MovesController < ApplicationController
  def grid_data
    @moves = Move.all(:order => "#{params[:sidx]} #{params[:sord]}")[0..1]

    respond_to do |format|
      format.xml { render :partial => 'grid_data.xml.builder', :layout => false }
    end   
  end
end
