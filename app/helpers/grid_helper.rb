module GridHelper
  def column_desc(col,table,last)
    comma = (last ? "" : ",")
    col_obj = Column.new(:table => table, :column => col)
    # "{name:'#{col}', index:'#{col}', editable:'true', width:'250'}"
    h = {:name => col, :index => col, :editable => true, :width => 250}
    if col_obj.dropdown?
      h[:edittype] = 'select'
      str = col_obj.possible_values.map { |x| "#{x}:#{x}" }.join(";")
      h[:editoptions] = {:value => str, :class => 'gridSelect'}.to_js_hash
    end
    h.to_js_hash + comma
  end
end

class Hash
  def to_js_hash
    "{" + map do |k,v|
      v = "'#{v}'" unless %w(true false).include?(v.to_s) or v.to_s =~ /^\d+$/ or v.to_s[0..0] == "{"
      "#{k}:#{v}"
    end.join(", ") + "}"
  end
end
module FromHash
  def from_hash(ops)
    ops.each do |k,v|
      send("#{k}=",v)
    end
  end
  def initialize(ops={})
    from_hash(ops)
  end
end
class Column
  attr_accessor :table, :column
  include FromHash
  def possible_values
    return [] unless map_row
    col = Column.new(:table => map_row['parent_column'].split(":")[0], :column => map_row['parent_column'].split(":")[1])
    res = col.all_values
    puts "possible_values: #{res.inspect}"
    res
  end
  fattr(:map_row) do
    CouchTable.new('columns').docs.find { |x| x['child_column'] == "#{table}:#{column}" }
  end
  def dropdown?
    !!map_row
  end
  def all_values
    CouchTable.new(table).possible_values(column)
  end
end