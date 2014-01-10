/**
 * Facebook Module
 * Copyright (c) 2009-2013 by Appcelerator, Inc. All Rights Reserved.
 * Please see the LICENSE included with this distribution for details.
 */

#import "FacebookModule.h"
#import "KrollCallback.h"
#import "FBConnect/Facebook.h"

@interface TiFacebookRequest : NSObject<FBRequestDelegate> {
	NSString *path;
	KrollCallback *callback;
	FacebookModule *module;
	BOOL graph;
}

-(id)initWithPath:(NSString*)path_ callback:(KrollCallback*)callback_ module:(FacebookModule*)module_ graph:(BOOL)graph_;

@end
