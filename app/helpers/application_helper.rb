# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def pages
    PageManager.get(self).pages
  end
  def render_whole_grid(table)
    render_grid(:table => table, :searchField => 'table', :searchString => table, :subtitle => table, :sopt => 'cn')
  end
end
