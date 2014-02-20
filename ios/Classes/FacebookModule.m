/**
 * Facebook Module
 * Copyright (c) 2009-2013 by Appcelerator, Inc. All Rights Reserved.
 * Please see the LICENSE included with this distribution for details.
 */

#import "FacebookModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiBlob.h"
#import "TiUtils.h"
#import "TiApp.h"
#import "FBConnect/Facebook.h"
#import "TiFacebookRequest.h"
#import "TiFacebookDialogRequest.h"
#import "TiFacebookLoginButtonProxy.h"
#import "FBSBJSON.h"
#import "FBSession.h"

/**
 * Good reference for access_tokens and what all this crap means
 * http://benbiddington.wordpress.com/2010/04/23/facebook-graph-api-getting-access-tokens/
 */

@implementation FacebookModule
#pragma mark Internal

// this is generated for your module, please do not change it
-(id)moduleGUID
{
	return @"da8acc57-8673-4692-9282-e3c1a21f5d83";
}

// this is generated for your module, please do not change it
-(NSString*)moduleId
{
	return @"facebook";
}

@synthesize facebook;

#pragma mark Sessions

-(void)_save
{
	VerboseLog(@"[DEBUG] facebook _save");
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ((uid != (NSString *) [NSNull null]) && (uid.length > 0)) {
		[defaults setObject:uid forKey:@"FBUserId"];
	} else {
		[defaults removeObjectForKey:@"FBUserId"];
	}

	NSString *access_token = facebook.accessToken;
	if ((access_token != (NSString *) [NSNull null]) && (access_token.length > 0)) {
		[defaults setObject:access_token forKey:@"FBAccessToken"];
	} else {
		[defaults removeObjectForKey:@"FBAccessToken"];
	}

	NSDate *expirationDate = facebook.expirationDate;
	if (expirationDate) {
		[defaults setObject:expirationDate forKey:@"FBSessionExpires"];
	} else {
		[defaults removeObjectForKey:@"FBSessionExpires"];
	}

	if (appid) {
		[defaults setObject:appid forKey:@"FBAppId"];
	}else {
		[defaults removeObjectForKey:@"FBAppId"];
	}

	[defaults synchronize];
}

-(void)_unsave
{
	VerboseLog(@"[DEBUG] facebook _unsave");
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults removeObjectForKey:@"FBUserId"];
	[defaults removeObjectForKey:@"FBAccessToken"];
	[defaults removeObjectForKey:@"FBSessionExpires"];
	[defaults removeObjectForKey:@"FBAppId"];
	[defaults synchronize];
}

-(id)_restore
{
	VerboseLog(@"[DEBUG] facebook _restore");
	RELEASE_TO_NIL(uid);
	RELEASE_TO_NIL(facebook);
	RELEASE_TO_NIL(appid);
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *uid_ = [defaults objectForKey:@"FBUserId"];
	appid = [[defaults stringForKey:@"FBAppId"] copy];
	facebook = [[Facebook alloc] initWithAppId:appid urlSchemeSuffix:urlSchemeSuffix andDelegate:self];

	VerboseLog(@"[DEBUG] facebook _restore, uid = %@",uid_);
	if (uid_)
	{
		NSDate* expirationDate = [defaults objectForKey:@"FBSessionExpires"];
		VerboseLog(@"[DEBUG] facebook _restore, expirationDate = %@",expirationDate);
		if (!expirationDate || [expirationDate timeIntervalSinceNow] > 0) {
			uid = [uid_ copy];
			facebook.accessToken = [defaults stringForKey:@"FBAccessToken"];
			facebook.expirationDate = expirationDate;
			loggedIn = YES;
			[self performSelector:@selector(fbDidLogin)];
		}
	}
	return facebook;
}

#pragma mark Lifecycle

-(void)dealloc
{
	RELEASE_TO_NIL(facebook);
	RELEASE_TO_NIL(stateListeners);
	RELEASE_TO_NIL(appid);
	RELEASE_TO_NIL(permissions);
	RELEASE_TO_NIL(uid);
	RELEASE_TO_NIL(urlSchemeSuffix);
	[super dealloc];
}

-(BOOL)handleRelaunch
{
	NSDictionary *launchOptions = [[TiApp app] launchOptions];
	if (launchOptions!=nil)
	{
		NSString *urlString = [launchOptions objectForKey:@"url"];
		if (urlString!=nil && [urlString hasPrefix:@"fb"])
		{
			// if we're resuming under the same URL, we need to ignore
			if (url!=nil && [urlString isEqualToString:url])
			{
				return YES;
			}
			RELEASE_TO_NIL(url);
			url = [urlString copy];
			[facebook handleOpenURL:[NSURL URLWithString:urlString]];
			return YES;
		}
	}
	return NO;
}

-(void)resumed:(id)note
{
	VerboseLog(@"[DEBUG] facebook resumed");

	[self handleRelaunch];
}

-(void)autoExtendToken:(NSNotification *)notification
{
	[facebook extendAccessTokenIfNeeded];
}

-(void)startup
{
	VerboseLog(@"[DEBUG] facebook startup");
	[facebook setUrlSchemeSuffix:'myappsuffix'];
	[super startup];
	TiThreadPerformOnMainThread(^{
		NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(autoExtendToken:) name:UIApplicationDidBecomeActiveNotification object:nil];
		[nc addObserver:self selector:@selector(autoExtendToken:) name:UIApplicationSignificantTimeChangeNotification object:nil];
		[self _restore];
	}, YES);
	[self handleRelaunch];
}

-(void)shutdown:(id)sender
{
	VerboseLog(@"[DEBUG] facebook shutdown");

	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super shutdown:sender];
}

-(BOOL)isLoggedIn
{
	return (facebook!=nil) && ([facebook isSessionValid]) && loggedIn;
}

#pragma mark Internal

-(NSString*)convertParams:(NSMutableDictionary*)params
{
	NSString* httpMethod = nil;
	for (NSString *key in [params allKeys])
	{
		id param = [params objectForKey:key];

		// convert to blob
		if ([param isKindOfClass:[TiFile class]])
		{
			TiFile *file = (TiFile*)param;
			if ([file size] > 0)
			{
				param = [file toBlob:nil];
			}
			else
			{
				// empty file?
				param = [[[TiBlob alloc] initWithData:[NSData data] mimetype:@"text/plain"] autorelease];
			}
		}

		// this is an attachment, we need to convert to POST and switch to blob
		if ([param isKindOfClass:[TiBlob class]])
		{
			httpMethod = @"POST";
			TiBlob *blob = (TiBlob*)param;
			VerboseLog(@"[DEBUG] detected blob with mime: %@",[blob mimeType]);
			if ([[blob mimeType] hasPrefix:@"image/"])
			{
				UIImage *image = [blob image];
				[params setObject:image forKey:key];
			}
			else
			{
				NSData *data = [blob data];
				[params setObject:data forKey:key];
			}
		}
        // All other arguments need to be encoded as JSON if they aren't strings
        else if (![param isKindOfClass:[NSString class]]) {
			FBSBJSON * stringifier = [[FBSBJSON alloc] init];
            NSString* json_value = [stringifier stringWithObject:param allowScalar:YES error:nil];
            if (json_value == nil) {
                NSLog(@"Unable to encode argument %@:%@ to JSON: Encoding as ''",key,param);
				json_value = @"";
            }
            [params setObject:json_value forKey:key];
			[stringifier release];
        }
	}
	return httpMethod;
}

//This is here for backwards compatibility to replace ENSURE_CLASS.
//As of writing, building for 3.1.0 breaks 3.0.0 otherwise.
-(NSString *)errorStringIf:(id)value isNotClass:(NSString *)typeName forArgument:(NSString *)argName
{
	NSString * valueType;
	if([value isKindOfClass:[NSString class]]) valueType = @"a string";
	else if([value isKindOfClass:[NSNumber class]]) valueType = @"a number";
	else if([value isKindOfClass:[NSArray class]]) valueType = @"an array";
	else if([value isKindOfClass:[NSDictionary class]]) valueType = @"an object";
	else if([value isKindOfClass:[KrollCallback class]]) valueType = @"a function";
	else if([value isKindOfClass:[KrollWrapper class]]) valueType = @"a function";
	else
	{
		valueType = [value description];
	}
	return [NSString stringWithFormat:@"%@ takes a %@, but was passed %@ instead",argName,typeName,valueType];
}
#define FACEBOOK_ENSURE_TYPE(x,t,n)	\
if(![x isKindOfClass:[t class]]){ \
[self throwException:TiExceptionInvalidType subreason: \
[self errorStringIf:x isNotClass:n forArgument:@"" #x] location:CODELOCATION]; \
}

#pragma mark Public APIs

/**
 * JS example:
 *
 * var facebook = require('facebook');
 * alert(facebook.uid);
 *
 */
-(id)uid
{
	return uid;
}

/**
 * JS example:
 *
 * var facebook = require('facebook');
 * if (facebook.loggedIn) {
 * }
 *
 */
-(id)loggedIn
{
	return NUMBOOL([self isLoggedIn]);
}

/**
 * JS example:
 *
 * var facebook = require('facebook');
 * facebook.appid = '1234';
 * alert(facebook.appid);
 *
 */
-(id)appid
{
	return appid;
}

/**
 * JS example:
 *
 * var facebook = require('facebook');
 * facebook.permissions = ['read_stream'];
 * alert(facebook.permissions);
 *
 */
-(id)permissions
{
	return permissions;
}

/**
 * JS example:
 *
 * var facebook = require('facebook');
 * facebook.urlSchemeSuffix = 'myappsuffix';
 * alert(facebook.urlSchemeSuffix);
 *
 */
-(id)urlSchemeSuffix
{
	return urlSchemeSuffix;
}

/**
 * JS example:
 *
 * var facebook = require('facebook');
 * alert(facebook.forceDialogAuth);
 *
 */
-(id)forceDialogAuth
{
	return [NSNumber numberWithBool:forceDialogAuth];
}

/**
 * JS example:
 *
 * var facebook = require('facebook');
 * alert(facebook.accessToken);
 *
 */
-(id)accessToken
{
	return [facebook accessToken];
}

/**
 * JS example:
 *
 * var facebook = require('facebook');
 * alert(facebook.expirationDate);
 *
 */
-(id)expirationDate
{
	return [facebook expirationDate];
}

/**
 * JS example:
 *
 * var facebook = require('facebook');
 * facebook.appid = '1234';
 * alert(facebook.appid);
 *
 */
-(void)setAppid:(id)arg
{
	[appid autorelease];
	appid = [[TiUtils stringValue:arg] copy];
	[facebook setAppId:appid];
}

/**
 * JS example:
 *
 * var facebook = require('facebook');
 * facebook.permissions = ['publish_stream'];
 * alert(facebook.permissions);
 *
 */
-(void)setPermissions:(id)arg
{
	RELEASE_TO_NIL(permissions);
	permissions = [arg retain];
}

/**
 * JS example:
 *
 * var facebook = require('facebook');
 * facebook.urlSchemeSuffix = 'myappsuffix';
 * alert(facebook.urlSchemeSuffix);
 *
 */
-(void)setUrlSchemeSuffix:(id)arg
{
	RELEASE_TO_NIL(urlSchemeSuffix);
	urlSchemeSuffix = [arg copy];
	[facebook setUrlSchemeSuffix:urlSchemeSuffix];
}

/**
 * JS example:
 *
 * var facebook = require('facebook');
 * facebook.forceDialogAuth = true;
 * alert(facebook.forceDialogAuth);
 *
 */
-(void)setForceDialogAuth:(id)arg
{
	forceDialogAuth = [TiUtils boolValue:arg def:NO];
}

/**
 * JS example:
 *
 * var facebook = require('facebook');
 *
 * facebook.addEventListener('login',function(e) {
 *    if (e.success) {
 *		alert('login from uid: '+e.uid+', name: '+e.data.name);
 *    }
 *    else if (e.cancelled) {
 *      // user cancelled logout
 *    }
 *    else {
 *      alert(e.error);
 *    }
 * });
 *
 * facebook.addEventListener('logout',function(e) {
 *    alert('logged out');
 * });
 *
 * facebook.appid = 'my_appid';
 * facebook.permissions = ['publish_stream'];
 * facebook.authorize();
 *
 */
-(void)authorize:(id)args
{
	VerboseLog(@"[DEBUG] facebook authorize");

	if ([self isLoggedIn])
	{
		// if already authorized, this should do nothing
		return;
	}

	if (appid==nil)
	{
		[self throwException:@"missing appid" subreason:nil location:CODELOCATION];
	}

	TiThreadPerformOnMainThread(^{
		// forget in case it fails
		[self _unsave];

		NSArray *permissions_ = permissions == nil ? [NSArray array] : permissions;
		[facebook setForceDialog:forceDialogAuth];
		[facebook authorize:permissions_];
	}, NO);
}

/**
 * JS example:
 *
 * var facebook = require('facebook');
 * ...
 * //While authorized for readonly permissions.
 * facebook.reauthorize(['read_stream','publish_stream'],'everyone',function(e){
 *     if(e.success){
 *         facebook.requestWithGraphPath(...);
 *     } else {
 *         Ti.API.debug('Failed authorization due to: ' + e.error);
 *     }
 * });
 */
-(void)reauthorize:(id)args
{
	ENSURE_ARG_COUNT(args, 3);

	if (![self isLoggedIn])
	{
		[self throwException:@"NotAuthorized" subreason:@"App tried to reauthorize before being logged in." location:CODELOCATION];
		return;
	}

	NSArray * writePermissions = [args objectAtIndex:0];
	NSString * audienceString = [TiUtils stringValue:[args objectAtIndex:1]];
	KrollCallback * callback = [args objectAtIndex:2];

	FACEBOOK_ENSURE_TYPE(writePermissions, NSArray, @"an array");
	FACEBOOK_ENSURE_TYPE(audienceString, NSString, @"a string");
	FACEBOOK_ENSURE_TYPE(callback, KrollCallback, @"a function");

	FBSessionLoginBehavior behavior = FBSessionLoginBehaviorUseSystemAccountIfPresent;
	FBSessionDefaultAudience audience = FBSessionDefaultAudienceEveryone;

	FBSessionReauthorizeResultHandler handler= ^(FBSession *session, NSError *error)
	{
		bool success = (error == nil);
		NSString * errorString = nil;
		int code = 0;
		if(!success)
		{
			code = [error code];
			if (code == 0)
			{
				code = -1;
			}
			errorString = [error localizedDescription];
			NSString * userInfoMessage = [[error userInfo] objectForKey:@"message"];
			if (errorString == nil)
			{
				errorString = userInfoMessage;
			}
			else if (userInfoMessage != nil)
			{
				errorString = [errorString stringByAppendingFormat:@" %@",userInfoMessage];
			}
		}

		NSNumber * errorCode = [NSNumber numberWithInteger:code];
		NSDictionary * propertiesDict = [[NSDictionary alloc] initWithObjectsAndKeys:
										 [NSNumber numberWithBool:success],@"success",
										 errorCode,@"code", errorString,@"error", nil];

		KrollEvent * invocationEvent = [[KrollEvent alloc] initWithCallback:callback eventObject:propertiesDict thisObject:self];
		[[callback context] enqueue:invocationEvent];
		[invocationEvent release];
		[propertiesDict release];
	};

	TiThreadPerformOnMainThread(^{
		[[facebook session] reauthorizeWithPublishPermissions:writePermissions
											  defaultAudience:audience
											completionHandler:handler];
	}, NO);
}

/**
 * JS example:
 *
 * var facebook = require('facebook');
 * facebook.logout();
 *
 */
-(void)logout:(id)args
{
	VerboseLog(@"[DEBUG] facebook logout");
	if ([self isLoggedIn])
	{
		TiThreadPerformOnMainThread(^{[facebook logout:self];}, NO);
	}
}

/**
 * JS example:
 *
 * var facebook = require('facebook');
 *
 * facebook.requestWithGraphPath('me',{}, 'post', function(e) {
 *    if (e.success) {
 *      alert('success! welcome userid: '+e.id);
 *    }
 *    else {
 *      alert(e.error);
 *    }
 * });
 *
 */
-(void)requestWithGraphPath:(id)args
{
	VerboseLog(@"[DEBUG] facebook requestWithGraphPath");

	ENSURE_ARG_COUNT(args,4);

	NSString* path = [args objectAtIndex:0];
	NSMutableDictionary* params = [args objectAtIndex:1];
	NSString* httpMethod = [args objectAtIndex:2];
	KrollCallback* callback = [args objectAtIndex:3];

	FACEBOOK_ENSURE_TYPE(path, NSString, @"a string");
	FACEBOOK_ENSURE_TYPE(params, NSDictionary, @"an object");
	FACEBOOK_ENSURE_TYPE(httpMethod, NSString, @"a string");
	FACEBOOK_ENSURE_TYPE(callback, KrollCallback, @"a function");

	[self convertParams:params];

	TiThreadPerformOnMainThread(^{
		TiFacebookRequest* delegate = [[[TiFacebookRequest alloc] initWithPath:path callback:callback module:self graph:YES] autorelease];
		[facebook requestWithGraphPath:path andParams:params andHttpMethod:httpMethod andDelegate:delegate];
	}, NO);
}

/**
 * JS example:
 *
 * var facebook = require('facebook');
 *
 * facebook.request('photos.upload',{picture:blob},function(e) {
 *    if (e.success) {
 *      alert('success!');
 *    }
 *    else {
 *      alert(e.error);
 *    }
 * });
 *
 */
-(void)request:(id)args
{
	VerboseLog(@"[DEBUG] facebook request");

	ENSURE_ARG_COUNT(args,3);

	NSString* method = [args objectAtIndex:0];
	NSMutableDictionary* params = [args objectAtIndex:1];
	KrollCallback* callback = [args objectAtIndex:2];

	FACEBOOK_ENSURE_TYPE(method, NSString, @"a string");
	FACEBOOK_ENSURE_TYPE(params, NSDictionary, @"an object");
	FACEBOOK_ENSURE_TYPE(callback, KrollCallback, @"a function");

	NSString *httpMethod = @"GET";
	NSString* changedHttpMethod = [self convertParams:params];
	if (changedHttpMethod != nil) {
		httpMethod = changedHttpMethod;
	}

	TiThreadPerformOnMainThread(^{
		TiFacebookRequest* delegate = [[[TiFacebookRequest alloc] initWithPath:method callback:callback module:self graph:NO] autorelease];
		[facebook requestWithMethodName:method andParams:params andHttpMethod:httpMethod andDelegate:delegate];
	}, NO);
}

/**
 * JS example:
 *
 * var facebook = require('facebook');
 * facebook.dialog('stream.publish',{'api_key':'1234'},function(e) {
 *    if (e.success) {
 *       Ti.API.info('result was = '+JSON.stringify(e.result));
 *    }
 * });
 *
 */
-(void)dialog:(id)args
{
	ENSURE_ARG_COUNT(args,3);

	VerboseLog(@"[DEBUG] facebook dialog");

	NSString* action = [args objectAtIndex:0];
	NSMutableDictionary* params = [args objectAtIndex:1];
	KrollCallback* callback = [args objectAtIndex:2];

	FACEBOOK_ENSURE_TYPE(action, NSString, @"a string");
	FACEBOOK_ENSURE_TYPE(params, NSDictionary, @"an object");
	FACEBOOK_ENSURE_TYPE(callback, KrollCallback, @"a function");

	[self convertParams:params];

	TiThreadPerformOnMainThread(^{
		TiFacebookDialogRequest *delegate = [[[TiFacebookDialogRequest alloc] initWithCallback:callback module:self] autorelease];
		[facebook dialog:action andParams:params andDelegate:delegate];
	}, NO);
}

/**
 * JS example:
 *
 * var facebook = require('facebook');
 * var button = facebook.createLoginButton({bottom:10});
 * window.add(button);
 *
 */
-(id)createLoginButton:(id)args
{
	return [[[TiFacebookLoginButtonProxy alloc] _initWithPageContext:[self executionContext] args:args module:self] autorelease];
}

#pragma mark Listener work

-(void)fireLoginChange
{
	if (stateListeners!=nil)
	{
		for (id<TiFacebookStateListener> listener in [NSArray arrayWithArray:stateListeners])
		{
			if (loggedIn)
			{
				[listener login];
			}
			else
			{
				[listener logout];
			}
		}
	}
}

-(void)fireLogin:(id)result cancelled:(BOOL)cancelled withError:(NSError *)error
{
	BOOL success = (result != nil);
	int code = [error code];
	if ((code == 0) && !success)
	{
		code = -1;
	}
	NSMutableDictionary *event = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								  NUMBOOL(cancelled),@"cancelled",
								  NUMBOOL(success),@"success",
								  NUMINT(code),@"code",nil];
	if(error != nil){
		NSString * errorString = [error localizedDescription];
		NSString * userInfoMessage = [[error userInfo] objectForKey:@"message"];
		if (errorString == nil)
		{
			errorString = userInfoMessage;
		}
		else if (userInfoMessage != nil)
		{
			errorString = [errorString stringByAppendingFormat:@" %@",userInfoMessage];
		}

		if (errorString != nil) {
			[event setObject:errorString forKey:@"error"];
		}
	}
	else if (cancelled)
	{
		[event setObject:@"User cancelled the login process." forKey:@"error"];
	}

	if(result != nil)
	{
		[event setObject:result forKey:@"data"];
		if (uid != nil)
		{
			[event setObject:uid forKey:@"uid"];
		}
	}
	[self fireEvent:@"login" withObject:event];
}


#pragma mark Delegate

/**
 * Called when the user successfully logged in.
 */
- (void)fbDidLogin
{
	VerboseLog(@"[DEBUG] facebook fbDidLogin");

	[facebook requestWithGraphPath:@"me" andDelegate:self];
}

/**
 * Called when the user dismissed the dialog without logging in.
 */
- (void)fbDidNotLogin:(BOOL)cancelled
{
	VerboseLog(@"[DEBUG] facebook fbDidNotLogin: cancelled=%d",cancelled);
	loggedIn = NO;
	[self fireLoginChange];
	[self fireLogin:nil cancelled:cancelled withError:nil];
}

/**
 * Called when the user logged out.
 */
- (void)fbDidLogout
{
	VerboseLog(@"[DEBUG] facebook fbDidLogout");

	loggedIn = NO;
	[self _unsave];
	[self fireLoginChange];
	[self fireEvent:@"logout"];
}

- (void)fbDidExtendToken:(NSString*)accessToken
               expiresAt:(NSDate*)expiresAt;

{
	[self _save];
}

- (void)fbSessionInvalidated;
{
	loggedIn = NO;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults removeObjectForKey:@"FBAccessToken"];
	[defaults removeObjectForKey:@"FBSessionExpires"];
	[defaults synchronize];
	[self fireLoginChange];
	//Because the user ID is still the same, we can't unsave. The
	//session expiring should NOT be considered an active move by the user
	//to log out, so maintain userID and appID and do not spoof a logout.
}


//----------- these are only used when the login is successful to grab UID

/**
 * FBRequestDelegate
 */
- (void)request:(FBRequest*)request didLoad:(id)result
{
	VerboseLog(@"[DEBUG] facebook didLoad");

	RELEASE_TO_NIL(uid);
	uid = [[result objectForKey:@"id"] copy];
	[self _save];
	loggedIn = YES;
	[self fireLoginChange];
	[self fireLogin:result cancelled:NO withError:nil];
}


- (void)request:(FBRequest*)request didFailWithError:(NSError*)error
{
	VerboseLog(@"[DEBUG] facebook didFailWithError: %@",error);

	RELEASE_TO_NIL(uid);
	loggedIn = NO;
	[self fireLoginChange];
	[self fireLogin:nil cancelled:NO withError:error];
}

#pragma mark Listeners

-(void)addListener:(id<TiFacebookStateListener>)listener
{
	if (stateListeners==nil)
	{
		stateListeners = [[NSMutableArray alloc]init];
	}
	[stateListeners addObject:listener];
}

-(void)removeListener:(id<TiFacebookStateListener>)listener
{
	if (stateListeners!=nil)
	{
		[stateListeners removeObject:listener];
		if ([stateListeners count]==0)
		{
			RELEASE_TO_NIL(stateListeners);
		}
	}
}

MAKE_SYSTEM_PROP(BUTTON_STYLE_NORMAL,FB_LOGIN_BUTTON_NORMAL);
MAKE_SYSTEM_PROP(BUTTON_STYLE_WIDE,FB_LOGIN_BUTTON_WIDE);

@end
