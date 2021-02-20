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

#import "XWSURLSchemeTask.h"

#include <sys/socket.h>

#define BYTES 1024

@interface WSURLSchemeTask ()

@property (nonatomic, assign) int fileDescriptor;

@end

@implementation WSURLSchemeTask

- (instancetype)initWithFileDescriptor:(int)fd {
    self = [super init];
    if (self) {
        self.fileDescriptor = fd;
    }
    return self;
}

- (BOOL)handleRequest {
    char mesg[99999];
    ssize_t rcvd;

    memset( (void*)mesg, (int)'\0', 99999 );

    rcvd = recv(self.fileDescriptor, mesg, 99999, 0);

    if (rcvd<0)    // receive error
    {
        fprintf(stderr, "recv() error\n");
    }
    else if (rcvd==0)    // receive socket closed
    {
        fprintf(stderr, "Client disconnected upexpectedly.\n");
    }
    else    // message received
    {
        NSString *string = [[NSString alloc] initWithBytes:mesg length:rcvd encoding:NSUTF8StringEncoding];
        NSScanner *scanner = [NSScanner scannerWithString:string];
        scanner.charactersToBeSkipped = nil;
        NSString *method;
        [scanner scanUpToString:@" " intoString:&method];
        [scanner scanString:@" " intoString:NULL];
        NSString *path;
        [scanner scanUpToString:@" " intoString:&path];
        [scanner scanString:@" " intoString:NULL];
        NSString *version;
        [scanner scanUpToString:@"\r\n" intoString:&version];

        NSString *key;
        NSMutableDictionary *allHTTPHeaderFields = [NSMutableDictionary new];
        while ([scanner scanString:@"\r\n" intoString:NULL] && [scanner scanUpToString:@":" intoString:&key] && ![scanner isAtEnd]) {
            [scanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@": "] intoString:NULL];
            NSString *value;
            [scanner scanUpToString:@"\r\n" intoString:&value];
            allHTTPHeaderFields[key] = value;
        }

        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:path]];
        request.HTTPMethod = method;
        request.allHTTPHeaderFields = allHTTPHeaderFields;
        request.HTTPBody = [NSData dataWithBytes:mesg+scanner.scanLocation length:rcvd-scanner.scanLocation];

        self.request = request;
        return YES;
    }
    [self didFinish];
    return NO;
}

- (void)didFailWithError:(nonnull NSError *)error {
    [self didFinish];
    abort();
}

- (void)didFinish {
    shutdown (self.fileDescriptor, SHUT_RDWR);         //All further send and recieve operations are DISABLED...
    close(self.fileDescriptor);
}

- (void)didReceiveData:(nonnull NSData *)data {
    [self _sendData:data];
}

- (void)didReceiveResponse:(nonnull NSHTTPURLResponse *)response {
    
    [self _sendStringWithFormat:@"HTTP/1.0 %ld OK\r\n", response.statusCode];
    [response.allHeaderFields enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull key, NSString *  _Nonnull value, BOOL * _Nonnull stop) {
        [self _sendStringWithFormat:@"%@: %@\r\n", key, value];
    }];

    [self _sendStringWithFormat:@"\r\n"];
}

- (void)_sendStringWithFormat:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2) {
    va_list argp;
    va_start(argp, format);
    NSString *string = [[NSString alloc] initWithFormat:format arguments:argp];
    va_end(argp);
    [self _sendData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)_sendData:(nonnull NSData *)data {
    [data enumerateByteRangesUsingBlock:^(const void * _Nonnull bytes, NSRange byteRange, BOOL * _Nonnull stop) {
        send (self.fileDescriptor, bytes, byteRange.length, 0);
    }];
}

@end
