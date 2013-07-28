//
//  Bubble.m
//  BubbleShooter
//
//  Created by Guillermo Zafra on 16/07/13.
//  Copyright 2013 __MyCompanyName__. All rights reserved.
//

#import "Bubble.h"

#define kBubbleVelocity 200


@implementation Bubble

@synthesize direction, bubbleType, bubbleColor, mustBeDestroyed, mustBeHeld;

- (id)initWithType:(enum EBubbleType)_type  andColor:(enum EBubbleColor)_color
{
    self = [super initWithSpriteFrameName:[NSString stringWithFormat:@"bubble_%d.png",(int)_color]];
    if (self) {
        velocity = kBubbleVelocity;
        bubbleType = _type;
        bubbleColor = _color;
        mustBeDestroyed = false;
        mustBeHeld = false;
        tag_ = kTagBubble;
    }
    return self;
}

- (void)update:(ccTime)deltaTime
{
    float newX = self.position.x + direction.x * kBubbleVelocity * deltaTime;
    float newY = self.position.y + direction.y * kBubbleVelocity * deltaTime;
    
    self.position = CGPointMake(newX, newY);
}

@end
