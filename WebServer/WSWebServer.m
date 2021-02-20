/*
 * Copyright (C) 2010 Abhijeet Rastogi. All rights reserved.
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

#import "WSWebServer.h"

#import "WSRequestHandler.h"
#import "WSWebServerDelegate.h"

#include <arpa/inet.h>
#include <netdb.h>

@implementation WSWebServer

- (BOOL)startServerWithPort:(int)port {
    //Default Values PATH = ~/ and PORT=10000
    char PORT[16];
    sprintf(PORT, "%d", port);

    struct addrinfo hints, *res, *p;
    
    int listenfd = -1;

    // getaddrinfo for host
    memset (&hints, 0, sizeof(hints));
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_flags = AI_PASSIVE;
    if (getaddrinfo( NULL, PORT, &hints, &res) != 0)
    {
        perror("getaddrinfo() error");
        return NO;
    }
    // socket and bind
    for (p = res; p!=NULL; p=p->ai_next)
    {
        listenfd = socket (p->ai_family, p->ai_socktype, 0);
        if (listenfd == -1) continue;
        if (bind(listenfd, p->ai_addr, p->ai_addrlen) == 0) break;
    }
    
    if (p == NULL)
    {
        perror("socket() or bind()");
        return NO;
    }

    freeaddrinfo(res);

    // listen for incoming connections
    if ( listen (listenfd, 1000000) != 0 )
    {
        perror("listen() error");
        return NO;
    }

    // ACCEPT connections
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (1)
        {
            struct sockaddr_in clientaddr;
            socklen_t addrlen = sizeof(clientaddr);
            int socketDescriptor = accept(listenfd, (struct sockaddr *) &clientaddr, &addrlen);

            if (socketDescriptor < 0)
            {
                perror("accept() error");
            }
            else
            {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    WSRequestHandler *requestHandler = [[WSRequestHandler alloc] initWithSocketDescriptor:socketDescriptor];
                    if ([requestHandler handleRequest]) {
                        [self.delegate webServer:self startURLSchemeTask:requestHandler];
                    }
                });
            }
        }
    });

    return YES;
}

@end
