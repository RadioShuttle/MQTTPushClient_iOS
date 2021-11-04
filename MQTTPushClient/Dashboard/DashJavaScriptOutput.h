/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <JavaScriptCore/JavaScriptCore.h>

#import <Foundation/Foundation.h>
#import "ViewParameter.h"


@interface DashJavaScriptOutput : NSObject
@property JSContext *context;

- (nonnull instancetype)initWithScript:(nonnull NSString *)outputScript;

- (nullable NSDictionary *)formatOutput:(nullable NSString *)input msg:(nonnull NSDictionary *)msg acc:(nonnull NSDictionary *)acc
				   viewParameter:(nullable ViewParameter *)viewParameter
						   error:(NSError * _Nullable *_Nullable)error;

@end
