#ifndef AdjustSignerRuntimeBridge_h
#define AdjustSignerRuntimeBridge_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AdjustSignerRuntimeResult : NSObject

@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSString *> *outputParams;
@property (nonatomic, copy, nullable) NSString *errorMessage;

@end

/// 按 Adjust 官方 iOS SDK 的方式，通过 Objective-C 运行时调用 ADJSigner。
/// 这里不静态引用 ADJSigner 类符号，以兼容未导出 _OBJC_CLASS_$_ADJSigner 的签名库。
@interface AdjustSignerRuntimeBridge : NSObject

+ (nullable NSString *)version;

+ (AdjustSignerRuntimeResult *)signPackageParams:
        (NSDictionary<NSString *, NSString *> *)packageParams
    activityKind:(NSString *)activityKind
       clientSdk:(NSString *)clientSdk
        endpoint:(NSString *)endpoint;

@end

NS_ASSUME_NONNULL_END

#endif
