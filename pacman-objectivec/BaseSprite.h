//
//  BaseSprite.h
//  pacman-objectivec
//
//  Created by hahasouliu on 10/14/15.
//  Copyright © 2015 hahasouliu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface BaseSprite : NSObject

- (id)initWithEffect:(GLKBaseEffect *)baseEffect;
- (id)initWithFile:(NSString *)fileName effect:(GLKBaseEffect *)effect;
- (void)setMoveBoundary:(float)boundaryX boundaryY:(float)boundaryY;

@property (nonatomic, strong) GLKTextureInfo *textureInfo;
@property (assign) GLKVector2 position;
@property (assign) GLKVector2 moveVelocity;
@property (assign) CGSize contentSize;

- (void)render;
- (void)update;

@end
