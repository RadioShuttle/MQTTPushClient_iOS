/*
 * Copyright (c) 2021 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "Message.h"

@interface DashMessage : Message
@property int status;
-(instancetype)initWithJSON:(NSDictionary *) dict;

-(NSDictionary *)toJSON;

-(NSString *)contentToHex;
-(NSString *)contentToStr;

@end
