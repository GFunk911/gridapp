class MovesController < ApplicationController
  def grid_data
    @moves = Move.all(:order => "#{params[:sidx]} #{params[:sord]}")

    respond_to do |format|
      format.xml { render :partial => 'grid_data.xml.builder', :layout => false }
    end   
  end
end
