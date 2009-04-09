newlineFormatter = function(el, cellval, opts){
   $(el).html($(el).html()+cellval.replace(";","<br/>").replace(";","<br/>").replace(";","<br/>").replace(";","<br/>"));
}

myLink = function(el, cellval, opts){
	linkName = cellval.split(':')[0]
	linkUrl = cellval.split(':')[1]
	str = '<a href="' + linkUrl + '">' + linkName + '</a>'
   $(el).html(str);
}