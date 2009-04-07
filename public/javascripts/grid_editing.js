function editGridCell(table_id,iRow,iCol,col_name,new_val) {
    grid = $('#'+table_id)
    grid.editCell(iRow,iCol,true)
    $('#'+iRow+'_'+col_name).val(new_val)
    grid.saveCell(iRow,iCol)
}

function reloadAllGrids() {
    
}

function getGridOfType(table_type) {
    str = 'table[table-type='+table_type+']'
    return $(str)
}

function numRows(table_type) {
    return getGridOfType(table_type).find('tr').size() - 1
}

//t = $('table[table-type=teams]'); iRow = 0; rids = t.getDataIDs(); rid = rids[iRow]; t.editCell(iRow+1,1,true); $('#1_team').val('Falcons');