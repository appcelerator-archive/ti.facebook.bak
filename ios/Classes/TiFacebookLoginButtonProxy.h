/**
 * Facebook Module
 * Copyright (c) 2009-2013 by Appcelerator, Inc. All Rights Reserved.
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiViewProxy.h"
#import "FacebookModule.h"
#import "TiFacebookLoginButton.h"

@interface TiFacebookLoginButtonProxy : TiViewProxy {

	FacebookModule *module;
}

-(id)_initWithPageContext:(id<TiEvaluator>)context_ args:(id)args module:(FacebookModule*)module_;

@property(nonatomic,readonly) FacebookModule *_module;

-(void)internalSetWidth:(id)width;
-(void)internalSetHeight:(id)height;

@end
