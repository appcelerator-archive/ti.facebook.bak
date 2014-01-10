/**
 * Facebook Module
 * Copyright (c) 2009-2013 by Appcelerator, Inc. All Rights Reserved.
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiUIView.h"
#import "FBConnect/FBLoginButton.h"
#import "FacebookModule.h"

@interface TiFacebookLoginButton : TiUIView<TiFacebookStateListener> {

	FBLoginButton *button;
}

@end
