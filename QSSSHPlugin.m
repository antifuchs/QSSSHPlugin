//
//  QSSSHPlugin.m
//  QSSSHPlugin
//
//  Created by Andreas Fuchs on 11/2/06.
//  Copyright Andreas Fuchs 2006. All rights reserved.
//

#import "QSSSHPlugin.h"
#import <Foundation/NSScanner.h>

#define QSSSHHostIDType @"QSSSHHostIDType"

@implementation QSSSHPlugin

- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry{
    NSDate *modDate=[[[NSFileManager defaultManager] fileAttributesAtPath:[@"~/.ssh/known_hosts" stringByStandardizingPath] traverseLink:YES]fileModificationDate];
    return [modDate compare:indexDate]==NSOrderedAscending;
}

+ (QSObject *)newHostEntry:(NSString *)name {
	QSObject *obj = [QSObject objectWithName:[NSString stringWithString:name]];
	[obj setObject:name forType:QSSSHHostIDType];
	[obj setPrimaryType:QSSSHHostIDType];
	
	return obj;
}
@end

@implementation QSSSHKnownHostsParser


- (NSArray *) objectsFromPath:(NSString *)path withSettings:(NSDictionary *)settings{
    NSMutableArray *objects=[NSMutableArray arrayWithCapacity:1];
    QSObject *newObject;
	int line=0;
	

	NSError *error=nil;
	NSString *contents = [NSString stringWithContentsOfFile:path encoding:NSISOLatin1StringEncoding error:&error];
	if (error != nil) {
		NSLog (@"Couldn't read contents of %@: %@\n", path, error);
		return objects;
	}
	NSScanner *lineScanner = [NSScanner scannerWithString:contents];
	NSCharacterSet *newline = [NSCharacterSet characterSetWithCharactersInString:@"\n"];
	NSCharacterSet *hostnameSeparator = [NSCharacterSet characterSetWithCharactersInString:@"\t ,"];
	NSString *host=nil, *ignored=nil;
	
	while(![lineScanner isAtEnd]) {
		if ([lineScanner scanUpToCharactersFromSet:hostnameSeparator intoString:&host] &&
			[lineScanner scanUpToCharactersFromSet:newline intoString:&ignored]) {
			QSObject *newHostObject = [QSSSHPlugin newHostEntry:host];
			if (![objects containsObject:newHostObject])
				[objects addObject:newHostObject];
			line++;
		} else {
			NSLog(@"huh? known_hosts entry didn't match? line: %d; ignoring line...", line);
			[lineScanner scanUpToCharactersFromSet:newline intoString:&ignored];
			line++;
		}
	}
    
    return objects;
}

- (BOOL)isValidParserForPath:(NSString *)path{
	return TRUE;
}

@end

@implementation QSSSHConfigParser

- (NSArray *) objectsFromPath:(NSString *)path withSettings:(NSDictionary *)settings{
    NSMutableArray *objects=[NSMutableArray arrayWithCapacity:0];
    QSObject *newObject;
	
	NSError *error=nil;
	NSString *contents = [NSString stringWithContentsOfFile:path encoding:NSISOLatin1StringEncoding error:&error];
	if (error != nil) {
		NSLog (@"Couldn't read contents of %@: %@\n", path, error);
		return objects;
	}
	NSScanner *lineScanner = [NSScanner scannerWithString:contents];
	NSCharacterSet *newline = [NSCharacterSet characterSetWithCharactersInString:@"\n"];
	NSCharacterSet *hostnameSeparator = [NSCharacterSet characterSetWithCharactersInString:@"\t ,"];
	NSCharacterSet *wildcards = [NSCharacterSet characterSetWithCharactersInString:@"*?"];
	NSString *firstWord=nil, *host=nil, *ignored=nil;
	
	while(![lineScanner isAtEnd]) {
		if ([lineScanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:&firstWord] &&
			[firstWord compare:@"Host"] == NSOrderedSame &&
			[lineScanner scanUpToCharactersFromSet:newline intoString:&host]) {
			/* ssh config entries can be general configuration entries (using wildcards) or host alias 
			   entries with optional customization. We want the latter. */
			if ([host rangeOfCharacterFromSet:wildcards].location == NSNotFound) {
				QSObject *newHostObject = [QSSSHPlugin newHostEntry:host];
				if (![objects containsObject:newHostObject]) {
					[objects addObject:newHostObject];
				}
			}
		} else {
			// ignore the line
			[lineScanner scanUpToCharactersFromSet:newline intoString:&ignored];
		}
	}
    
    return objects;
}

- (BOOL)isValidParserForPath:(NSString *)path{
	return TRUE;
}

@end


#define kQSSSHOpenAction @"QSSSHOpenAction"
#define kQSSSHOpenAsUserAction @"QSSSHOpenAsUserAction"

@implementation QSSSHActionProvider

- (NSArray *)validActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject{
    return [NSArray arrayWithObjects:kQSSSHOpenAction, kQSSSHOpenAsUserAction, nil];
}

- (NSArray *)validIndirectObjectsForAction:(NSString *)action directObject:(QSObject *)dObject{
	return [NSArray arrayWithObject:[QSObject textProxyObjectWithDefaultValue:@""]];
}

- (QSObject *) openConnection:(QSObject *)dObject{
	NSString *hostStr = [dObject objectForType:QSSSHHostIDType];
	if (hostStr == NULL)
		hostStr = [dObject objectForType:NSStringPboardType];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"ssh://%@/", hostStr]];
	
    if (NO == [[NSWorkspace sharedWorkspace] openURL:url])
		NSLog(@"opening URL %@ failed!", url);
    return nil;
}

- (QSObject *) openConnection:(QSObject *)dObject asUser:(QSObject*)iObject{
	NSString *hostStr = [dObject objectForType:QSSSHHostIDType];
	if (hostStr == NULL)
		hostStr = [dObject objectForType:NSStringPboardType];
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"ssh://%@@%@/", iObject, hostStr]];
	
    if (NO == [[NSWorkspace sharedWorkspace] openURL:url])
		NSLog(@"opening URL %@ failed!", url);
	return nil;
}

- (NSImage *) iconForEntry:(NSDictionary *)dict{
    return [QSResourceManager imageNamed:@"com.apple.Terminal"];
}

- (NSString *)identifierForObject:(id <QSObject>)object{
    return [@"[SSH Host]:"stringByAppendingString:[object objectForType:QSSSHHostIDType]];
}

- (void)setQuickIconForObject:(QSObject *)object{
    [object setIcon:[QSResourceManager imageNamed:@"com.apple.Terminal"]];
}

@end