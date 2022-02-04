/*
 * Copyright (c) 2022 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import <Foundation/Foundation.h>
#import "Cmd.h"
#import "AccountList.h"

@interface FileInfo : NSObject
@property NSString *name;
@property uint64_t mdate;
@end

@interface DashResourcesHelper : NSObject

@property NSURL *accountDir;

- (instancetype)initWithAccountDir:(NSURL *)dir;

/* load images from server for the given dash board (if no local copy exists) */
-(int) syncResources:(Cmd *)command dash:(NSString *)currentDash;

/* get all resource names (images) stored on server */
-(NSMutableArray<FileInfo *> *)getServerResourceList:(RawCmd *)rawCmd;

/* save imported images on server */
-(void)saveImportedResources:(Cmd*)command serverResourceList:(NSMutableArray<FileInfo *> *)serverResourceList json:(NSMutableDictionary *)jsonObj;
-(void)saveHTMLResources:(Cmd*)command  json:(NSMutableDictionary *)jsonObj;

/* call to delete imported resouce files after calling saveImportedResources and saving the dashboard on server */
-(void)deleteImportedResouces;

/* check resources for the given account, which are stored on server, but not referenced (anymore) */
-(NSArray<NSString *> *)findUnusedResources:(NSMutableArray<FileInfo *> *)serverResourceList type:(NSString *)type json:(NSMutableDictionary *)jsonObj;

/* remove all local unused imported and downloaded images for all accounts */
+(void)deleteLocalResources:(AccountList *)accountList;

@end
