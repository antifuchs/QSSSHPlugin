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

- (NSImage *) iconForEntry:(NSDictionary *)dict{
    return [QSResourceManager imageNamed:@"com.apple.Terminal"];
}

- (NSString *)identifierForObject:(id <QSObject>)object{
    return [@"[SSH Host]:"stringByAppendingString:[object objectForType:QSURLType]];
}

- (void)setQuickIconForObject:(QSObject *)object{
    [object setIcon:[QSResourceManager imageNamed:@"com.apple.Terminal"]];
}

+ (QSObject *)newHostEntry:(NSString *)name {
	// NSLog(@"returning one object %@!\n", name);
	
	QSObject *obj = [QSObject objectWithName:[NSString stringWithString:name]];
	[obj setObject:[@"ssh://" stringByAppendingString:name] forType:QSURLType];
	[obj setPrimaryType:QSSSHHostIDType];
	
	return obj;
}
@end

@implementation QSSSHKnownHostsParser


- (NSArray *) objectsFromPath:(NSString *)path withSettings:(NSDictionary *)settings{
    NSMutableArray *objects=[NSMutableArray arrayWithCapacity:1];
    QSObject *newObject;
	

	NSString *contents = [NSString stringWithContentsOfFile:path];
	NSScanner *lineScanner = [NSScanner scannerWithString:contents];
	NSCharacterSet *newline = [NSCharacterSet characterSetWithCharactersInString:@"\n"];
	NSCharacterSet *hostnameSeparator = [NSCharacterSet characterSetWithCharactersInString:@"\t ,"];
	NSString *host, *ignored;
	
	while(![lineScanner isAtEnd]) {
		if ([lineScanner scanUpToCharactersFromSet:hostnameSeparator intoString:&host] &&
			[lineScanner scanUpToCharactersFromSet:newline intoString:&ignored]) {
			QSObject *newHostObject = [QSSSHPlugin newHostEntry:host];
			if (![objects containsObject:newHostObject])
				[objects addObject:newHostObject];
		} else {
			NSLog(@"huh? known_hosts entry didn't match? host: %@", host);
		}
	}
    
    return objects;
}

- (BOOL)isValidParserForPath:(NSString *)path{
	return TRUE;
}

@end

#define kQSSSHOpenAction @"QSSSHOpenAction"

@implementation QSSSHActionProvider

- (NSArray *)validActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject{
    return [NSArray arrayWithObject:kQSSSHPluginType];
}

- (QSObject *) openConnection:(QSObject *)dObject{
    
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[dObject objectForType:QSURLType]]];
    
    return nil;
}

@end