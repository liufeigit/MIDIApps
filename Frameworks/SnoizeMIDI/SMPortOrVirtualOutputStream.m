//
// Copyright 2001-2002 Kurt Revis. All rights reserved.
//

#import "SMPortOrVirtualOutputStream.h"

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>

#import "SMEndpoint.h"
#import "SMPortOutputStream.h"
#import "SMVirtualOutputStream.h"


@interface SMPortOrVirtualOutputStream (Private)

- (void)repostNotification:(NSNotification *)notification;

@end


@implementation SMPortOrVirtualOutputStream

- (id)init;
{
    if (!(self = [super init]))
        return nil;

    flags.ignoresTimeStamps = NO;
    flags.sendsSysExAsynchronously = NO;

    return self;
}

- (BOOL)ignoresTimeStamps;
{
    return flags.ignoresTimeStamps;
}

- (void)setIgnoresTimeStamps:(BOOL)value;
{
    flags.ignoresTimeStamps = value;
    [[self stream] setIgnoresTimeStamps:value];
}

- (BOOL)sendsSysExAsynchronously;
{
    return flags.sendsSysExAsynchronously;
}

- (void)setSendsSysExAsynchronously:(BOOL)value;
{
    flags.sendsSysExAsynchronously = value;
    if ([[self stream] respondsToSelector:@selector(setSendsSysExAsynchronously:)])
        [[self stream] setSendsSysExAsynchronously:value];    
}

- (BOOL)canSendSysExAsynchronously;
{
    return ([self stream] == portStream);
}

- (void)cancelPendingSysExSendRequests;
{
    if ([[self stream] respondsToSelector:@selector(cancelPendingSysExSendRequests)])
        [[self stream] cancelPendingSysExSendRequests];
}

- (SMSysExSendRequest *)currentSysExSendRequest;
{
    if ([[self stream] respondsToSelector:@selector(currentSysExSendRequest)])
        return [[self stream] currentSysExSendRequest];
    else
        return nil;
}

//
// SMPortOrVirtualStream subclass methods
//

- (NSArray *)allEndpoints;
{
    return [SMDestinationEndpoint destinationEndpoints];
}

- (SMEndpoint *)endpointWithUniqueID:(int)uniqueID;
{
    return [SMDestinationEndpoint destinationEndpointWithUniqueID:uniqueID];
}

- (id)newPortStream;
{
    SMPortOutputStream *stream = nil;

    NS_DURING {
        stream = [[SMPortOutputStream alloc] init];
        [stream setIgnoresTimeStamps:flags.ignoresTimeStamps];
        [stream setSendsSysExAsynchronously:flags.sendsSysExAsynchronously];
    } NS_HANDLER {
        [stream release];
        stream = nil;
    } NS_ENDHANDLER;

    if (!stream)
        return nil;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(portStreamEndpointDisappeared:) name:SMPortOutputStreamEndpointDisappearedNotification object:stream];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(repostNotification:) name:SMPortOutputStreamWillStartSysExSendNotification object:stream];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(repostNotification:) name:SMPortOutputStreamFinishedSysExSendNotification object:stream];
        
    return [stream autorelease];
}

- (void)willRemovePortStream;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:portStream];
}

- (id)newVirtualStream;
{
    SMVirtualOutputStream *stream;

    stream = [[SMVirtualOutputStream alloc] initWithName:virtualEndpointName uniqueID:virtualEndpointUniqueID];
    [stream setIgnoresTimeStamps:flags.ignoresTimeStamps];

    return [stream autorelease];
}

- (void)willRemoveVirtualStream;
{
    // Nothing is necessary
}

//
// SMMessageDestination protocol
//

- (void)takeMIDIMessages:(NSArray *)messages;
{
    [[self stream] takeMIDIMessages:messages];
}

@end


@implementation SMPortOrVirtualOutputStream (Private)

- (void)repostNotification:(NSNotification *)notification;
{
    [[NSNotificationCenter defaultCenter] postNotificationName:[notification name] object:self userInfo:[notification userInfo]];
}

@end
