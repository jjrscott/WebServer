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

#import "WSRequestHandler.h"

#include <sys/socket.h>

#define BYTES 1024

@interface WSRequestHandler ()

@property (nonatomic, assign) int socketDescriptor;

@end

@implementation WSRequestHandler

- (instancetype)initWithSocketDescriptor:(int)fd {
    self = [super init];
    if (self) {
        self.socketDescriptor = fd;
    }
    return self;
}

- (BOOL)handleRequest {
    char mesg[99999];
    ssize_t rcvd;

    memset( (void*)mesg, (int)'\0', 99999 );

    rcvd = recv(self.socketDescriptor, mesg, 99999, 0);

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
    shutdown (self.socketDescriptor, SHUT_RDWR);         //All further send and recieve operations are DISABLED...
    close(self.socketDescriptor);
}

- (void)didReceiveData:(nonnull NSData *)data {
    [self _sendData:data];
}

- (void)didReceiveResponseWithURL:(NSURL *)url statusCode:(NSInteger)statusCode headerFields:(nullable NSDictionary<NSString *, NSString *> *)headerFields {
    [self _sendStringWithFormat:@"HTTP/1.0 %ld %@\r\n", statusCode, [self stringForStatusCode:statusCode]];
    [headerFields enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull key, NSString *  _Nonnull value, BOOL * _Nonnull stop) {
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
        send (self.socketDescriptor, bytes, byteRange.length, 0);
    }];
}

- (NSString*)stringForStatusCode:(NSInteger)statusCode {
    // https://github.com/erunion/http-status-code-definitions
    switch (statusCode) {
        case 100: return @"Continue";
        case 101: return @"Switching Protocols";
        case 102: return @"Processing";

        case 200: return @"OK";
        case 201: return @"Created";
        case 202: return @"Accepted";
        case 203: return @"Non-Authoritative Information";
        case 204: return @"No Content";
        case 205: return @"Reset Content";
        case 206: return @"Partial Content";
        case 207: return @"Multi-Status";

        case 300: return @"Multiple Choices";
        case 301: return @"Moved Permanently";
        case 302: return @"Found";
        case 303: return @"See Other";
        case 304: return @"Not Modified";
        case 305: return @"Use Proxy";
        case 307: return @"Temporary Redirect";

        case 400: return @"Bad Request";
        case 401: return @"Authorization Required";
        case 402: return @"Payment Required";
        case 403: return @"Forbidden";
        case 404: return @"Not Found";
        case 405: return @"Method Not Allowed";
        case 406: return @"Not Acceptable";
        case 407: return @"Proxy Authentication Required";
        case 408: return @"Request Time-out";
        case 409: return @"Conflict";
        case 410: return @"Gone";
        case 411: return @"Length Required";
        case 412: return @"Precondition Failed";
        case 413: return @"Request Entity Too Large";
        case 414: return @"Request-URI Too Large";
        case 415: return @"Unsupported Media Type";
        case 416: return @"Requested Range Not Satisfiable";
        case 417: return @"Expectation Failed";
        case 422: return @"Unprocessable Entity";
        case 423: return @"Locked";
        case 424: return @"Failed Dependency";
        case 426: return @"Upgrade Required";

        case 500: return @"Internal Server Error";
        case 501: return @"Method Not Implemented";
        case 502: return @"Bad Gateway";
        case 503: return @"Service Temporarily Unavailable";
        case 504: return @"Gateway Time-out";
        case 505: return @"HTTP Version Not Supported";
        case 506: return @"Variant Also Negotiates";
        case 507: return @"Insufficient Storage";
        case 510: return @"Not Extended";
    }
    return nil;
}

@end
