exports.window = function(value){
	var win = Titanium.UI.createWindow({title:'Publish Stream'});
	var fb = require('facebook');
	function showRequestResult(e) {
		var s = '';
		if (e.success) {
			s = "SUCCESS";
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
			s = "CANCELLED";
		} else {
			s = "FAIL";
			if (e.error) {
				s += "; " + e.error;
			}
		}
		alert(s);
	}
	
	var actionsView = Ti.UI.createScrollView({
		top: 0, left: 0, right: 0,
		visible: fb.loggedIn, height: Ti.UI.SIZE,
		contentHeight:Ti.UI.SIZE, backgroundColor:'white'
	});
	win.add(Ti.UI.createLabel({
		top:70, height:40, text:'Please log into Facebook',
		textAlign:'center'
	}));
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
	
	var blurField = Ti.UI.createButton({
		title:'Done',
		style:Titanium.UI.iPhone.SystemButtonStyle.DONE		
	});
	var statusText = Ti.UI.createTextField({
		top: 0, left: 10, right: 10, height: 40,
		hintText: 'Enter your FB status',
		keyboardToolbar:[
			Titanium.UI.createButton({systemButton:Titanium.UI.iPhone.SystemButton.FLEXIBLE_SPACE}),
			blurField],
	});
	blurField.addEventListener('click',function(e){
		statusText.blur();
	});
	actionsView.add(statusText);
	var statusBtn = Ti.UI.createButton({
		title: 'Publish status with GRAPH API',
		top: 45, left: 10, right: 10, height: 40
	});
	statusBtn.addEventListener('click', function() {
		var text = statusText.value;
		Ti.API.info('text value::'+text+';');
		if( (text === '')){
			Ti.UI.createAlertDialog({ tile:'ERROR', message:'No text to Publish !! '}).show(); 	
		}
		else
		{
			fb.reauthorize(['read_stream','publish_stream'],'everyone',function(e){
				if(e.success){
					fb.requestWithGraphPath('me/feed', {message: text}, "POST", showRequestResult);
				} else {
					Ti.API.debug('Failed authorization due to: ' + e.error);
				}
			});
		}
		
	});
	actionsView.add(statusBtn);
	
	var wall = Ti.UI.createButton({
		title: 'Publish wall post with GRAPH API',
		top: 90, left: 10, right: 10, height: 40
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
		fb.reauthorize(['read_stream','publish_stream'],'everyone',function(e){
			if(e.success){
				fb.requestWithGraphPath('me/feed', data, 'POST', showRequestResult);
			} else {
				Ti.API.debug('Failed authorization due to: ' + e.error);
			}
		});
	});
	actionsView.add(wall);
	
	var wallDialog = Ti.UI.createButton({
		title: 'Publish wall post with DIALOG',
		top: 135, left: 10, right: 10, height: 40
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
	win.add(actionsView);

	return win;
};
