newlineFormatter = function(el, cellval, opts){
   $(el).html($(el).html()+cellval.replace(";","<br/>").replace(";","<br/>").replace(";","<br/>").replace(";","<br/>"));
}
