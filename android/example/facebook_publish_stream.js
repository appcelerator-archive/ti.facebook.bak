function fb_pub_stream() {
	var fb = require('facebook');
	
	var win = Ti.UI.createWindow({
		title: 'Publish Stream',
		backgroundColor:'#fff',
		fullscreen: false
	});
	
	fb.appid = '495338853813822';
	fb.permissions = ['publish_stream', 'read_stream'];
	
	function showRequestResult(e) {
		var s = '';
		if (e.success) {
			s = 'SUCCESS';
			if (e.result) {
				s += "; " + e.result;
			}
			if (e.data) {
				s += "; " + e.data;
			}
			if (!e.result && !e.data) {
				s = '"success", but no data from FB.  I am guessing you cancelled the dialog.';
			}
		} else if (e.cancelled) {
			s = 'CANCELLED';
		} else {
			s = 'FAIL';
			if (e.error) {
				s += "; " + e.error;
			}
		}
		alert(s);
	}
	
	var login = fb.createLoginButton({
		top: 10
	});
	login.style = fb.BUTTON_STYLE_NORMAL;
	win.add(login);
	
	var actionsView = Ti.UI.createView({
		top: 80, left: 0, right: 0, visible: fb.loggedIn, height: 'auto'
	});
	
	fb.addEventListener('login', function(e) {
		if (e.success) {
			actionsView.show();
		}
		if (e.error) {
			alert(e.error);
		}
	});
	
	fb.addEventListener('logout', function(e){
		Ti.API.info('logout event');
		actionsView.hide();
	});
	
	var statusText = Ti.UI.createTextField({
		top: 0, left: 10, right: 10, height: 80,
		hintText: 'Enter your FB status'
	});
	actionsView.add(statusText);
	var statusBtn = Ti.UI.createButton({
		title: 'Publish status with GRAPH API',
		top: 90, left: 10, right: 10, height: 80
	});
	statusBtn.addEventListener('click', function() {
		var text = statusText.value;
		if( (text === '')){
			Ti.UI.createAlertDialog({ tile:'ERROR', message:'No text to Publish !! '}).show();
		}else {
			fb.requestWithGraphPath('me/feed', {message: text}, "POST", showRequestResult);
		}	
	});
	actionsView.add(statusBtn);
	
	var wall = Ti.UI.createButton({
		title: 'Publish wall post with GRAPH API',
		top: 180, left: 10, right: 10, height: 80
	});
	wall.addEventListener('click', function() {
		var data = {
			link: "https://developer.mozilla.org/en/JavaScript",
			name: "Best online Javascript reference",
			message: "Use Mozilla's online Javascript reference",
			caption: "MDN Javascript Reference",
			picture: "https://developer.mozilla.org/media/img/mdn-logo.png",
			description: "This section of the site is dedicated to JavaScript-the-language, the parts that are not specific to web pages or other host environments...",
			test: [ {foo:'Encoding test', bar:'Durp durp'}, 'test' ]
		};
		fb.requestWithGraphPath('me/feed', data, 'POST', showRequestResult);
	});
	actionsView.add(wall);
	
	var wallDialog = Ti.UI.createButton({
		title: 'Publish wall post with DIALOG',
		top: 270, left: 10, right: 10, height: 80
	});
	var iter = 0;
	wallDialog.addEventListener('click', function() {
		iter++;
		var data = {
			link: "http://www.appcelerator.com",
			name: "Appcelerator Titanium (iteration " + iter + ")",
			message: "Awesome SDKs for building desktop and mobile apps",
			caption: "Appcelerator Titanium (iteration " + iter + ")",
			picture: "http://developer.appcelerator.com/assets/img/DEV_titmobile_image.png",
			description: "You've got the ideas, now you've got the power. Titanium translates your hard won web skills..."
		};
		fb.dialog("feed", data, showRequestResult);
	});
	actionsView.add(wallDialog);
	
	var description = "FYI, the 'Publish wall post with GRAPH API' button will publish a post with a link to the Mozilla MDN JavaScript page, saying 'Best online Javascript reference'.\n\nDo the 'Publish wall post with DIALOG' option more than once, and be sure the 'iteration n' gets incremented each time.  This proves that cached post data is *not* being re-used, which is important.";
	actionsView.add(Ti.UI.createLabel({bottom: 10, text: description}));
	
	win.add(actionsView);
	return win;
};

module.exports = fb_pub_stream;
