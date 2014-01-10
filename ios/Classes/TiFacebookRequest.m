/**
 * Facebook Module
 * Copyright (c) 2009-2013 by Appcelerator, Inc. All Rights Reserved.
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiFacebookRequest.h"
#import "FBSBJSON.h"

@implementation TiFacebookRequest

-(id)initWithPath:(NSString*)path_ callback:(KrollCallback*)callback_ module:(FacebookModule*)module_ graph:(BOOL)graph_
{
	if (self = [super init])
	{
		path = [path_ retain];
		callback = [callback_ retain];
		module = [module_ retain];
		graph = graph_;
		[self retain]; // since we're a delegate, we retain and release on callback
	}
	return self;
}

-(void)dealloc
{
	RELEASE_TO_NIL(path);
	RELEASE_TO_NIL(callback);
	RELEASE_TO_NIL(module);
	[super dealloc];
}

-(NSMutableDictionary*)eventParameters:(NSError *)error
{
	//Eventually consistent error reporting will become core
	//to event passing in Titanium
	
	NSNumber * success = [NSNumber numberWithBool:error==nil];
	int code = [error code];
	if ((error != nil) && (code == 0)) {
		code = -1;
	}
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

	return [NSMutableDictionary dictionaryWithObjectsAndKeys:
			NUMBOOL(graph),@"graph",
			path,(graph?@"path":@"method"),
			success,@"success",
			NUMINT(code),@"code",
			errorString,@"error",
			nil];
}

#pragma mark Delegates

/**
 * Called when an error prevents the request from completing successfully.
 */
- (void)request:(FBRequest*)request didFailWithError:(NSError*)error
{
	VerboseLog(@"[DEBUG] facebook didFailWithError = %@",error);
    VerboseLog(@"[DEBUG] Facebook Error description : %@ ", [error userInfo]);
    
	NSMutableDictionary *event = [self eventParameters:error];
	[module _fireEventToListener:@"result" withObject:event listener:callback thisObject:nil];
	[self autorelease];
}

/**
 * Called when a request returns and its response has been parsed into an object.
 *
 * The resulting object may be a dictionary, an array, a string, or a number, depending
 * on thee format of the API response.
 */
- (void)request:(FBRequest*)request didLoad:(id)result
{
	VerboseLog(@"[DEBUG] facebook didLoad");
	NSMutableDictionary *event = [self eventParameters:nil];
	
	// On Android, Facebook is a little braindead and so it returns the stringified result without parsing the JSON.
	// But here, we do the opposite.  So... we re-stringify and ship as a JSON string.

	FBSBJSON * stringifier = [[FBSBJSON alloc] init];
	NSString* resultString = [stringifier stringWithObject:result allowScalar:YES error:nil];
	if (resultString == nil) {
		NSLog(@"Unable to encode argument %@ to JSON: Encoding as ''",result);
		resultString = @"";
	}
	[stringifier release];
	[event setObject:resultString forKey:@"result"];
	[module _fireEventToListener:@"result" withObject:event listener:callback thisObject:nil];
	[self autorelease];
}

@end

