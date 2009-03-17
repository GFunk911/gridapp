require 'page'

class MovesController < ApplicationController
  def grid_data
    puts params.inspect
    if params[:move_type] =~ /pickup/i
      @moves = Move.all(:order => "#{params[:sidx]} #{params[:sord]}")[0..1]
    else
      @moves = Move.all(:order => "#{params[:sidx]} #{params[:sord]}")[2..3]
    end

    respond_to do |format|
      format.xml { render :partial => 'grid_data.xml.builder', :layout => false }
    end   
  end
  def show
  end
end
