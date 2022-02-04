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

@interface Resource : NSObject
-(instancetype)initWithName:(NSString *)name type:(NSString*)type;
@property NSString *name;
@property NSString *type;
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

-(int) syncResources:(Cmd *)command dash:(NSString *)currentDash {
	int rc = 0;
	if (![Utils isEmpty:currentDash]) {
		NSData *jsonData = [currentDash dataUsingEncoding:NSUTF8StringEncoding];
		NSError *error;
		NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
		if (error) {
			NSLog(@"sync images, json parse error.");
		} else {
			NSArray *groups = [jsonDict objectForKey:@"groups"];
			NSArray *resources = [jsonDict objectForKey:@"resources"];
			
			NSMutableSet<Resource *> *resourceNames = [NSMutableSet new];
			NSString *uri;
			NSString *resourceName;
			NSString *internalFilename;
			NSURL *localDir = [DashUtils getUserFilesDir:self.accountDir];
			NSURL *fileURL;
			
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
						[resourceNames addObject:[[Resource alloc] initWithName:resourceName type:DASH512_PNG]];
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
					NSString *uris[4] = {@"uri", @"uri_off", @"background_uri", @"htmlUri"};
					for(int z = 0; z < 4; z++) {
						uri = [item objectForKey:uris[z]];
						if (uri) {
							if ([DashUtils isUserResource:uri] || [DashUtils isHTMLResource:uri]) {
								resourceName = [DashUtils getURIPath:uri];
								internalFilename = [NSString stringWithFormat:@"%@.%@", [resourceName enquoteHelios], ([DashUtils isUserResource:uri] ? DASH512_PNG : DASH_HTML)];
								fileURL = [DashUtils appendStringToURL:localDir str:internalFilename];
								if (![DashUtils fileExists:fileURL]) {
									[resourceNames addObject:[[Resource alloc] initWithName:resourceName type:([DashUtils isUserResource:uri] ? DASH512_PNG : DASH_HTML)]];
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
										[resourceNames addObject:[[Resource alloc] initWithName:resourceName type:DASH512_PNG]];
									}
								}
							}
						}
					}
				}
			}
			
			/* get all missing resources */
			NSEnumerator<Resource *> *enumerator = [resourceNames objectEnumerator];
			Resource *resName;
			unsigned char *p;
			uint64_t mdate;
			int len;
			
			while ((resName = [enumerator nextObject])) {
				NSLog(@"missing resource: %@", resName);
				[command getResourceRequest:0 name:resName.name type:resName.type];
				if (command.rawCmd.error) {
					break;
				} else if (command.rawCmd.rc != RC_OK) {
					NSLog(@"getResource request failed for resource %@. Error: Resource not found.", resName);
					continue;
				} else {
					p = (unsigned char *)command.rawCmd.data.bytes;
					mdate = [Utils charArrayToUint64:p];
					p += 8;
					len = (int) (((uint64_t)p[0] << 24) + (p[1] << 16) + (p[2] << 8) + p[3]);
					p += 4;
					NSData* data = [NSData dataWithBytes:p length:len];
					
					internalFilename = [NSString stringWithFormat:@"%@.%@", [resName.name enquoteHelios], resName.type];
					fileURL = [DashUtils appendStringToURL:localDir str:internalFilename];
					if (![data writeToURL:fileURL atomically:YES]) {
						NSLog(@"Resource file %@ could not be written.", resName);
					} else {
						if ([resName.type isEqual:DASH512_PNG]) {
							rc = rc | 1;
						} else if ([resName.type isEqual:DASH_HTML]) {
							rc = rc | 2;
						}
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
	return rc;
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

-(void)saveHTMLResources:(Cmd*)command  json:(NSMutableDictionary *)jsonObj {
	NSMutableArray *groups = [[jsonObj objectForKey:@"groups"] mutableCopy];
	[jsonObj setObject:groups forKey:@"groups"];
	
	if (groups.count > 0) {
		NSURL *userDir = [DashUtils getUserFilesDir:self.accountDir];
		NSURL *fileURL;

		NSMutableDictionary * group;
		NSMutableArray *items;
		NSMutableDictionary *item;
		NSString *type, *html, *htmlUri, *resourceName, *newResourceName, *filename;
		unichar f[8];
		for(int i = 0; i < [groups count]; i++) {
			group = [[groups objectAtIndex:i] mutableCopy];
			[groups setObject:group atIndexedSubscript:i];
			items = [[group objectForKey:@"items"] mutableCopy];
			[group setObject:items forKey:@"items"];
		
			for(int j = 0; j < [items count]; j++) {
				item = [[items objectAtIndex:j] mutableCopy];
				[items setObject:item atIndexedSubscript:j];
				type = [item helStringForKey:@"type"];
				if ([@"custom" isEqual:type]) {
					html = [item helStringForKey:@"html"];
					htmlUri = [item helStringForKey:@"htmlUri"];
					if (![Utils isEmpty:html]) {
						/* html content must be saved to file */
						do {
							for(int k = 0; k < 8; k++) {
								f[k] = 97 + arc4random_uniform(26);
							}
							resourceName = [NSString stringWithCharacters:f length:8];
							filename = [NSString stringWithFormat:@"%@.%@",resourceName, DASH_HTML];
							fileURL = [DashUtils appendStringToURL:userDir str:filename];
						} while([DashUtils fileExists:fileURL]);
						if ([html writeToURL:fileURL atomically:YES encoding:NSUTF8StringEncoding error:nil]) {
							newResourceName = [self addResource:resourceName type:DASH_HTML fileURL:fileURL command:command];
							if (![resourceName isEqual:newResourceName]) {
								filename = [NSString stringWithFormat:@"%@.%@",newResourceName, DASH_HTML];
								NSURL *newFileURL = [DashUtils appendStringToURL:userDir str:filename];
								[[NSFileManager defaultManager] moveItemAtPath:fileURL.path toPath:newFileURL.path error:nil];
							}
							html = @"";
							htmlUri = [NSString stringWithFormat:@"res://html/%@", newResourceName];
							[item setObject:html forKey:@"html"];
							[item setObject:htmlUri forKey:@"htmlUri"];
						} else {
							@throw [NSException exceptionWithName:@"IOException" reason:@"Save failed." userInfo:nil];
						}
					} else if ([DashUtils isHTMLResource:htmlUri]) {
						;
					}
				}
			}
		}
	}
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

-(NSArray<NSString *> *)findUnusedResources:(NSMutableArray<FileInfo *> *)serverResourceList type:(NSString *)type json:(NSMutableDictionary *)jsonObj {
	
	NSMutableSet<NSString *> *unusedResources = [NSMutableSet new];
	for(FileInfo *fi in serverResourceList) {
		[unusedResources addObject:fi.name];
	}
	
	NSMutableSet<NSString *> *usedResources =  [NSMutableSet new];
	NSSet<Resource *> *res = [DashResourcesHelper getUsedResources:jsonObj];
	for(Resource *r in res) {
		if ([type isEqual:r.type]) {
			[usedResources addObject:r.name];
		}
	}
	[unusedResources minusSet:usedResources];
	
	NSMutableArray* unusedResArr = [NSMutableArray new];
	for(NSString *r in unusedResources) {
		[unusedResArr addObject:r];
	}
	return unusedResArr;
}

+(void)deleteLocalResources:(AccountList *)accountList {
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
							NSMutableSet<Resource *> *usedResources = [DashResourcesHelper getUsedResources:jsonObj];
							
							NSURL *userDir = [DashUtils getUserFilesDir:accountDir];
							NSFileManager *fm = [NSFileManager defaultManager];
							NSArray<NSURL *> * urls = [fm contentsOfDirectoryAtURL:userDir includingPropertiesForKeys:nil options:0 error:nil];
							NSString *filename, *resourceName;
							NSString *fileExtImg = [NSString stringWithFormat:@".%@",DASH512_PNG];
							NSString *fileExtHtml = [NSString stringWithFormat:@".%@",DASH_HTML];
							Resource *resource;
							for(NSURL *u in urls) {
								filename = u.lastPathComponent;
								if ([filename hasSuffix:fileExtImg] || [filename hasSuffix:fileExtHtml]) {
									resourceName = [[filename substringToIndex:filename.length - ([filename hasSuffix:fileExtImg] ? fileExtImg.length : fileExtHtml.length)] dequoteHelios];
									resource = [[Resource alloc] initWithName:resourceName type:([filename hasSuffix:fileExtImg] ? DASH512_PNG : DASH_HTML)];
									
									if (![usedResources containsObject:resource]) {
										/* resource is not referenced so delete */
										[fm removeItemAtURL:u error:nil];
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
+(NSMutableSet<Resource *> *)getUsedResources:(NSDictionary *)jsonObj {
	NSMutableSet<Resource *> *usedResources = [NSMutableSet new];
	
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
				[usedResources addObject:[[Resource alloc] initWithName:resourceName type:DASH512_PNG]];
				;
			}
			
			uri = item[@"uri_off"];
			if ([DashUtils isUserResource:uri]) {
				resourceName = [DashUtils getURIPath:uri];
				[usedResources addObject:[[Resource alloc] initWithName:resourceName type:DASH512_PNG]];
			}
			
			uri = item[@"background_uri"];
			if ([DashUtils isUserResource:uri]) {
				resourceName = [DashUtils getURIPath:uri];
				[usedResources addObject:[[Resource alloc] initWithName:resourceName type:DASH512_PNG]];
			}

			uri = item[@"htmlUri"];
			if ([DashUtils isHTMLResource:uri]) {
				resourceName = [DashUtils getURIPath:uri];
				[usedResources addObject:[[Resource alloc] initWithName:resourceName type:DASH_HTML]];
			}

			optionList = item[@"optionlist"];
			for(NSDictionary *optionItem in optionList) {
				uri = optionItem[@"uri"];
				if ([DashUtils isUserResource:uri]) {
					resourceName = [DashUtils getURIPath:uri];
					[usedResources addObject:[[Resource alloc] initWithName:resourceName type:DASH512_PNG]];
				}
			}
		}
	}
	NSArray *resources = [jsonObj objectForKey:@"resources"];
	for(NSString * uri in resources) {
		if ([DashUtils isUserResource:uri]) {
			resourceName = [DashUtils getURIPath:uri];
			[usedResources addObject:[[Resource alloc] initWithName:resourceName type:DASH512_PNG]];
		}
	}
	return usedResources;
}

@end

@implementation FileInfo
@end

@implementation Resource

-(instancetype)initWithName:(NSString *)name type:(NSString*)type {
	if (self = [super init]) {
		self.name = name;
		self.type = type;
	}
	return self;
}

- (BOOL)isEqual:(id)other
{
	if (other == self) {
		return YES;
	} else if (other == nil || ![other isKindOfClass:[Resource class]]) {
		return NO;
	} else {
		Resource *o = (Resource *) other;
		return [self.name isEqual:o.name] && [self.type isEqual:o.type];
	}
}

- (NSUInteger)hash
{
	NSUInteger p = 31;
	NSUInteger result = 1;
	result = result * p + [self.name hash];
	result = result * p + [self.type hash];
	return result;
}

@end
