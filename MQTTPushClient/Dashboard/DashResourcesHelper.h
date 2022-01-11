/*
 * Copyright (c) 2022 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <Foundation/Foundation.h>
#import "Cmd.h"

@interface FileInfo : NSObject
@property NSString *name;
@property uint64_t mdate;
@end

@interface DashResourcesHelper : NSObject

@property NSURL *accountDir;

- (instancetype)initWithAccountDir:(NSURL *)dir;

/* load images from server for the given dash board (if no local copy exists) */
-(void) syncImages:(Cmd *)command dash:(NSString *)currentDash;

/* get all resources (images) stored on server */
-(NSMutableArray<FileInfo *> *)getServerResourceList:(RawCmd *)rawCmd;

/* save imported images on server */
-(void)saveImportedResources:(Cmd*)command serverResourceList:(NSMutableArray<FileInfo *> *)serverResourceList json:(NSMutableDictionary *)jsonObj;

/* call to delete imported resouce files after calling saveImportedResources and saving the dashboard on server */
-(void)deleteImportedResouces;

@end
