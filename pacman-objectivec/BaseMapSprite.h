//
//  BaseMapSprite.h
//  pacman-objectivec
//
//  Created by hahasouliu on 10/21/15.
//  Copyright © 2015 hahasouliu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface BaseMapSprite : NSObject

@property (nonatomic, strong) GLKTextureInfo *textureInfo;
@property (assign) CGSize contentSize;
@property (assign) GLKVector2 position;

- (id)initWithFile:(NSString *)fileName effect:(GLKBaseEffect *)effect;
- (void) setSize:(float)width height:(float)height;
- (void)render;
- (float) getWidth;
- (float) getHeight;


@end
