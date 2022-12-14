#import "MobileVnpayPlugin.h"
#import <CallAppSDK/CallAppInterface.h>
@interface MobileVnpayPlugin ()
@property(nonatomic, retain) FlutterMethodChannel *channel;
@property(nonatomic, copy) NSString *latestScheme;
@end

@implementation MobileVnpayPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"mobile_vnpay"
                                     binaryMessenger:[registrar messenger]];
    FlutterHlVnpayPlugin* instance = [[FlutterHlVnpayPlugin alloc] init];
    instance.channel = channel;
    [registrar addMethodCallDelegate:instance channel:channel];
    [registrar addApplicationDelegate:instance];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"show" isEqualToString:call.method]) {
        [self handleShow:call];
        result(nil);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)handleShow:(FlutterMethodCall*)call {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdkAction:)
                                                 name:@"SDK_COMPLETED" object:nil];
    [CallAppInterface setHomeViewController:[self viewControllerWithWindow:nil]];

    NSDictionary *value = [call arguments];
    bool isSandbox = value[@"isSandbox"];
    NSString *scheme = value[@"scheme"];
    NSString *backAlert = value[@"backAlert"];
    NSString *paymentUrl = value[@"paymentUrl"];
    NSString *title = value[@"title"];
    NSString *iconBackName = value[@"iconBackName"];
    NSString *beginColor = value[@"beginColor"];
    NSString *endColor = value[@"endColor"];
    NSString *titleColor = value[@"titleColor"];
    NSString *tmn_code = value[@"tmn_code"];

    self.latestScheme = scheme;

    [CallAppInterface setSchemes:scheme];
    [CallAppInterface setIsSandbox:isSandbox];
    [CallAppInterface setAppBackAlert:backAlert];
    [CallAppInterface showPushPaymentwithPaymentURL:paymentUrl
                                          withTitle:title
                                       iconBackName:iconBackName
                                         beginColor:beginColor
                                           endColor:endColor
                                         titleColor:titleColor
                                           tmn_code:tmn_code];
}

-(void)sdkAction:(NSNotification*)notification{
    if([notification.name isEqualToString:@"SDK_COMPLETED"]){
        [[NSNotificationCenter defaultCenter] removeObserver:self];

        NSString *actionValue=[notification.object valueForKey:@"Action"];
        if ([@"AppBackAction" isEqualToString:actionValue]) {
            //Ng?????i d??ng nh???n back t??? sdk ????? quay l???i
            [_channel invokeMethod:@"PaymentBack" arguments:@{@"resultCode":@-1}];
            return;
        }
        if ([@"CallMobileBankingApp" isEqualToString:actionValue]) {
        //Ng?????i d??ng nh???n ch???n thanh to??n qua app thanh to??n (Mobile Banking, V??...)
             [_channel invokeMethod:@"PaymentBack" arguments:@{@"resultCode":@10}];
             return;
        }
        if ([@"WebBackAction" isEqualToString:actionValue]) {
            //Ng?????i d??ng nh???n back t??? trang thanh to??n th??nh c??ng khi thanh to??n qua th??? khi g???i ?????n http://sdk.merchantbackapp
            [_channel invokeMethod:@"PaymentBack" arguments:@{@"resultCode":@24}];
            return;
        }
        if ([@"FaildBackAction" isEqualToString:actionValue]) {
             [_channel invokeMethod:@"PaymentBack" arguments:@{@"resultCode":@99}];
             return;
        }
        if ([@"FailBackAction" isEqualToString:actionValue]) {
            [_channel invokeMethod:@"PaymentBack" arguments:@{@"resultCode":@99}];
            return;
        }
        if ([@"SuccessBackAction" isEqualToString:actionValue]) {
            [_channel invokeMethod:@"PaymentBack" arguments:@{@"resultCode":@0}];
            return;
        }
    }
}

- (UIViewController *)viewControllerWithWindow:(UIWindow *)window {
    UIWindow *windowToUse = window;
    if (windowToUse == nil) {
        for (UIWindow *window in [UIApplication sharedApplication].windows) {
            if (window.isKeyWindow) {
                windowToUse = window;
                break;
            }
        }
    }

    UIViewController *topController = windowToUse.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    return topController;
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
    NSString *latestLink = [url absoluteString];
    NSString *scheme = [url scheme];
    NSString *host = [url host];
    if ([@"vnpay" isEqualToString:host] && [self.latestScheme isEqualToString:scheme]) {
        UIViewController *topController = [self viewControllerWithWindow:nil];
        UIWindow *windowToUse = nil;
        if (windowToUse == nil) {
            for (UIWindow *window in [UIApplication sharedApplication].windows) {
                if (window.isKeyWindow) {
                    windowToUse = window;
                    break;
                }
            }
        }

        if ([topController isKindOfClass:[FlutterViewController class]] == false) {
            [topController dismissViewControllerAnimated:YES completion:nil];
        }
    }
    return YES;
}
@end
