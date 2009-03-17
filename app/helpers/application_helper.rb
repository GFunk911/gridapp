# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def pages
    PageManager.get(self).pages
  end
end
