require "#{RAILS_ROOT}/vendor/plugins/jqgrid_interface/lib/grid_params"
GridParams
class GridParams
  attr_accessor :app
  def self.vars
    base_vars + ['app']
  end
  def columns
    super.reject { |x| ['table','app'].include?(x.to_s) }
  end
end