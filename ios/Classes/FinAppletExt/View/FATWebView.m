//
//  FATWebView.m
//  FinApplet
//
//  Created by Haley on 2019/12/9.
//  Copyright © 2019 finogeeks. All rights reserved.
//

#import "FATWebView.h"

#import <FinApplet/FinApplet.h>
#import <WebKit/WebKit.h>
#import "FATExtUtil.h"

@interface FATWebView () <WKScriptMessageHandler, WKUIDelegate, WKNavigationDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) WKWebView *webView;

@property (nonatomic, strong) UIProgressView *progressView;

@property (nonatomic, copy) NSString *appletId;

@end

@implementation FATWebView

- (instancetype)initWithFrame:(CGRect)frame URL:(NSURL *)URL appletId:(NSString *)appletId {
    self = [super initWithFrame:frame];
    if (self) {
        _appletId = appletId;
        [self p_initSubViews:URL];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    self.webView.frame = self.bounds;

    CGFloat y = fabs(self.webView.scrollView.contentOffset.y);
    self.progressView.frame = CGRectMake(0, y, self.bounds.size.width, 4);
}

- (void)dealloc {
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
}

#pragma mark - private method

- (void)p_initSubViews:(NSURL *)URL {
    FATWeakScriptMessageDelegate *scriptMessageDelegate = [FATWeakScriptMessageDelegate new];
    scriptMessageDelegate.scriptDelegate = self;

    WKUserContentController *userContentController = [WKUserContentController new];
    NSString *souce = @"window.__fcjs_environment='miniprogram'";
    WKUserScript *script = [[WKUserScript alloc] initWithSource:souce injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:true];
    [userContentController addUserScript:script];
    [userContentController addScriptMessageHandler:scriptMessageDelegate name:@"webInvokeHandler"];
    [userContentController addScriptMessageHandler:scriptMessageDelegate name:@"webPublishHandler"];

    WKWebViewConfiguration *wkWebViewConfiguration = [WKWebViewConfiguration new];
    wkWebViewConfiguration.allowsInlineMediaPlayback = YES;
    wkWebViewConfiguration.userContentController = userContentController;

    self.webView = [[WKWebView alloc] initWithFrame:self.bounds configuration:wkWebViewConfiguration];
    self.webView.UIDelegate = self;
    self.webView.navigationDelegate = self;
    self.webView.clipsToBounds = YES;
    self.webView.scrollView.delegate = self;
    [self addSubview:self.webView];

    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:URL cachePolicy:NSURLRequestReloadRevalidatingCacheData timeoutInterval:60];
    [self.webView loadRequest:request];

    self.progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 4)];
    self.progressView.progressTintColor = [UIColor colorWithRed:44 / 255.0 green:127 / 255.0 blue:251 / 255.0 alpha:1];
    [self addSubview:self.progressView];

    [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];

    NSString *version = [FATClient sharedClient].version;
    NSString *appendUserAgent;
    NSString *model = [[UIDevice currentDevice] model];
    if ([FATExtUtil currentProductIdentificationIsEmpty]) {
        appendUserAgent = [NSString stringWithFormat:@"Provider/finogeeks (%@; miniprogram; FinChat; runtimeSdkVersion/%@)", model, version];
    } else {
        appendUserAgent = [NSString stringWithFormat:@"Provider/%@ (%@; miniprogram; %@; runtimeSdkVersion/%@)", [FATExtUtil currentProductIdentification], model, [FATExtUtil currentProductIdentification], version];
    }
    NSString *customUA = [FATClient sharedClient].uiConfig.appendingCustomUserAgent;
    if (customUA.length > 0) {
        appendUserAgent = [appendUserAgent stringByAppendingString:@" "];
        appendUserAgent = [appendUserAgent stringByAppendingString:customUA];
    }

    __weak typeof(self) weakSelf = self;
    [self.webView evaluateJavaScript:@"navigator.userAgent" completionHandler:^(id _Nullable result, NSError *_Nullable error) {
        NSString *userAgent = result;
        userAgent = [userAgent stringByAppendingFormat:@" %@", appendUserAgent];
        weakSelf.webView.customUserAgent = userAgent;
    }];
}

- (void)callJS:(NSString *)js callback:(void (^)(id result, NSError *error))callback {
    [self.webView evaluateJavaScript:js completionHandler:^(id _Nullable result, NSError *_Nullable error) {
        if (callback) {
            callback(result, error);
        }
    }];
}

- (void)webInvokeHandler:(NSDictionary *)data {
    if (!data) {
        return;
    }

    NSString *command = data[@"C"];
    NSString *paramsString = data[@"paramsString"];

    // 可能是字符串，也可能是number
    id callbackId = data[@"callbackId"];

    if (!command) {
        return;
    }

    if ([command isEqualToString:@"initPage"]) {
        unsigned long long webPageId = self.webView.hash;
        NSString *js = [NSString stringWithFormat:@"FinChatJSBridge.webInvokeCallbackHandler('%@',%@)", callbackId, @(webPageId)];
        [self callJS:js callback:nil];
        return;
    }

    // 执行注入的事件
    NSDictionary<NSString *, FATWebExtensionApiHandlerModel *> *webExtensionApis = [FATWebExtension webExtensionApis];
    id handler = (__bridge id)(webExtensionApis[command].isOld ? webExtensionApis[command].deprecatedHandler : webExtensionApis[command].handler);
    if (handler) {
        FATExtensionApiCallback callbck = ^void(FATExtensionCode code, NSDictionary<NSString *, NSObject *> *result) {
            NSString *successErrMsg = [NSString stringWithFormat:@"%@:ok", command];
            NSString *failErrMsg = [NSString stringWithFormat:@"%@:fail", command];
            NSString *cancelErrMsg = [NSString stringWithFormat:@"%@:cancel", command];

            NSString *errMsg = (NSString *)result[@"errMsg"];
            if (errMsg && [errMsg isKindOfClass:[NSString class]] && errMsg.length > 0) {
                successErrMsg = [successErrMsg stringByAppendingFormat:@" %@", errMsg];
                failErrMsg = [failErrMsg stringByAppendingFormat:@" %@", errMsg];
                cancelErrMsg = [cancelErrMsg stringByAppendingFormat:@" %@", errMsg];
            }

            switch (code) {
                case FATExtensionCodeSuccess: {
                    NSMutableDictionary *successResult = [NSMutableDictionary dictionaryWithDictionary:result];
                    [successResult setObject:successErrMsg forKey:@"errMsg"];
                    NSString *resultJsonString = [self fat_jsonStringFromDict:successResult];

                    NSString *js = [NSString stringWithFormat:@"FinChatJSBridge.webInvokeCallbackHandler('%@',%@)", callbackId, resultJsonString];
                    [self callJS:js callback:nil];
                    break;
                }
                case FATExtensionCodeCancel: {
                    NSMutableDictionary *cancelResult = [NSMutableDictionary dictionaryWithDictionary:result];
                    [cancelResult setObject:cancelErrMsg forKey:@"errMsg"];
                    NSString *resultJsonString = [self fat_jsonStringFromDict:cancelResult];

                    NSString *js = [NSString stringWithFormat:@"FinChatJSBridge.webInvokeCallbackHandler('%@',%@)", callbackId, resultJsonString];
                    [self callJS:js callback:nil];
                    break;
                }
                case FATExtensionCodeFailure: {
                    NSMutableDictionary *failResult = [NSMutableDictionary dictionaryWithDictionary:result];
                    [failResult setObject:failErrMsg forKey:@"errMsg"];
                    NSString *resultJsonString = [self fat_jsonStringFromDict:failResult];

                    NSString *js = [NSString stringWithFormat:@"FinChatJSBridge.webInvokeCallbackHandler('%@',%@)", callbackId, resultJsonString];
                    [self callJS:js callback:nil];
                    break;
                }
                default:
                    break;
            }
        };
        NSDictionary *param = [self fat_jsonObjectFromString:paramsString];
        if (webExtensionApis[command].isOld) {
            webExtensionApis[command].deprecatedHandler(param, callbck);
        } else {
            FATAppletInfo *appletInfo = [[FATClient sharedClient] getAppletInfo:self.appletId];
            webExtensionApis[command].handler(appletInfo, param, callbck);
        }
        return;
    }

    NSMutableDictionary *failResult = [NSMutableDictionary dictionary];
    NSString *failErrMsg = [NSString stringWithFormat:@"%@:fail 该api未实现", command];
    [failResult setObject:failErrMsg forKey:@"errMsg"];
    NSString *resultJsonString = [self fat_jsonStringFromDict:failResult];

    NSString *js = [NSString stringWithFormat:@"FinChatJSBridge.webInvokeCallbackHandler('%@',%@)", callbackId, resultJsonString];
    [self callJS:js callback:nil];
}

- (void)webPublishHandler:(NSDictionary *)data {
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey, id> *)change context:(void *)context {
    if ([keyPath isEqual:@"estimatedProgress"] && object == self.webView) {
        [self.progressView setAlpha:1.0f];
        [self.progressView setProgress:self.webView.estimatedProgress animated:YES];
        if (self.webView.estimatedProgress >= 1.0f) {
            [UIView animateWithDuration:0.3 delay:0.3 options:UIViewAnimationOptionCurveEaseOut animations:^{
                [self.progressView setAlpha:0.0f];
            } completion:^(BOOL finished) {
                [self.progressView setProgress:0.0f animated:YES];
            }];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

//MARK: - TOOL METHOD
- (NSString *)fat_jsonStringFromDict:(NSDictionary *)dict {
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];
    if (!data) {
        return nil;
    }

    NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return jsonString;
}

- (id)fat_jsonObjectFromString:(NSString *)string {
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];

    if (!data) {
        return nil;
    }

    id object = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    return object;
}

//MARK: - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSString *name = message.name;
    id body = message.body;

    if ([name isEqualToString:@"webInvokeHandler"]) {
        [self webInvokeHandler:body];
    } else if ([name isEqualToString:@"webPublishHandler"]) {
        [self webPublishHandler:body];
    }
}

//MARK: - WKNavigationDelegate
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    decisionHandler(WKNavigationActionPolicyAllow);
}

@end
