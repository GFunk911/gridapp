function addMarker(i, point){
        jQuery('#map1').jmap('AddMarker',{
                'pointLatLng':[point.Point.coordinates[1], point.Point.coordinates[0]],
                'pointHTML':point.address
            });
        }

function processResult(result, options) {
    var valid = Mapifies.SearchCode(result.Status.code);
    if (valid.success) {
   	 jQuery.each(result.Placemark, addMarker);
    } 
    else {
        jQuery('#address').val(valid.message);
    }
}

function placeMarkerForAddress(address) {
	h = {
        'query': address,
        'returnType': 'getLocations'
    }
    jQuery('#map1').jmap('SearchAddress', h, processResult);
}

function placeTableMarkers(table_id,td_i) {
	app = function(v) {
		$("#msg_box").append(v + "<br/>")
	} 
	debug_str = function(o) {
	    str = "ID: " + o.attr('id')
		str += ", Class: " + o.attr('class')
		str += ", Text: " + o.text()
		str += ", HTML: " + o.html()
		str += "<br/>"
		return str	
	}
	app("Table HTML: " + $("#move").html())
	$("#" + table_id + " td").each(function(i,o) {
		if(i%4 == td_i) {
	    	o = $(o)
		    app(debug_str(o))
		    placeMarkerForAddress(o.text())
		}
	})
}

jQuery(document).ready(function(){
    jQuery('#map1').jmap('init', {'mapType':'hybrid','mapCenter':[40.723056, -74.476250 ],'mapZoom':9});
    //setTimeout("placeTableMarkers('pickups_grid',1)",2000);
    //setTimeout("placeTableMarkers('deliveries_grid',2)",2000);
    jQuery('#address-submit-1').click(function(){
	    placeMarkerForAddress(jQuery('#address').val())
        return false;   
    });
});

jQuery(document).ready(function(){
    jQuery("#testlink").click(function() {
	    alert("SUP")
    })	
});