/**
 * Facebook Module
 * Copyright (c) 2009-2013 by Appcelerator, Inc. All Rights Reserved.
 * Please see the LICENSE included with this distribution for details.
 */

#import "FBConnect/Facebook.h"
#import "FacebookModule.h"
#import "KrollCallback.h"

@interface TiFacebookDialogRequest : NSObject <FBDialogDelegate> {

	KrollCallback *callback;
	FacebookModule *module;
}

-(id)initWithCallback:(KrollCallback*)callback_ module:(FacebookModule*)module_;

@end
