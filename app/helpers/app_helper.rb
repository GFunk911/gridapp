module AppHelper
  def tables_to_show
    if @plumbing
      @app.tables
    else
      @app.tables.reject { |x| %w(columns).include?(x.to_s) }
    end
  end
end
