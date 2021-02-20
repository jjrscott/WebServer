/*
 * Copyright (C) 2017 Apple Inc. All rights reserved.
 * Copyright (C) 2021 John Scott. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>

@class WSWebServer;
@protocol WSURLSchemeTask;


/*! A class conforming to the WSWebserverDelegate protocol provides methods for
 loading resources.
 */
@protocol WSWebServerDelegate <NSObject>

/*! @abstract Notifies your app to start loading the data for a particular resource
 represented by the URL scheme handler task.
 @param webServer The web server invoking the method.
 @param urlSchemeTask The task that your app should start loading data for.
 */
- (void)webServer:(WSWebServer *)webServer startURLSchemeTask:(id <WSURLSchemeTask>)urlSchemeTask;

/*! @abstract Notifies your app to stop handling a URL scheme handler task.
 @param webServer The web server invoking the method.
 @param urlSchemeTask The task that your app should stop handling.
 @discussion After your app is told to stop loading data for a URL scheme handler task
 it must not perform any callbacks for that task.
 An exception will be thrown if any callbacks are made on the URL scheme handler task
 after your app has been told to stop loading for it.
 */
- (void)webServer:(WSWebServer *)webServer stopURLSchemeTask:(id <WSURLSchemeTask>)urlSchemeTask;

@end
