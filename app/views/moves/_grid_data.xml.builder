xml.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"
xml.rows do
  xml.page params[:page]
  xml.total_pages (@moves.size.to_i / params[:rows].to_i)
  xml.records{@moves.size}
  @moves.each do |u|
    xml.row :id => u.id do
      xml.cell u.id
      xml.cell u.orig
      xml.cell u.dest
      xml.cell u.customer
    end
  end
end
