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

function placeTableMarkers() {
	jQuery('#addressTable td.addressCell').each(function(i,o) {
		placeMarkerForAddress(jQuery(o).text())
	})
}

jQuery(document).ready(function(){
    jQuery('#map1').jmap('init', {'mapType':'hybrid','mapCenter':[40.723056, -74.476250 ],'mapZoom':9});
    placeTableMarkers()
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