/*
 * Copyright (c) 2022 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

#import "Utils.h"
#import "DashUtils.h"
#import "DashConsts.h"
#import "NSString+HELUtils.h"
#import "NSDictionary+HelSafeAccessors.h"
#import "DashResourcesHelper.h"

@interface DashResourcesHelper()
@property NSMutableArray* trash;
@end

@implementation DashResourcesHelper

- (instancetype)initWithAccountDir:(NSURL *)dir {
	self = [super init];
	if (self) {
		self.accountDir = dir;
		self.trash = [NSMutableArray new];
	}
	return self;
}

-(void) syncImages:(Cmd *)command dash:(NSString *)currentDash {
	if (![Utils isEmpty:currentDash]) {
		NSData *jsonData = [currentDash dataUsingEncoding:NSUTF8StringEncoding];
		NSError *error;
		NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
		if (error) {
			NSLog(@"sync images, json parse error.");
		} else {
			NSArray *groups = [jsonDict objectForKey:@"groups"];
			NSArray *resources = [jsonDict objectForKey:@"resources"];
			
			NSMutableSet *resourceNames = [NSMutableSet new];
			NSString *uri;
			NSString *resourceName;
			NSString *internalFilename;
			NSURL *localDir = [DashUtils getUserFilesDir:self.accountDir];
			NSURL *fileURL;
			
			//TODO: remove the following 2 lines after test. Otherwise all images will be reloaded from server
			// [[NSFileManager defaultManager] removeItemAtURL:localDir error:nil];
			// localDir = [DashUtils getUserFilesDir:resourceDir];
			
			/* check if referenced resources exists */
			for(int i = 0; i < [resources count]; i++) {
				uri = [resources objectAtIndex:i];
				if ([DashUtils isUserResource:uri]) {
					resourceName = [DashUtils getURIPath:uri];
					internalFilename = [NSString stringWithFormat:@"%@.%@", [resourceName enquoteHelios], DASH512_PNG];
					fileURL = [DashUtils appendStringToURL:localDir str:internalFilename];
					if (![DashUtils fileExists:fileURL]) {
						// NSLog(@"internal filename not exists: %@", internalFilename);
						[resourceNames addObject:resourceName];
					}
				}
			}
			
			NSDictionary * group;
			NSArray *items;
			NSDictionary *item;
			for(int i = 0; i < [groups count]; i++) {
				group = [groups objectAtIndex:i];
				items = [group objectForKey:@"items"];
				for(int j = 0; j < [items count]; j++) {
					item = [items objectAtIndex:j];
					NSString *uris[3] = {@"uri", @"uri_off", @"background_uri"};
					for(int z = 0; z < 3; z++) {
						uri = [item objectForKey:uris[z]];
						if (uri) {
							if ([DashUtils isUserResource:uri]) {
								resourceName = [DashUtils getURIPath:uri];
								internalFilename = [NSString stringWithFormat:@"%@.%@", [resourceName enquoteHelios], DASH512_PNG];
								fileURL = [DashUtils appendStringToURL:localDir str:internalFilename];
								if (![DashUtils fileExists:fileURL]) {
									[resourceNames addObject:resourceName];
								}
							}
						}
					}
					NSArray *optionList = [item objectForKey:@"optionlist"];
					if (optionList) {
						NSDictionary * optionItem;
						for(int z = 0; z < [optionList count]; z++) {
							optionItem = [optionList objectAtIndex:z];
							if (optionItem) {
								uri = [optionItem objectForKey:@"uri"];
								if ([DashUtils isUserResource:uri]) {
									resourceName = [DashUtils getURIPath:uri];
									internalFilename = [NSString stringWithFormat:@"%@.%@", [resourceName enquoteHelios], DASH512_PNG];
									fileURL = [DashUtils appendStringToURL:localDir str:internalFilename];
									if (![DashUtils fileExists:fileURL]) {
										[resourceNames addObject:resourceName];
									}
								}
							}
						}
					}
				}
			}
			
			/* get all missing resources */
			NSEnumerator *enumerator = [resourceNames objectEnumerator];
			NSString *resName;
			unsigned char *p;
			uint64_t mdate;
			int len;
			
			while ((resName = [enumerator nextObject])) {
				NSLog(@"missing resource: %@", resName);
				[command getResourceRequest:0 name:resName type:DASH512_PNG];
				if (command.rawCmd.error) {
					break; /* critical error - do not try to get more resource files yet */
				}
				else if (command.rawCmd.rc != RC_OK) {
					continue; /* file not found - continue with loading next missing resource */
				}else {
					p = (unsigned char *)command.rawCmd.data.bytes;
					mdate = [Utils charArrayToUint64:p];
					p += 8;
					len = (int) (((uint64_t)p[0] << 24) + (p[1] << 16) + (p[2] << 8) + p[3]);
					p += 4;
					NSData* data = [NSData dataWithBytes:p length:len];
					
					internalFilename = [NSString stringWithFormat:@"%@.%@", [resName enquoteHelios], DASH512_PNG];
					fileURL = [DashUtils appendStringToURL:localDir str:internalFilename];
					if (![data writeToURL:fileURL atomically:YES]) {
						NSLog(@"Resource file %@ could not be written.", resName);
					} else {
						NSDate *modDate = [NSDate dateWithTimeIntervalSince1970:mdate];
						NSString *dateString = [NSDateFormatter localizedStringFromDate:modDate
																			  dateStyle:NSDateFormatterShortStyle
																			  timeStyle:NSDateFormatterFullStyle];
						NSLog(@"File %@: modification date %@",internalFilename, dateString);
						NSDictionary *attr = [NSDictionary dictionaryWithObjectsAndKeys: modDate, NSFileModificationDate, NULL];
						[[NSFileManager defaultManager] setAttributes:attr ofItemAtPath:[fileURL path] error:&error];
						if (error) {
							NSLog(@"Error: %@ %@", error, [error userInfo]); //TODO
						}
					}
				}
			}
		}
	}
}

-(NSMutableArray<FileInfo *> *)getServerResourceList:(RawCmd *)rawCmd {
	unsigned char *p = (unsigned char *)rawCmd.data.bytes;
	int noOfResources = (p[0] << 8) + p[1];
	p += 2;
	
	int count;
	NSMutableArray<FileInfo *> *serverResourceList = [NSMutableArray new];
	FileInfo *fileInfo;
	for(int i = 0; i < noOfResources; i++) {
		count = (p[0] << 8) + p[1];
		p += 2;
		fileInfo = [FileInfo new];
		fileInfo.name = [[NSString alloc] initWithBytes:p length:count encoding:NSUTF8StringEncoding];
		// NSLog(@"filename: %@", fileInfo.name);
		p += count;
		fileInfo.mdate = [Utils charArrayToUint64:p];
		p += 8;
		[serverResourceList addObject:fileInfo];
	}
	return serverResourceList;
}

-(void)saveImportedResources:(Cmd*)command serverResourceList:(NSMutableArray<FileInfo *> *)serverResourceList json:(NSMutableDictionary *)jsonObj {
	NSArray *groups = [jsonObj objectForKey:@"groups"];
	NSArray *resources = [jsonObj objectForKey:@"resources"];
	
	if (groups.count > 0) {
		NSMutableSet<NSString *> *serverResourceSet = [NSMutableSet new];
		for(FileInfo *fi in serverResourceList) {
			[serverResourceSet addObject:fi.name];
		}
		NSMutableSet<NSString *> *lockedResourcesSet = [NSMutableSet new];
		for(NSString *r in resources) {
			if (![Utils isEmpty:r]) {
				[lockedResourcesSet addObject:r];
			}
		}
		
		[jsonObj removeObjectForKey:@"resources"];
		
		NSURL *userDir = [DashUtils getUserFilesDir:self.accountDir];
		NSURL *importDir = [DashUtils getImportedFilesDir:self.accountDir];
		
		NSMutableDictionary<NSString *,NSString *> *replacedImportedResources = [NSMutableDictionary new];
		NSDictionary * group;
		NSArray *items;
		NSDictionary *item;
		NSArray *optionList;
		for(int i = 0; i < [groups count]; i++) {
			group = [groups objectAtIndex:i];
			items = [group objectForKey:@"items"];
			
			for(int j = 0; j < [items count]; j++) {
				item = [items objectAtIndex:j];
				[self saveResource:@"uri" jsonObj:item replacedRes:replacedImportedResources serverResources:serverResourceSet userDir:userDir importDir:importDir command:command];
				[self saveResource:@"uri_off" jsonObj:item replacedRes:replacedImportedResources serverResources:serverResourceSet userDir:userDir importDir:importDir command:command];
				[self saveResource:@"background_uri" jsonObj:item replacedRes:replacedImportedResources serverResources:serverResourceSet userDir:userDir importDir:importDir command:command];
				optionList = [item objectForKey:@"optionlist"];
				for(NSDictionary *optionItem in optionList) {
					[self saveResource:@"uri" jsonObj:optionItem replacedRes:replacedImportedResources serverResources:serverResourceSet userDir:userDir importDir:importDir command:command];
				}
			}
		}
		
		/* locked resources */
		NSMutableArray *lockedResources = [NSMutableArray new];
		for(NSString *uri in lockedResourcesSet) {
			if ([replacedImportedResources objectForKey:uri] != nil) {
				[lockedResources addObject:replacedImportedResources[uri]];
			} else if ([DashUtils isImportedResource:uri]) {
				NSString *finalResourceName = [self addImportedResource:uri userDir:userDir importDir:importDir command:command];
				NSString *tmp = [DashUtils buildResourceURI:@"user" resourceName:finalResourceName];
				[lockedResources addObject:tmp];
			} else if ([DashUtils isUserResource:uri]) {
				/* maybe user has chosen an image from another account (which are locally stored in same dir). if so, add to account resources */
				NSString *finalResourceName = [self addUserResource:uri userDir:userDir serverResources:serverResourceSet command:command];
				if (finalResourceName) {
					NSString *tmp = [DashUtils buildResourceURI:@"user" resourceName:finalResourceName];
					[lockedResources addObject:tmp];
				} else {
					[lockedResources addObject:uri];
				}
			}
		}
		[jsonObj setObject:lockedResources forKey:@"resources"];
	}
}

-(void)saveResource:(NSString *)objKey jsonObj:(NSDictionary *)jsonObj replacedRes:(NSMutableDictionary<NSString *,NSString *> *)replacedImportedResources serverResources:(NSSet<NSString *> *)serverResourceSet userDir:(NSURL *)userDir importDir:(NSURL *)importDir command:(Cmd*)command {
	
	NSString *uri = [jsonObj objectForKey:objKey];
	if (uri) {
		/* already done for this uri? */
		if ([replacedImportedResources objectForKey:uri] != nil) {
			[((NSMutableDictionary *) jsonObj) setObject:replacedImportedResources[uri] forKey:objKey];
		} else if ([DashUtils isImportedResource:uri]) {
			NSString *finalResourceName = [self addImportedResource:uri userDir:userDir importDir:importDir command:command];
			NSString *tmp = [DashUtils buildResourceURI:@"user" resourceName:finalResourceName];
			[((NSMutableDictionary *) jsonObj) setObject:tmp forKey:objKey];
			[replacedImportedResources setObject:uri forKey:tmp];
		} else if ([DashUtils isUserResource:uri]) {
			/* maybe user has chosen an image from another account (which are locally stored in same dir). if so, add to account resources */
			NSString *finalResourceName = [self addUserResource:uri userDir:userDir serverResources:serverResourceSet command:command];
			if (finalResourceName) {
				NSString *tmp = [DashUtils buildResourceURI:@"user" resourceName:finalResourceName];
				[((NSMutableDictionary *) jsonObj) setObject:tmp forKey:objKey];
				[replacedImportedResources setObject:uri forKey:tmp];
			}
		}
	}
}

-(NSString *)addUserResource:(NSString *)uri userDir:(NSURL *)userDir serverResources:(NSSet<NSString *> *)serverResourceSet command:(Cmd*)command {
	
	NSString *finalResourceName;
	NSString *cleanResourceName = [DashUtils getURIPath:uri];
	NSString *encodedFilename = [NSString stringWithFormat:@"%@.%@", [cleanResourceName enquoteHelios], DASH512_PNG];
	
	NSURL *userFile = [DashUtils appendStringToURL:userDir str:encodedFilename];
	NSFileManager *fm = [NSFileManager defaultManager];
	
	/* maybe user has chosen an image from another account (which are locally stored in same dir). if so, add to account resources */
	if ([fm fileExistsAtPath:userFile.path] && ![serverResourceSet containsObject:cleanResourceName]) {
		finalResourceName = [self addResource:cleanResourceName type:DASH512_PNG fileURL:userFile command:command];
		
		/* if resource name has changed, we must create a copy of the resource */
		if (![cleanResourceName isEqualToString:finalResourceName]) {
			encodedFilename = [NSString stringWithFormat:@"%@.%@", [finalResourceName enquoteHelios], DASH512_PNG];
			NSURL *targetFile = [DashUtils appendStringToURL:userDir str:encodedFilename];
			if (![fm copyItemAtURL:userFile toURL:targetFile error:nil]) {
				@throw [NSException exceptionWithName:@"IOException" reason:@"Copying file failed." userInfo:nil];
			}
		}
	}
	return finalResourceName;
}

-(NSString *)addImportedResource:(NSString *)uri userDir:(NSURL *)userDir importDir:(NSURL *)importDir command:(Cmd*)command {
	
	NSString *resourceName = [DashUtils getURIPath:uri];
	NSString *cleanFilename = [DashUtils removeImportedFilePrefix:resourceName];
	NSString *filename = [NSString stringWithFormat:@"%@.%@", [resourceName enquoteHelios], DASH512_PNG];
	
	NSURL *importedFile = [DashUtils appendStringToURL:importDir str:filename];
	
	NSString *finalResourceName = [self addResource:cleanFilename type:DASH512_PNG fileURL:importedFile command:command];
	
	/* copy imported file to user file dir */
	NSString *encodedFilename = [NSString stringWithFormat:@"%@.%@", [finalResourceName enquoteHelios], DASH512_PNG];
	NSURL *userFile = [DashUtils appendStringToURL:userDir str:encodedFilename];
	if (![[NSFileManager defaultManager] copyItemAtURL:importedFile toURL:userFile error:nil]) {
		@throw [NSException exceptionWithName:@"IOException" reason:@"Moving file failed." userInfo:nil];
	}
	
	[self.trash addObject:importedFile]; // delete later, save might fail
	
	return finalResourceName;
}

-(NSString *)addResource:(NSString *)filename type:(NSString *)type fileURL:(NSURL *)resourceFileURL command:(Cmd*)command {
	NSString *resoureName;
	[command addResource:0 filename:filename type:type fileURL:resourceFileURL];
	if (!command.rawCmd.error) {
		if (command.rawCmd.rc != RC_OK) {
			@throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Invalid args." userInfo:nil];
		}
		unsigned char *p = (unsigned char *)command.rawCmd.data.bytes;
		int count = (p[0] << 8) + p[1];
		p += 2;
		resoureName = [[NSString alloc] initWithBytes:p length:count encoding:NSUTF8StringEncoding];
	} else {
		NSError *error = command.rawCmd.error;
		NSMutableDictionary *userInfo = [NSMutableDictionary new];
		[userInfo setObject:error forKey:@"conn_error"];
		@throw [NSException exceptionWithName:@"IOException" reason:@"Save failed." userInfo:userInfo];
	}
	return resoureName;
}

-(void)deleteImportedResouces {
	NSFileManager *fm = [NSFileManager defaultManager];
	for(NSURL *f in self.trash) {
		[fm removeItemAtURL:f error:nil];
	}
}

-(NSArray<NSString *> *)findUnusedResources:(NSMutableArray<FileInfo *> *)serverResourceList json:(NSMutableDictionary *)jsonObj {
	
	NSMutableSet<NSString *> *unusedResources = [NSMutableSet new];
	for(FileInfo *fi in serverResourceList) {
		[unusedResources addObject:fi.name];
	}
	
	NSMutableSet<NSString *> *usedResources = [DashResourcesHelper getUsedResources:jsonObj];
	[unusedResources minusSet:usedResources];
	
	NSMutableArray* unusedResArr = [NSMutableArray new];
	for(NSString *uri in unusedResources) {
		[unusedResArr addObject:uri];
	}
	return unusedResArr;
}

+(void)deleteLocalImageResources:(AccountList *)accountList {
	NSURL *accountDir;
	for(int i = 0; i < accountList.count; i++) {
		accountDir = [accountList objectAtIndexedSubscript:i].cacheURL;
		if (accountDir) {
			/* delete all files in imported files dir */
			[DashUtils clearImportedFilesDir:accountDir];
			
			/* read dashboard */
			NSURL *fileURL = [DashUtils appendStringToURL:accountDir str:@"dashboard.json"];
			NSString *dashboardStr = [NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:nil];
			if (dashboardStr) {
				NSRange r = [dashboardStr rangeOfString:@"\n"];
				if (r.location != NSNotFound) {
					NSString * dashboardJS = [dashboardStr substringFromIndex:r.location + 1];
					if (dashboardJS) {
						NSData *jsonData = [dashboardJS dataUsingEncoding:NSUTF8StringEncoding];
						NSDictionary *jsonObj = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
						if (jsonObj) {
							NSMutableSet<NSString *> *usedResources = [DashResourcesHelper getUsedResources:jsonObj];
							
							NSURL *userDir = [DashUtils getUserFilesDir:accountDir];
							NSFileManager *fm = [NSFileManager defaultManager];
							NSArray<NSURL *> * urls = [fm contentsOfDirectoryAtURL:userDir includingPropertiesForKeys:nil options:0 error:nil];
							NSString *filename, *resourceName;
							NSString *fileExt = [NSString stringWithFormat:@".%@",DASH512_PNG];
							for(NSURL *u in urls) {
								filename = u.lastPathComponent;
								if ([filename hasSuffix:fileExt]) {
									resourceName = [[filename substringToIndex:filename.length - fileExt.length] dequoteHelios];
									if (![usedResources containsObject:resourceName]) {
										/* resource is not referenced so delete */
										if ([[accountList objectAtIndexedSubscript:i].mqttUser hasPrefix:@"alu"]) {
											[fm removeItemAtURL:u error:nil];
											// NSLog(@"%@", u.lastPathComponent);
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
}

/* returns all used resource names (referenced, locked) of given dashboard */
+(NSMutableSet<NSString *> *)getUsedResources:(NSDictionary *)jsonObj {
	NSMutableSet<NSString *> *usedResources = [NSMutableSet new];
	
	NSArray *groups = jsonObj[@"groups"];
	NSDictionary *item;
	NSArray *items, *optionList;
	NSString *resourceName, *uri;
	
	for(NSDictionary *group in groups) {
		items = group[@"items"];
		
		for(int j = 0; j < [items count]; j++) {
			item = [items objectAtIndex:j];
			
			uri = item[@"uri"];
			if ([DashUtils isUserResource:uri]) {
				resourceName = [DashUtils getURIPath:uri];
				[usedResources addObject:resourceName];
			}
			
			uri = item[@"uri_off"];
			if ([DashUtils isUserResource:uri]) {
				resourceName = [DashUtils getURIPath:uri];
				[usedResources addObject:resourceName];
			}
			
			uri = item[@"background_uri"];
			if ([DashUtils isUserResource:uri]) {
				resourceName = [DashUtils getURIPath:uri];
				[usedResources addObject:resourceName];
			}
			
			optionList = item[@"optionlist"];
			for(NSDictionary *optionItem in optionList) {
				uri = optionItem[@"uri"];
				if ([DashUtils isUserResource:uri]) {
					resourceName = [DashUtils getURIPath:uri];
					[usedResources addObject:resourceName];
				}
			}
		}
	}
	NSArray *resources = [jsonObj objectForKey:@"resources"];
	for(NSString * uri in resources) {
		if ([DashUtils isUserResource:uri]) {
			resourceName = [DashUtils getURIPath:uri];
			[usedResources addObject:resourceName];
		}
	}
	return usedResources;
}

@end

@implementation FileInfo
@end
