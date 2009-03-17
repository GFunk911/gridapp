class PageManager
  class << self
    def get(h)
      @get ||= new(h)
    end
  end
  attr_accessor :helper
  def initialize(h)
    @helper = h
  end
  def session
    helper.session
  end
  def pages
     return session[:pages] if session[:pages]
     res = []
     res << Page.new('Main')
     res << Page.new('Move 1')
     session[:pages] = res
     res
   end
   def add_page(name)
     session[:pages] << Page.new(name)
   end
end