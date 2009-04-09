class Object
  def klass
    self.class
  end
end

class ColumnConstraint
  attr_accessor :parent_table, :parent_column, :child_table, :child_column, :value, :parent, :child, :app, :modifier
  def initialize(row)
    @parent = row.parent_column
    @child = row.child_column
    @parent_table, @parent_column = *row.parent_column.split(":")
    @child_table, @child_column = *row.child_column.split(":")
    @value = row['value']
    @app = row['app']
    @modifier = row['modifier']
  end
  def get_app
    App.get(app)
  end
end

class ForeignKey < ColumnConstraint
  def row_for(row)
    value = row.send(child_column)
    get_app.get_table(parent_table).docs.find { |x| x.send(parent_column) == value }
  end
  def rows_for(row)
    value = row.send(parent_column)
    get_app.get_table(child_table).docs.select { |x| x.send(child_column) == value }
  end
  def possible_values
    res = get_app.get_table(parent_table).docs
    res = res.select { |x| x.instance_eval(value) } if value
    res = [""] + res.map { |x| x[parent_column.to_s] }
    res = res.select { |x| x }
    res.sort
  end
  def child_editable?
    true
  end
  def for_possible_values?
    modifier != 'no_edit'
  end
end

class VirtualColumn < ColumnConstraint
  def value_for(row)
    fk = row.fk_row(parent_table)
    parent = fk.row_for(row)
    parent ? parent.send(parent_column) : nil
  end
  def child_editable?
    false
  end
end

class SortColumn < ColumnConstraint
  def sorted_rows(rows)
    rows.sort_by { |x| x.instance_eval(value) }
  end
  def child_editable?
    true
  end
end

class CalcColumn < ColumnConstraint
  attr_accessor :code
  def initialize(row)
    @child_table, @child_column = *row.child_column.split(":")
    @code = row.value
  end
  def value_for(row)
    row.instance_eval(code)
  rescue => exp
    puts "error evaluating '#{code}'"
    raise exp
  end
  def child_editable?
    false
  end
end

class VirtualTable < ColumnConstraint
end

module Enumerable
  def mysum(*args)
    if args.empty?
      inject(0) { |s,i| s + i }
    elsif args.size == 1
      k = args.first
      res = inject(0) { |s,i| s + i.send(k).to_f }
      (res == res.to_i) ? res.to_i : res
    else
      raise "can't sum with #{args.size} args #{args.inspect}"
    end
  end
  def select_h(h)
    select do |row|
      h.all? { |k,v| row.send(k) == v }
    end
  end
  def find_h(h)
    select_h(h).first
  end
end

class Array
  def method_missing(sym,*args,&b)
    return [] if empty?
    return super(sym,*args,&b) unless first.respond_to?(:get_table)
    table = first.get_table
    if table.keys.include?(sym.to_s)
      raise "no args #{args.insect}" unless args.size == 1
      select_h(sym => args.first)
    else
      puts "key #{sym} not in #{table.keys.inspect}"
      super(sym,*args,&b)
    end
  end
end

class CouchRest::Document
  def fk_row(other_table)
    a = get_app.constraints(ForeignKey)
    a.find { |x| x.parent_table == other_table.to_s and x.child_table == table }
  end
  def child_fk_rows(other_table)
    a = get_app.constraints(ForeignKey)
    a.select { |x| x.parent_table == table and x.child_table == other_table.to_s }
  end
  def row_in_table(other_table)
    fk = fk_row(other_table)
    return fk.row_for(self)
    #value = send(fk.child_column)
    #CouchTable.get(fk.parent_table).docs.find { |x| x.send(fk.parent_column) == value }
  end
  def parent_rows_in_table(t)
    child_row_list = child_fk_rows(t.to_s).map { |x| x.rows_for(self) }
    res = child_row_list.flatten.group_by { |x| x.id }.values.select { |x| x.size == child_row_list.size }.map { |x| x.first }
    DocumentList.new(res)
  end
  def parent(t)
    row_in_table(t)
  end
  def children(t)
    parent_rows_in_table(t)
  end
end

class DocumentList < BlankSlate
  attr_accessor :list
  def initialize(list)
    @list = list
  end
  def method_missing(sym,*args,&b)
    if sym == :parent
      list.map { |x| x.parent(*args,&b) }.select { |x| x }
    else
      list.send(sym,*args,&b)
    end
  end
end

class CouchTable
  #extend CouchTableClassMethods
end

class ConcreteCouchTable < CouchTable
  attr_accessor :table, :app
  def initialize(app,table)
    @app = app
    @table = table
    raise "nil table" unless table.to_s != ''
  end
  def db
    app.db
  end
  fattr(:all_docs) do
    #app.get_documents("function(doc){if(doc['table']=='#{table}') emit(null,doc)}")
    app.all.select { |x| x.table == table }
  end
  def sorted_docs(rows)
    col = sort_column
    if col
      col.sorted_rows(rows)
    else
      rows
    end
  end
  fattr(:docs) do
    sorted_docs(all_docs)
  end
  def sort_column
    res = app.constraints(SortColumn)
    res.find { |x| x.child_table == table }
  end
  def virtual_columns
    res = app.constraints(VirtualColumn)
    res.select { |x| x.child_table == table }
  end
  def calc_columns
    res = app.constraints(CalcColumn)
    res.select { |x| x.child_table == table }
  end
  def concrete_keys
    docs.map { |x| x.keys }.flatten.uniq.reject { |x| x.to_s[0..0] == '_' }
  end
  def virtual_keys
    virtual_columns.map { |x| x.child_column }.uniq
  end
  def keys
    res = concrete_keys + virtual_keys + calc_columns.map { |x| x.child_column }.uniq 
    res << 'scrapelink' if table == 'scrapes'
    res
  end
  def remove_column(col)
    docs.each do |doc|
      doc.delete(col)
      doc.save
    end
  end
  def add_column(col)
    d = docs.first
    d[col] = ""
    d.save
  end
  def possible_values(col)
    docs.map { |x| x[col] }.uniq.select { |x| x }.sort
  end
  def create!
    db.save_doc(:table => table, :fake_column => "", :app => app.app)
  end
  def to_csv
    ks = concrete_keys.reject { |x| x.to_s == 'table' }
    headers = ks.join(",")
    rows = docs.map do |row|
      ks.map { |k| row[k] }.join(",")
    end
    ([headers]+rows).join("\n")
  end
end

class VirtualCouchTable < ConcreteCouchTable
  fattr(:virtual_table_constraint) do
    app.constraints(VirtualTable).find_h(:child_table => table)
  end
  fattr(:base_table_name) do
    raise "no virtual table constraint for #{table}" unless virtual_table_constraint
    virtual_table_constraint.parent_table
  end
  def base_table
    app.get_table(base_table_name)
  end
  fattr(:all_docs) do
    base_table.all_docs
  end
  fattr(:docs) do
    value = virtual_table_constraint.value
    return all_docs unless value and value != ''
    all_docs.select { |row| row.instance_eval(value) }
  end
end