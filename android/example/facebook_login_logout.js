function fb_login_logout() {
	var fb = require('facebook');
	
	var win = Ti.UI.createWindow({
		title: 'Login/Logout',
		backgroundColor:'#fff',
		fullscreen: false
	});
	
	fb.appid = '495338853813822';
	fb.permissions = ['publish_stream', 'read_stream'];
	//
	// Login Status
	//
	var label = Ti.UI.createLabel({
		text:'Logged In = ' + fb.loggedIn,
		font:{fontSize:20},
		top:10,
		textAlign:'center'
	});
	win.add(label);
	
	var forceButton = Ti.UI.createButton({
		title:'Force dialog: '+fb.forceDialogAuth,
		top:100,
		width:400,
		height:80
	});
	forceButton.addEventListener('click', function() {
		fb.forceDialogAuth = !fb.forceDialogAuth;
		forceButton.title = "Force dialog: "+fb.forceDialogAuth;
	});
	win.add(forceButton);
	
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
		style : fb.BUTTON_STYLE_WIDE,
		bottom : 30
	})); 

	return win;
};

module.exports = fb_login_logout;
