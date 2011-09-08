var Modes = (function(){
	var modeTypes = [],
		_listeners = {},
		_modes = {};
	function getModes() {
		
	}
	function clear() {
		modeTypes = [];
		_modes = {};
		_listeners = {};
	}
	function _getContext() {
		return {
			stopChange: false
		};
	}
	function setMode(type, str, noStop) {
		var context = _getContext();
		function contextCall(cb) {cb.call(context);}
		//preserve old info in context
		context.prev = {
			modeString: modeString(),
			modes: _.clone(_modes)
		};
		
		//change mode
		_modes[type] = str;
		_.extend(context, _modes);
		context.modeStr = [type, str].join(':');
		context.modeString = modeString();
		
		//trigger callbacks
		if(_listeners[context.modeStr] !== undefined)
			_.each(_listeners[context.modeStr], contextCall);
		if(_listeners[context.modeString]!==undefined)
			_.each(_listeners[context.modeString], contextCall);
		if(!!context.stopChange && !noStop)
			setMode(type, context.prev.modes[type], true);
	}
	function init(modes, opts) {
		modeTypes = _.keys(modes).sort();
//			var defaults = {}, _defaults = opts.defaults || {};
		_.each(modeTypes, function(i, ii){
			_modes[i] = modes[i][0];
		});
	}
	function modeString() {
		//returns "amode:val,mode2:val"
		var o = _.map(modeTypes, function(i){
			return i + ':' + _modes[i];
		});
		return o.join(',');
	}
	function listen(modeStr, cb){
		if(_listeners[modeStr]===undefined)
			_listeners[modeStr] = [];
		_listeners[modeStr].push(cb);
	}
	return {
		init: init,
		clear: clear,
		listen: listen,
		getModes: getModes,
		modeString: modeString,
		setMode: setMode
	}
})();