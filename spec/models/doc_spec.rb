require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe 'Doc' do
  before(:each) do
    @people = CouchTable.new('people')
    @people.db.recreate!
    @people.db.save_doc(:table => 'people', :name => 'Adam', :city => 'Atlanta')
    @people.db.save_doc(:table => 'people', :name => 'Bill', :city => 'Boston')
    @people.db.save_doc(:table => 'people', :name => 'Chad', :city => 'Chicago')
    
    @people.db.save_doc(:table => 'cities', :weather => 'Hot', :city => 'Atlanta')
    @people.db.save_doc(:table => 'cities', :weather => 'Cold', :city => 'Boston')
    
    @people.db.save_doc(:table => 'columns', :constraint_type => 'foreign_key', :parent_column => 'cities:city', :child_column => 'people:city')
    @people.db.save_doc(:table => 'columns', :constraint_type => 'virtual_column', :parent_column => 'cities:weather', :child_column => 'people:weather')
    @people.db.save_doc(:table => 'columns', :constraint_type => 'calc_column', :child_column => 'people:double_name', :value => "name + ' ' + name")
    
    @people.db.save_doc(:table => 'junk', :weather => 'Hot', :city => 'Atlanta')
    @people.db.save_doc(:table => 'junk', :weather => 'Cold', :city => 'Boston')
    
    @adam = @people.docs.find { |x| x.name == 'Adam' }
  end
  it 'table' do
    @people.docs.size.should == 3
  end
  it 'fk' do
    @adam.fk_row('cities').class.should == ForeignKey
  end
  it 'row' do
    @adam.row_in_table('cities').city.should == 'Atlanta'
  end
  it 'fk all' do
    ForeignKey.all.size.should == 1
  end
  it 'fk attrs' do
    fk = ForeignKey.all.first
    fk.parent_table.should == 'cities'
    fk.parent_column.should == 'city'
    fk.child_table.should == 'people'
    fk.child_column.should == 'city'
  end
  it 'child table has virtual key' do
    CouchTable.new('people').keys.include?('weather').should == true
  end
  it 'child table has virtual value' do
    @adam.weather.should == 'Hot'
  end
  it 'double name' do
    @adam.double_name.should == 'Adam Adam'
  end
  it 'calc_column' do
    @adam.calc_column('double_name').class.should == CalcColumn
    @adam.calc_column('double_name').value_for(@adam).should == 'Adam Adam'
  end

end
