/**
 * Facebook Module
 * Copyright (c) 2009-2013 by Appcelerator, Inc. All Rights Reserved.
 * Please see the LICENSE included with this distribution for details.
 */

package facebook;

import org.appcelerator.kroll.annotations.Kroll;
import org.appcelerator.kroll.common.Log;
import org.appcelerator.titanium.TiContext;
import org.appcelerator.titanium.proxy.TiViewProxy;
import org.appcelerator.titanium.view.TiUIView;

import android.app.Activity;

@Kroll.proxy(parentModule=FacebookModule.class)
public class TiFacebookModuleLoginButtonProxy extends TiViewProxy
{
	private FacebookModule facebookModule = null;

	public TiFacebookModuleLoginButtonProxy()
	{
		super();
	}

	public TiFacebookModuleLoginButtonProxy(TiContext tiContext)
	{
		this();
	}
	
	public TiFacebookModuleLoginButtonProxy(FacebookModule facebookModule)
	{
		this();
		Log.d("LoginButtonProxy", "Second constructor called", Log.DEBUG_MODE);
		this.facebookModule = facebookModule;
	}

	public TiFacebookModuleLoginButtonProxy(TiContext tiContext, FacebookModule facebookModule)
	{
		this(facebookModule);
	}

	@Override
	public TiUIView createView(Activity activity) {
		return new TiLoginButton(this);
	}
	
	public FacebookModule getFacebookModule() {
		return this.facebookModule;
	}
}
