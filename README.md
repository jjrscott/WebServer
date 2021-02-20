# WebServer

Simple webserver inspired by WebKit's [WKURLSchemeTask](https://github.com/WebKit/WebKit/blob/main/Source/WebKit/UIProcess/API/Cocoa/WKURLSchemeTask.h) and based off [A Very Simple HTTP Server writen in C](https://blog.abhi.host/blog/2010/04/15/very-simple-http-server-writen-in-c/) by [Abhijeet Rastogi](https://blog.abhi.host/blog/).


```objc
WSWebServer *webServer = [WSWebServer new];
WebServerDelegate *webServerDelegate = [WebServerDelegate new];
webServer.delegate = webServerDelegate;
[webServer startServerWithPort:10000];
```

Responses are managed by way of WSWebServerDelegate:

```objc
- (void)webServer:(WSWebServer *)webServer startURLSchemeTask:(id<WSURLSchemeTask>)urlSchemeTask {
    [urlSchemeTask didReceiveResponseWithURL:urlSchemeTask.request.URL
                                  statusCode:200
                                headerFields:nil];
    [urlSchemeTask didReceiveData:[@"Hello World!" dataUsingEncoding:NSUTF8StringEncoding]];
    [urlSchemeTask didFinish];
}

- (void)webServer:(WSWebServer *)webServer stopURLSchemeTask:(id<WSURLSchemeTask>)urlSchemeTask {
    
}
```

