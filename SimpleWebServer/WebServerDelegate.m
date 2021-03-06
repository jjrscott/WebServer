/*
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

#import "WebServerDelegate.h"

@implementation WebServerDelegate

- (void)webServer:(WSWebServer *)webServer startURLSchemeTask:(id<WSURLSchemeTask>)urlSchemeTask {
    NSLog(@"request.URL = %@", urlSchemeTask.request.URL);
    NSLog(@"request.HTTPMethod = %@", urlSchemeTask.request.HTTPMethod);
    NSLog(@"request.allHTTPHeaderFields = %@", urlSchemeTask.request.allHTTPHeaderFields);
    NSLog(@"request.HTTPBody = %@", urlSchemeTask.request.HTTPBody);
    
    [urlSchemeTask didReceiveResponseWithURL:urlSchemeTask.request.URL
                                  statusCode:200
                                headerFields:nil];
    [urlSchemeTask didReceiveData:[@"Hello World!" dataUsingEncoding:NSUTF8StringEncoding]];
    [urlSchemeTask didFinish];
}

- (void)webServer:(WSWebServer *)webServer stopURLSchemeTask:(id<WSURLSchemeTask>)urlSchemeTask {
    
}

@end
