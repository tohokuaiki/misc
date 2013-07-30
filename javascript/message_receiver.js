var setMessageReceiver;
(function($){
    
    var callbacks = {};
    
    setMessageReceiver = function(register)
    {
        for (var cb in register){
            callbacks[cb] = register[cb]; // stock
        }
        
        var data,param,retval ;
        var target_url = arguments[1] || "*";
        $.receiveMessage(function(e) {
            data = $.deparam(e.data);
            if (data.method){
                param = data.param || {};
                if (typeof(callbacks[data.method]) == "function"){
                    retval = callbacks[data.method].call(this, param);
                    if (data.retval){
                        $.postMessage({
                          method: data.method+'Return',
                          param: retval
                        }, target_url, e.source);
                    }
                }
            }
        });
    }
    
    // set generic message receiver
    setMessageReceiver({
      setHtml: function(param){
          $(param.selector).html(param.html);
      }});
    setMessageReceiver({
      getLocation: function(){
          return location.href;
      }});
    setMessageReceiver({
      setLocation: function(param){
          location.href = param.href;
      }});
})(jQuery);
