/*
 * This is an unpublished work copyright (c) 2011 HELIOS Software GmbH
 * 30827 Garbsen, Germany
 */

@import Foundation;

@interface NSString (HELUtils)

@property (nonatomic, readonly, copy) NSString *toHex;
@property (nonatomic, readonly, copy) NSString *fromHex;
@property (nonatomic, readonly, copy) NSData *dataFromHex;
+ (NSString *)hexFromData:(NSData *)sdata;

@property (nonatomic, readonly, copy) NSString *dequoteHelios;
@property (nonatomic, readonly, copy) NSString *enquoteHelios;

@property (nonatomic, readonly, copy) NSString *xmlEscape;
@property (nonatomic, readonly, copy) NSString *urlEscape;

@property (nonatomic, readonly, copy) NSString *helNormalizePath;

@end
