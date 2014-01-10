/**
 * Facebook Module
 * Copyright (c) 2009-2013 by Appcelerator, Inc. All Rights Reserved.
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiFacebookDialogRequest.h"

@implementation TiFacebookDialogRequest

#pragma mark Lifecycle

-(id)initWithCallback:(KrollCallback*)callback_ module:(FacebookModule*)module_
{
	if (self = [super init])
	{
		callback = [callback_ retain];
		module = [module_ retain];
		[self retain]; // this is because we return autoreleased and as a delegate we're not retained
	}
	return self;
}

-(void)dealloc
{
	RELEASE_TO_NIL(callback);
	RELEASE_TO_NIL(module);
	[super dealloc];
}


-(void)fireResult:(NSString *)result cancelled:(BOOL)cancelled error:(NSError *)error
{
	BOOL success = !cancelled && (error == nil);
	int code = [error code];
	if ((code == 0) && !success)
	{
		code = -1;
	}
	
	NSMutableDictionary *event = [NSMutableDictionary dictionaryWithObjectsAndKeys:
						   NUMBOOL(cancelled),@"cancelled",
						   NUMBOOL(success),@"success",
						   NUMINT(code),@"code",
						   result,@"result",nil];
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
	[module _fireEventToListener:@"result" withObject:event listener:callback thisObject:nil];
}

#pragma mark Delegate

/**
 * Called when the dialog succeeds with a returning url.
 */
- (void)dialogCompleteWithUrl:(NSURL *)url
{
	VerboseLog(@"[INFO] dialogCompleteWithUrl = %@",url);
	
	[self autorelease];

	// Based on the Android code, they return ONLY the query part of the URL as 'result'.  Let's do the same.
	// TODO: Android also attempts to parse the ref... but why would the ref ever contain a query...?
	[self fireResult:[url query] cancelled:NO error:nil];
}

/**
 * Called when the dialog get cancelled by the user.
 */
- (void)dialogDidNotCompleteWithUrl:(NSURL *)url
{
	VerboseLog(@"[INFO] dialogDidNotCompleteWithUrl = %@",url);

	[self autorelease];
	
	// Based on the Android code, they return ONLY the query part of the URL as 'result'.  Let's do the same.
	// TODO: Android also attempts to parse the ref... but why would the ref ever contain a query...?
	[self fireResult:[url query] cancelled:YES error:nil];
}

/**
 * Called when dialog failed to load due to an error.
 */
- (void)dialog:(FBDialog*)dialog didFailWithError:(NSError *)error
{
	VerboseLog(@"[INFO] didFailWithError = %@",error);
	
	[self autorelease];
	
	[self fireResult:nil cancelled:NO error:error];
}

/**
 * Asks if a link touched by a user should be opened in an external browser.
 *
 * If a user touches a link, the default behavior is to open the link in the Safari browser, 
 * which will cause your app to quit.  You may want to prevent this from happening, open the link
 * in your own internal browser, or perhaps warn the user that they are about to leave your app.
 * If so, implement this method on your delegate and return NO.  If you warn the user, you
 * should hold onto the URL and once you have received their acknowledgement open the URL yourself
 * using [[UIApplication sharedApplication] openURL:].
 */
- (BOOL)dialog:(FBDialog*)dialog shouldOpenURLInExternalBrowser:(NSURL *)url
{
	return NO;
}


@end
