exports.window = function(value){
	var win = Titanium.UI.createWindow({title:'Login'});
	var fb = require('facebook');
	//
	// Login Status
	//
	var label = Ti.UI.createLabel({
		text:'Logged In = ' + fb.loggedIn,
		font:{fontSize:14},
		height:'auto',
		top:10,
		textAlign:'center'
	});
	win.add(label);
	
	var forceButton = Ti.UI.createButton({
		title:'Force dialog: '+fb.forceDialogAuth,
		top:50,
		width:160,
		height:40
	});
	forceButton.addEventListener('click', function() {
		fb.forceDialogAuth = !fb.forceDialogAuth;
		forceButton.title = "Force dialog: "+fb.forceDialogAuth;
	});
	win.add(forceButton);

	function updatePerms(){
		var perms = ['read_stream'];
		if (doPublish.value) perms.push('publish_stream');
		fb.permissions = perms;
	}

	function newToggle(title,viewTop){
		win.add(Ti.UI.createLabel({
			top:viewTop, left:10, width:200, text:title, height:40
		}));
		var result = Ti.UI.createSwitch({
			value:false, left:220, top:viewTop
		});
		win.add(result);
		result.addEventListener('change',updatePerms);
		return result;
	}

	var doPublish = newToggle('Publish stream',100);
	
	function updateLoginStatus() {
		label.text = 'Logged In = ' + fb.loggedIn;
	}

	// capture
	fb.addEventListener('login', updateLoginStatus);
	fb.addEventListener('logout', updateLoginStatus);
	
	//
	// Login Button
	//
	win.add(fb.createLoginButton({
		style:fb.BUTTON_STYLE_WIDE,
		bottom:30
	}));

	return win;
};
