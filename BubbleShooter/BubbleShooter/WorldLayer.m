//
//  WorldLayer.m
//  BubbleShooter
//
//  Created by Guillermo Zafra on 16/07/13.
//  Copyright __MyCompanyName__ 2013. All rights reserved.
//


// Import the interfaces
#import "WorldLayer.h"

// Needed to obtain the Navigation Controller
#import "AppDelegate.h"

#pragma mark - HelloWorldLayer

// HelloWorldLayer implementation
@implementation WorldLayer

// Helper class method that creates a Scene with the HelloWorldLayer as the only child.
+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	WorldLayer *layer = [WorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super's" return value
	if( (self=[super init]) ) {
        
        // Init generic
        self.isTouchEnabled = YES;
        filledRows = 0;
        cannonPoint = ccp(kScreenWidth / 2, kScreenHeight * 0.1f);
        elapsedTime = 0;
        pushedRows = 0;
        shooting = false;
        even = true;
        gameState = EGameStopped;
        
        // Init batch node
        NSString *_textureSheetName = [NSString stringWithFormat:@"atlas.plist"];
        NSString *pathAndFileName = [[CCFileUtils sharedFileUtils] fullPathFromRelativePath:_textureSheetName ];
        BOOL      textureSheetExists = [[NSFileManager defaultManager] fileExistsAtPath:pathAndFileName];
        NSAssert(textureSheetExists == true, @"Texture sheet for world doesn't exist!");
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:_textureSheetName];
        batchNode = [CCSpriteBatchNode batchNodeWithFile:@"atlas.png" capacity:400];
        
        [self addChild:batchNode];
        
        // Init aim helper
        aimHelper = [[AimHelper alloc] initWithOrigin:cannonPoint];
        aimHelper.visible = false;
        [self addChild:aimHelper];
        [aimHelper release];
        
        // Init grid of bubbles
        bubblesGrid = [NSMutableArray arrayWithCapacity:kMaxRows];
        for (int i = 0; i < kMaxRows; i++) {
            NSMutableArray *row = [NSMutableArray arrayWithCapacity:12];
            [bubblesGrid setObject:row atIndexedSubscript:i];
            
            // Init with NSNull for empty spaces
            for (int j = 0; j < 12; j++) {
                [row setObject:[NSNull null] atIndexedSubscript:j];
            }
        }
        [bubblesGrid retain];

        [self scheduleUpdate];
        [self startGame];

	}
	return self;
}

#pragma mark Update

- (void)update:(ccTime)deltaTime{
    // Check game is playing
    if (gameState == EGamePlaying) {
        // Update bubble movement
        [bubbleToShoot update:deltaTime];
        
        // Check for collisions
        [self checkWallCollisions];
        if ([self checkBubblesCollisions]) {
            // Calculate first the row it's going to fit in
            int y = (kScreenHeight - (bubbleToShoot.position.y + kVerticalOffset)) / kBubbleSize;
            
            // Calculate if this row has an offset
            int rowOffset = 0;
            int numRow = even ? y : y + 1;
            if (numRow % 2 != 0) {
                rowOffset = kBubbleSize / 2;
            }
            
            // Now calculate the column on the grid
            int x = (bubbleToShoot.position.x - kHorizontalOffset + rowOffset) / kBubbleSize;
            
            // Check if this slot if empty and otherwise, chose nearest empty slot
            id thisSlot = [(NSMutableArray*)[bubblesGrid objectAtIndex:y] objectAtIndex:x];
            if (![thisSlot isKindOfClass:[NSNull class]]){
                CGPoint newSlot = [self getNearestEmptySlotForRow:y andCol:x];
                x = newSlot.x;
                y = newSlot.y;
            }
            
            // Add it to grid
            NSMutableArray *row = (NSMutableArray*)[bubblesGrid objectAtIndex:y];
            row[x] = bubbleToShoot;
            
            [self updateNumberOfRows];
            
            // Reposition correctly
            bubbleToShoot.position = [self getPositionForRow:y andCol:x];
            
            // Check color matches
            if ([self checkMatchesColor:(int)bubbleToShoot.bubbleColor forGridRow:y andCol:x] >= kNumOfMatchesRequired) {
                [self destroyBubbles];
                [self checkAndDropBubbles];
            }else{
                [self clearBubbles];
            }
            
            // Remove reference
            bubbleToShoot = nil;
            [self prepareBubbleToShoot]; // Prepare another bubble
        }
        
        elapsedTime += deltaTime;
        if (elapsedTime > kTimeToPushRow) {
            [self pushRows];
            [self addNewRow];
            
            elapsedTime = 0;
        }
    }
}

#pragma mark Collisions

- (void)checkWallCollisions{
    CGSize size = [[CCDirector sharedDirector] winSize];
    
    // Check just if there is a shooting bubble and it's actually moving
    if (bubbleToShoot && bubbleToShoot.bubbleType == EBubbleMoving) {
        if (bubbleToShoot.position.x < kHorizontalOffset) {
            // Bounced in left wall
            CGPoint u = bubbleToShoot.direction;
            
            u = ccp(-u.x, u.y);
            [bubbleToShoot setDirection:u];
            
        }else if(bubbleToShoot.position.x > size.width - kHorizontalOffset){
            // Bounced in right wall
            CGPoint u = bubbleToShoot.direction;
            
            u = ccp(-u.x, u.y);
            [bubbleToShoot setDirection:u];
        }
    }
}

- (bool)checkBubblesCollisions{
    // Check just if there is a shooting bubble and it's actually moving
    if (bubbleToShoot && bubbleToShoot.bubbleType == EBubbleMoving) {
        
        // Loop through all bubbles to check collision
        for (NSMutableArray *row in bubblesGrid){
            for (id obj in row){
                if ([obj isKindOfClass:[Bubble class]]) {
                    Bubble *bubble = (Bubble*)obj;
                    
                    // Check if collision happened (just radius)
                    if (ccpDistance(bubbleToShoot.position, bubble.position) < kBubbleSize * 0.9f) {
                        bubbleToShoot.bubbleType = EBubbleStatic;
                        //bubbleToShoot.position = ccpAdd(bubbleToShoot.position, ccpMult(bubbleToShoot.direction, kBubbleSize * 0.2f));
                        shooting = false;
                        
                        return true; // Return, no need to keep checking
                    }
                }
            }
        }
    }
    
    return false;
}

#pragma mark Grid

- (void)fillGrid:(int)_numberOfRows{
    int count = 0;
    do {
        [self addNewRowAtIndex:count];
        count++;
    } while (count < _numberOfRows);
}

- (void) addNewRow{
    // Adds row at index 0 by default
    [self addNewRowAtIndex:0];
}

- (void) addNewRowAtIndex:(int)_idx{
    // Calculate number of bubbles based on position or number of rows
    int numberOfBubbles = 11;
    
    // Check wheter pushing a row, or populating at the beginning
    if (_idx == 0) {
        // User number of pushed rows instead
        if (pushedRows % 2 != 0) {
            numberOfBubbles = 12;
        }
    }else{
        // Use index
        if (_idx % 2 != 0) {
            numberOfBubbles = 12;
        }
    }
 
    // Create row
    NSMutableArray *row = [NSMutableArray arrayWithCapacity:12];
    
    // Fill with bubbles
    for (int col = 0; col < numberOfBubbles; col++) {
        int randomColor = arc4random() % kNumColors;
        Bubble *newBub = [[[Bubble alloc] initWithType:EBubbleStatic andColor:randomColor] autorelease];
        [row addObject:newBub];
        
        // Calculate position and add to layer
        newBub.position = [self getPositionForRow:_idx andCol:col];
        [batchNode addChild:newBub];
    }
    
    // For rows with 11 items, last item is null
    if (numberOfBubbles < 12) {
        [row addObject:[NSNull null]];
    }
    
    [bubblesGrid insertObject:row atIndex:_idx];
    
    pushedRows++; // Updates number of pushed rows
    [self updateNumberOfRows]; // Updates total number of rows with at least one bubble
    
    // If grid has more than allowed rows, remove
    if ([bubblesGrid count] > kMaxRows) {
        [bubblesGrid removeLastObject];
    }
}

- (void) pushRows{
    // Shift all bubbles in each row to the next one
    [self updateNumberOfRows];
    
    for (int i = filledRows - 1; i >= 0; i--) {
        id arrayToShift = [bubblesGrid objectAtIndex:i];
        
        // Move physically every bubble in this row
        id moveAction = [CCMoveBy actionWithDuration:0.2f position:ccp(0, - kBubbleSize)];
        for (id obj in arrayToShift) {
            
            // If object is not nil
            if ([obj isKindOfClass:[Bubble class]]) {
                Bubble *bubble = (Bubble*)obj;
                [bubble runAction:[[moveAction copy] autorelease]];
            }
        }
    }
    
    // Switch even flag
    even = !even; 
}

- (void) updateNumberOfRows{
    int newNumberOfFilledRows = 0;
    // Reset all bubbles to not be destroyed
    for (NSMutableArray *row in bubblesGrid) {
        for (id obj in row) {
            if ([obj isKindOfClass:[Bubble class]]) {
                newNumberOfFilledRows++;
                break; // Skip the rest of the loop
            }
        }
    }
    
    filledRows = newNumberOfFilledRows;
    
    // Check end of game
    if (filledRows >= kMaxRows) {
        [self endGame];
    }
}

- (CGPoint) getPositionForRow:(int)_row andCol:(int)_col{
    CGSize size = [[CCDirector sharedDirector] winSize];
    
    // Calculate position in layer based on offset and bubble size
    float y = size.height - kVerticalOffset - kBubbleSize / 2 - _row * kBubbleSize; // Fill downwards
    float x = kHorizontalOffset + kBubbleSize / 2 + _col * kBubbleSize;
    
    // Check row is indented
    _row = even ? _row : _row + 1;
    if (_row % 2 != 0) {
        x -= kBubbleSize / 2;
    }
    
    return ccp(x, y);
}

- (int) checkMatchesColor:(int)_color forGridRow:(int)_row andCol:(int)_col{
    CCLOG(@"Call to matches Color row %d col %d", _row, _col);
    // Recursive function to check color matches on all bubbles nearby
    int colorMatches = 0;
    
    // Obtain upper, middle and lower rows
    NSMutableArray *upperRow = _row > 1 ? [bubblesGrid objectAtIndex:_row - 1] : nil; // First row is never checked (hidden row)
    NSMutableArray *middleRow = [bubblesGrid objectAtIndex:_row];
    NSMutableArray *lowerRow = _row < (kMaxRows - 1) ? [bubblesGrid objectAtIndex:_row + 1] : nil;
    
    // Get color to look for
    Bubble *thisBubble = (Bubble*)[middleRow objectAtIndex:_col];
    int colorToMatch = thisBubble.bubbleColor;
    
    // Check if color matches
    if (colorToMatch == _color && !thisBubble.mustBeDestroyed) {
        colorMatches++;
        thisBubble.mustBeDestroyed = true;
    }
    // Check upper bubble, if any
    if (upperRow) {
        id upper = [upperRow objectAtIndex:_col];
        if ([upper isKindOfClass:[Bubble class]]) {
            Bubble *bubble = (Bubble*)upper;
            if (!bubble.mustBeDestroyed && bubble.bubbleColor == colorToMatch) {
                colorMatches += [self checkMatchesColor:colorToMatch forGridRow:_row - 1 andCol:_col];
            }
        }
    }
    
    // Check lower bubbles, if any
    if (lowerRow) {
        id lower = [lowerRow objectAtIndex:_col];
        if ([lower isKindOfClass:[Bubble class]]) {
            Bubble *bubble = (Bubble*)lower;
            if (!bubble.mustBeDestroyed && bubble.bubbleColor == colorToMatch) {
                colorMatches += [self checkMatchesColor:colorToMatch forGridRow:_row + 1 andCol:_col];
            }
        }
    }
    
    // Check if it's an even row to know nearby bubbles
    if ((_row -  pushedRows) % 2 != 0) {
        // NOTE: col +1
        
        // Check upper right and lower right bubbles
        if (upperRow && _col < 11) {
            id upRight = [upperRow objectAtIndex:_col + 1];
            if ([upRight isKindOfClass:[Bubble class]]) {
                Bubble *bubble = (Bubble*)upRight;
                if (!bubble.mustBeDestroyed && bubble.bubbleColor == colorToMatch) {
                    colorMatches += [self checkMatchesColor:colorToMatch forGridRow:_row - 1 andCol:_col + 1];
                }
            }
        }
        
        if (lowerRow && _col < 11) {
            id lowerRight = [lowerRow objectAtIndex:_col + 1];
            if ([lowerRight isKindOfClass:[Bubble class]]) {
                Bubble *bubble = (Bubble*)lowerRight;
                if (!bubble.mustBeDestroyed && bubble.bubbleColor == colorToMatch) {
                    colorMatches += [self checkMatchesColor:colorToMatch forGridRow:_row + 1 andCol:_col + 1];
                }
            }
        }
    }else{
        // NOTE: col -1
        
        // Check upper left and lower left bubbles
        if (upperRow && _col > 0) {
            id upLeft = [upperRow objectAtIndex:_col - 1];
            if ([upLeft isKindOfClass:[Bubble class]]) {
                Bubble *bubble = (Bubble*)upLeft;
                if (!bubble.mustBeDestroyed && bubble.bubbleColor == colorToMatch) {
                    colorMatches += [self checkMatchesColor:colorToMatch forGridRow:_row - 1 andCol:_col - 1];
                }
            }
        }
        
        if (lowerRow && _col > 0) {
            id lowerLeft = [lowerRow objectAtIndex:_col - 1];
            if ([lowerLeft isKindOfClass:[Bubble class]]) {
                Bubble *bubble = (Bubble*)lowerLeft;
                if (!bubble.mustBeDestroyed && bubble.bubbleColor == colorToMatch) {
                    colorMatches += [self checkMatchesColor:colorToMatch forGridRow:_row + 1 andCol:_col - 1];
                }
            }
        }
    }
    
    // Check left nearby bubble
    if (_col > 0) {
        id left = [middleRow objectAtIndex:_col - 1];
        if ([left isKindOfClass:[Bubble class]]) {
            Bubble *leftBubble = (Bubble*)left;
            if (!leftBubble.mustBeDestroyed && leftBubble.bubbleColor == colorToMatch) {
                colorMatches += [self checkMatchesColor:colorToMatch forGridRow:_row andCol:_col - 1];
            }
        }
    }

    
    // Check right nearby bubble
    if (_col < 11) {
        id right = [middleRow objectAtIndex:_col + 1];
        if ([right isKindOfClass:[Bubble class]]) {
            Bubble *rightBubble = (Bubble*)right;
            if (!rightBubble.mustBeDestroyed && rightBubble.bubbleColor == colorToMatch) {
                colorMatches += [self checkMatchesColor:colorToMatch forGridRow:_row andCol:_col + 1];
            }
        }
    }
    
    return colorMatches;
}


- (void) destroyBubbles{
    // Loop through all bubbles to see which ones must be destroyed
    for (NSMutableArray *row in bubblesGrid) {
        for (int i = 0; i < 12; i++) {
            id obj = [row objectAtIndex:i];
            if ([obj isKindOfClass:[Bubble class]]) {
                Bubble *bubble = (Bubble*)obj;
                if (bubble.mustBeDestroyed) {
                    // Remove from grid
                    [row replaceObjectAtIndex:i withObject:[NSNull null]];
                    
                    // Create selector to remove node from layer
                    id destroyBubble = [CCCallBlock actionWithBlock:^{
                        [bubble removeFromParentAndCleanup:YES];
                    }];
                    [bubble runAction:[CCSequence actions:[CCScaleTo actionWithDuration:0.2f scale:0.01f],
                                       destroyBubble, nil]];
                }
            }
        }
    }
}

- (void) clearBubbles{
    // Reset all bubbles to not be destroyed
    for (NSMutableArray *row in bubblesGrid) {
        for (id obj in row) {
            if ([obj isKindOfClass:[Bubble class]]) {
                Bubble *bubble = (Bubble*)obj;
                bubble.mustBeDestroyed = false;
            }
        }
    }
}

- (void)checkAndDropBubbles{ 
    // Recursive call to hold bubbles that are linked
    [self holdBubbleForGridRow:0 andCol:0];
    
    // Set not held bubbles to drop
    for (NSMutableArray *row in bubblesGrid) {
        for (int i = 0; i < 12; i++) {
            id obj = [row objectAtIndex:i];
            if ([obj isKindOfClass:[Bubble class]]) {
                Bubble *bubble = (Bubble*)obj;
                if (!bubble.mustBeHeld) {
                    // Remove from grid
                    [row replaceObjectAtIndex:i withObject:[NSNull null]];
                    
                    // Create selector to remove node
                    id destroyBubble = [CCCallBlock actionWithBlock:^{
                        [bubble removeFromParentAndCleanup:YES];
                    }];
                    [bubble runAction:[CCSequence actions:
                                       [CCEaseOut actionWithAction:[CCMoveBy actionWithDuration:0.7f position:ccp(0, - kScreenHeight)] rate:0.5f],
                                       destroyBubble, nil]];
                }else{
                    // Reset
                    bubble.mustBeHeld = false;
                }
            }
        }
    }
}

- (CGPoint) getNearestEmptySlotForRow:(int)_row andCol:(int)_col{
    // Obtain upper, middle and lower rows
    NSMutableArray *upperRow = _row > 1 ? [bubblesGrid objectAtIndex:_row - 1] : nil; // First row is never checked (hidden row)
    NSMutableArray *middleRow = [bubblesGrid objectAtIndex:_row];
    NSMutableArray *lowerRow = _row < (kMaxRows - 1) ? [bubblesGrid objectAtIndex:_row + 1] : nil;
    
    int newRow = _row;
    int newCol = _col;
    
    // Check upper bubble, if any
    if (upperRow) {
        id upper = [upperRow objectAtIndex:_col];
        if (![upper isKindOfClass:[Bubble class]]) {
            return ccp(newCol, --newRow);
        }
    }
    
    // Check left nearby bubble
    if (_col > 0) {
        id left = [middleRow objectAtIndex:_col - 1];
        if (![left isKindOfClass:[Bubble class]]) {
            return ccp(--newCol, newRow);
        }
    }
    
    
    // Check right nearby bubble
    if (_col < 11) {
        id right = [middleRow objectAtIndex:_col + 1];
        if (![right isKindOfClass:[Bubble class]]) {
            return ccp(++newCol, newRow);
        }
    }
    
    // Check if it's an even row to know nearby bubbles
    if ((_row - pushedRows) % 2 != 0) {
        // NOTE: col +1
        
        // Check upper right and lower right bubbles
        if (upperRow && _col < 11) {
            id upRight = [upperRow objectAtIndex:_col + 1];
            if (![upRight isKindOfClass:[Bubble class]]) {
                return ccp(++newCol, --newRow);
            }
        }
        
        if (lowerRow && _col < 11) {
            id lowerRight = [lowerRow objectAtIndex:_col + 1];
            if (![lowerRight isKindOfClass:[Bubble class]]) {
                return ccp(--newCol, ++newRow);
            }
        }
    }else{
        // NOTE: col -1
        
        // Check upper left and lower left bubbles
        if (upperRow && _col > 0) {
            id upLeft = [upperRow objectAtIndex:_col - 1];
            if (![upLeft isKindOfClass:[Bubble class]]) {
                return ccp(++newCol, --newRow);
            }
        }
        
        if (lowerRow && _col > 0) {
            id lowerLeft = [lowerRow objectAtIndex:_col - 1];
            if (![lowerLeft isKindOfClass:[Bubble class]]) {
                return ccp(--newCol, ++newRow);
            }
        }
    }
    
    // Check lower bubbles, if any
    if (lowerRow) {
        id lower = [lowerRow objectAtIndex:_col];
        if (![lower isKindOfClass:[Bubble class]]) {
            return ccp(newCol, ++newRow);
        }
    }

    CCLOG(@"This shouldn't happen, ever!");
    return ccp(newCol, newRow);
}

- (void) holdBubbleForGridRow:(int)_row andCol:(int)_col{
    // Recursive call to hold all adjacent bubbles
    // (Those not held will be dropped thereafter)
    NSMutableArray *middleRow = [bubblesGrid objectAtIndex:_row];
    NSMutableArray *lowerRow = _row < (kMaxRows - 1) ? [bubblesGrid objectAtIndex:_row + 1] : nil;;
    
    Bubble *thisBubble = (Bubble*)[middleRow objectAtIndex:_col];
    thisBubble.mustBeHeld = true;
    
    // Check lower bubbles, if any row below
    if (lowerRow) {
        id lower = [lowerRow objectAtIndex:_col];
        if ([lower isKindOfClass:[Bubble class]]) {
            Bubble *bubble = (Bubble*)lower;
            if (!bubble.mustBeHeld) {
                [self holdBubbleForGridRow:_row + 1 andCol:_col];
            }
        }
        
        // Check lower right or lower left depending if row is even
        if ((_row -  pushedRows) % 2 != 0) {
            // NOTE: col +1
            
            if (_col < 11) {
                id lowerRight = [lowerRow objectAtIndex:_col + 1];
                if ([lowerRight isKindOfClass:[Bubble class]]) {
                    Bubble *bubble = (Bubble*)lowerRight;
                    if (!bubble.mustBeHeld) {
                        [self holdBubbleForGridRow:_row + 1 andCol:_col +1];
                    }
                }
            }
        }else{
            // NOTE: col-1
            
            if (_col > 0) {
                id lowerLeft = [lowerRow objectAtIndex:_col - 1];
                if ([lowerLeft isKindOfClass:[Bubble class]]) {
                    Bubble *bubble = (Bubble*)lowerLeft;
                    if (!bubble.mustBeHeld) {
                        [self holdBubbleForGridRow:_row + 1 andCol:_col -1];
                    }
                }
            }
        }
    }
    
    // Check left nearby bubble
    if (_col > 0) {
        id left = [middleRow objectAtIndex:_col - 1];
        if ([left isKindOfClass:[Bubble class]]) {
            Bubble *leftBubble = (Bubble*)left;
            if (!leftBubble.mustBeHeld) {
                [self holdBubbleForGridRow:_row andCol:_col -1];
            }
        }
    }
    
    
    // Check right nearby bubble
    if (_col < 11) {
        id right = [middleRow objectAtIndex:_col + 1];
        if ([right isKindOfClass:[Bubble class]]) {
            Bubble *rightBubble = (Bubble*)right;
            if (!rightBubble.mustBeHeld) {
                [self holdBubbleForGridRow:_row andCol:_col +1];
            }
        }
    }
}

- (void) clearGrid{

}

#pragma mark Shooting

- (void) prepareBubbleToShoot{    
    // Create random bubble and add to layer
    int randomColor = arc4random() % kNumColors;
    bubbleToShoot = [[[Bubble alloc] initWithType:EBubbleDisabled andColor:randomColor] autorelease];
    bubbleToShoot.position = cannonPoint;
    [batchNode addChild:bubbleToShoot];
}

- (void) shootBubble{
    // Calculate and assign direction of the bubble based on last touch
    CGPoint unitary = ccpNormalize(ccpSub(lastLocation, cannonPoint));
    bubbleToShoot.direction = unitary;
    
    // Enable bubble to be shot
    bubbleToShoot.bubbleType = EBubbleMoving;
    shooting = true;
}

#pragma mark Game

- (void) startGame{
    [self fillGrid:5];
    [self prepareBubbleToShoot];
    
    // Set game as playing
    gameState = EGamePlaying;
}

- (void) restartGame{
    
    // Remove all bubbles from grid
    for (NSMutableArray *row in bubblesGrid) {
        for (int i = 0;i<row.count;i++) {
            id obj = [row objectAtIndex:i];
            if ([obj isKindOfClass:[Bubble class]]) {
                // Replace object with null and remove bubble from layer
                row[i] = [NSNull null];
                [obj removeFromParentAndCleanup:YES];
            }
        }
    }
    
    // Remove shooting bubble, if any
    if (bubbleToShoot) {
        [bubbleToShoot removeFromParentAndCleanup:YES];
        bubbleToShoot = nil;
    }
    
    // Restart other values
    pushedRows = 0;
    filledRows = 0;
    shooting = false;
    even = true;
    
    // Remove game over label
    [self removeChildByTag:kTagGameOverLabel cleanup:YES];
    
    // Start another game
    [self startGame];
}

- (void) endGame{
    if (gameState == EGamePlaying) {
        // Show game over label and stop director
        CCLabelTTF *label = [CCLabelTTF labelWithString:@"Game Over" fontName:@"Marker Felt" fontSize:64];
        label.position =  ccp( kScreenWidth /2 , kScreenHeight/2 );
        label.tag = kTagGameOverLabel;
        [self addChild: label];
        
        gameState = EGameStopped;
    }
}

#pragma mark -
#pragma mark Touch Events

-(void) ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    if (!shooting && gameState == EGamePlaying) {
        for( UITouch *touch in touches ) {
            CGPoint location = [touch locationInView: [touch view]];
            lastLocation = [[CCDirector sharedDirector] convertToGL: location];
            
            if (lastLocation.y < cannonPoint.y + 20) {
                lastLocation.y = cannonPoint.y + 20;
            }
            
            // Show Aim Helper in the shooting direction
            CGPoint unitary = ccpNormalize(ccpSub(lastLocation, cannonPoint));
            aimHelper.direction = unitary;
            
            float verticalDistance = kScreenHeight - cannonPoint.y - filledRows * kBubbleSize; // Aprox
            aimHelper.length = verticalDistance / unitary.y;
            
            aimHelper.visible = true;
        }
    }
}

-(void) ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!shooting && gameState == EGamePlaying) {
        for( UITouch *touch in touches ) {
            CGPoint location = [touch locationInView: [touch view]];
            lastLocation = [[CCDirector sharedDirector] convertToGL: location];
            
            if (lastLocation.y < cannonPoint.y + 20) {
                lastLocation.y = cannonPoint.y + 20;
            }
            
            // Update Aim Helper direction
            CGPoint unitary = ccpNormalize(ccpSub(lastLocation, cannonPoint));
            aimHelper.direction = unitary;
            
            float verticalDistance = kScreenHeight - cannonPoint.y - filledRows * kBubbleSize; // Aprox
            aimHelper.length = verticalDistance / unitary.y;
        }
    }
}

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    // Check if game was stopped so we restart another game
    if (gameState == EGameStopped) {
        [self restartGame];
        return;
    }
    
    if (!shooting) {
        [self shootBubble];
        
        // Hide Aim Helper again
        aimHelper.visible = false;
    }
}

#pragma mark -
#pragma mark Dealloc

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
    
    [bubblesGrid release];
	
	// don't forget to call "super dealloc"
	[super dealloc];
}

@end
