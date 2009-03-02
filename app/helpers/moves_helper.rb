module MovesHelper
  def element_draggable(name)
    name = "#" + name
    "<script>$('#{name}').easydrag();</script>"
  end
  def move_list(ops)
    ops[:move_list_box_id] = "#{ops[:list_name].to_s.downcase}_move_list_box"
    ops[:grid_id] ||= nil
    render :partial => 'move_list', :locals => ops
  end
  def grid_col_i(grid_id)
    (grid_id =~ /pickup/i) ? 1 : 2
  end
end
