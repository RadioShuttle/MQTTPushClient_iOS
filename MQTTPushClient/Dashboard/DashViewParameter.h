/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "ViewParameter.h"
#import "DashItem.h"
#import "Account.h"
#import <JavaScriptCore/JavaScriptCore.h>

@interface DashViewParameter : ViewParameter

-(instancetype)initWithItem:(DashItem *)item context:(JSContext *)context account:(Account *)account;
+(instancetype)viewParameterWithItem:(DashItem *)item context:(JSContext *)context account:(Account *)account;

@property DashItem *dashItem;
@property JSContext *jsContext;
@property Account *account;

@end

@interface DashTextItemViewParameter : DashViewParameter
@end

@interface DashSwitchItemViewParameter : DashViewParameter
@end

@interface DashSliderItemViewParameter : DashViewParameter
@end

@interface DashOptionItemViewParameter : DashViewParameter
@end

