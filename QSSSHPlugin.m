//
//  QSSSHPlugin.m
//  QSSSHPlugin
//
//  Created by Andreas Fuchs on 11/2/06.
//  Copyright Andreas Fuchs 2006. All rights reserved.
//

#import "QSSSHPlugin.h"

#define QSSSHHostIDType @"QSSSHHostIDType"

@implementation QSSSHPlugin

- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry{
    NSDate *modDate=[[[NSFileManager defaultManager] fileAttributesAtPath:[@"~/.ssh/config" stringByStandardizingPath] traverseLink:YES]fileModificationDate];
    return [modDate compare:indexDate]==NSOrderedAscending;
}

- (NSImage *) iconForEntry:(NSDictionary *)dict{
    return [QSResourceManager imageNamed:@"com.apple.Terminal"];
}

- (NSString *)identifierForObject:(id <QSObject>)object{
    return [@"[SSH Host]:"stringByAppendingString:[object objectForType:QSSSHHostIDType]];
}

- (NSArray *) objectsForEntry:(NSDictionary *)theEntry{
    NSMutableArray *objects=[NSMutableArray arrayWithCapacity:1];
    QSObject *newObject;

    newObject=[QSObject objectWithName:@"boojum.boinkor.net"];

    [newObject setObject:@"ssh://boojum.boinkor.net/" forType:QSURLType];
	[newObject setPrimaryType:QSSSHHostIDType];
    [objects addObject:newObject];
    
	NSLog(@"returning one object!\n"); 
	
    return objects;
}

- (BOOL)loadChildrenForObject:(QSObject *)object{
		[object setChildren:[self objectsForEntry:nil]];
		return YES;   	
}

- (void)setQuickIconForObject:(QSObject *)object{
    [object setIcon:[QSResourceManager imageNamed:@"com.apple.Terminal"]];
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