//
//  AimHelper.m
//  BubbleShooter
//
//  Created by Guillermo Zafra on 16/07/13.
//  Copyright 2013 __MyCompanyName__. All rights reserved.
//

#import "AimHelper.h"


@implementation AimHelper

@synthesize direction, length;

-(id)initWithOrigin:(CGPoint)_origin{
    self = [super init];
    if (self) {
        origin = _origin;
        direction = ccp(0,1);
        length = 0;
    }
    
    return self;
}

- (void)draw
{
    [super draw];
	ccDrawColor4F(0.8, 1.0, 0.76, 1.0);
	glLineWidth(6.0f);
	ccDrawLine(origin, ccpAdd(origin, ccpMult(direction, length)));
}

@end
