#import "AdjustSignerRuntimeBridge.h"

@implementation AdjustSignerRuntimeResult
@end

@implementation AdjustSignerRuntimeBridge

+ (nullable Class)signerClass {
    return NSClassFromString(@"ADJSigner");
}

+ (nullable NSString *)version {
    Class signerClass = [self signerClass];
    SEL selector = NSSelectorFromString(@"getVersion");
    if (signerClass == nil || ![signerClass respondsToSelector:selector]) {
        return nil;
    }

    IMP implementation = [signerClass methodForSelector:selector];
    NSString *(*function)(id, SEL) = (void *)implementation;
    return function(signerClass, selector);
}

+ (AdjustSignerRuntimeResult *)signPackageParams:
        (NSDictionary<NSString *, NSString *> *)packageParams
    activityKind:(NSString *)activityKind
       clientSdk:(NSString *)clientSdk
        endpoint:(NSString *)endpoint {
    AdjustSignerRuntimeResult *result = [[AdjustSignerRuntimeResult alloc] init];
    Class signerClass = [self signerClass];
    if (signerClass == nil) {
        result.errorMessage = @"运行时未找到 ADJSigner，请检查 AdjustSigSdk.framework 是否已加载";
        return result;
    }

    SEL selector = NSSelectorFromString(@"sign:withExtraParams:withOutputParams:");
    if (![signerClass respondsToSelector:selector]) {
        result.errorMessage = @"ADJSigner 不支持 sign:withExtraParams:withOutputParams:";
        return result;
    }

    NSMutableDictionary<NSString *, NSString *> *extraParams = [NSMutableDictionary dictionary];
    extraParams[@"activity_kind"] = activityKind;
    extraParams[@"client_sdk"] = clientSdk;
    extraParams[@"endpoint"] = endpoint;

    NSMutableDictionary<NSString *, NSString *> *outputParams = [NSMutableDictionary dictionary];
    NSMethodSignature *methodSignature = [signerClass methodSignatureForSelector:selector];
    if (methodSignature == nil) {
        result.errorMessage = @"无法读取 ADJSigner 签名方法定义";
        return result;
    }

    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    [invocation setSelector:selector];
    [invocation setTarget:signerClass];

    NSDictionary<NSString *, NSString *> *packageArgument = packageParams;
    NSDictionary<NSString *, NSString *> *extraArgument = extraParams;
    NSMutableDictionary<NSString *, NSString *> *outputArgument = outputParams;
    [invocation setArgument:&packageArgument atIndex:2];
    [invocation setArgument:&extraArgument atIndex:3];
    [invocation setArgument:&outputArgument atIndex:4];
    [invocation invoke];

    result.outputParams = [outputParams copy];
    return result;
}

@end
