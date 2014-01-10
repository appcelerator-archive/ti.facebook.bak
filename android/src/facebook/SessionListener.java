/**
 * Facebook Module
 * Copyright (c) 2009-2013 by Appcelerator, Inc. All Rights Reserved.
 * Please see the LICENSE included with this distribution for details.
 */

package facebook;

import org.appcelerator.kroll.common.Log;

import facebook.SessionEvents.AuthListener;
import facebook.SessionEvents.LogoutListener;

// Implementation of Facebook SessionEvents.AuthListener and SessionEvents.LogoutListener
public class SessionListener implements AuthListener, LogoutListener {
    private FacebookModule fbmod;
    public SessionListener(FacebookModule fbmod)
    {
    	this.fbmod = fbmod;
    }
    
    public void onAuthSucceed() {
    	fbmod.debug("onAuthSucceed");
    	fbmod.completeLogin();
    }

    public void onAuthFail(String error) {
    	Log.e(FacebookModule.TAG, "onAuthFail: " + error);
    }
    
    public void onLogoutBegin() {
    	fbmod.debug("onLogoutBegin");
    }
    
    public void onLogoutFinish() {
    	fbmod.debug("onLogoutFinish");
        fbmod.completeLogout();
    }
}

