//
//  BaseSprite.m
//  pacman-objectivec
//
//  Created by hahasouliu on 10/14/15.
//  Copyright © 2015 hahasouliu. All rights reserved.
//


#import "BaseSprite.h"

#define SQUARE_SIZE 30.0f
#define MOVE_SPEED (2)

typedef struct {
    GLKVector3 positionCoordinates;
    GLKVector2 textureCoordinates;
} VertexData;

VertexData SpriteVertices[] = {
    {{-SQUARE_SIZE/2, -SQUARE_SIZE/2, 0.0f}, {0.0f, 0.0f}},
    {{SQUARE_SIZE/2, -SQUARE_SIZE/2, 0.0f}, {1.0f, 0.0f}},
    {{-SQUARE_SIZE/2, SQUARE_SIZE/2, 0.0f}, {0.0f, 1.0f}},
    {{-SQUARE_SIZE/2, SQUARE_SIZE/2, 0.0f}, {0.0f, 1.0f}},
    {{SQUARE_SIZE/2, -SQUARE_SIZE/2, 0.0f}, {1.0f, 0.0f}},
    {{SQUARE_SIZE/2, SQUARE_SIZE/2, 0.0f}, {1.0f, 1.0f}}
};

// 0: right, 1: left, 2:up, 3:down
float RotateDegreeBasedOnMotion[] = {0.0f, 180.0f, 90.0f, 270.0f};

@interface BaseSprite()

@property (nonatomic, weak) GLKBaseEffect *baseEffect;
@property (assign) float boundayX;
@property (assign) float boundayY;

@end

@implementation BaseSprite {
    GLuint _vertextBufferId;
}

- (id)initWithFile:(NSString *)fileName effect:(GLKBaseEffect *)effect {
    if ((self = [super init])) {
        self.baseEffect = effect;
        NSDictionary * options = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithBool:YES],
                                  GLKTextureLoaderOriginBottomLeft,
                                  nil];
        NSError * error;
        NSString *path = [[NSBundle mainBundle] pathForResource:fileName ofType:nil];
        //NSLog(@"path is %@", path);
        
        self.textureInfo = [GLKTextureLoader textureWithContentsOfFile:path options:options error:&error];
        if (self.textureInfo == nil) {
            NSLog(@"Error loading file: %@", [error localizedDescription]);
            return nil;
        }
        
        self.contentSize = CGSizeMake(self.textureInfo.width, self.textureInfo.height);
        //NSLog(@"initWithFile [%u, %u]", self.textureInfo.width, self.textureInfo.height);
    }
    return self;
}


- (id)initWithEffect:(GLKBaseEffect *)baseEffect {
    if ((self = [super init])) {
        self.baseEffect = baseEffect;
    }
    return self;
}

- (void)render {
    glGenBuffers(1, &_vertextBufferId);
    glBindBuffer(GL_ARRAY_BUFFER, _vertextBufferId);
    glBufferData(GL_ARRAY_BUFFER, sizeof(SpriteVertices), SpriteVertices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(VertexData),
                          (GLvoid *)offsetof(VertexData, positionCoordinates));
    
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(VertexData),
                          (GLvoid *)offsetof(VertexData, textureCoordinates));
    
    self.baseEffect.texture2d0.name = self.textureInfo.name;
    self.baseEffect.texture2d0.target = self.textureInfo.target;
    self.baseEffect.transform.modelviewMatrix = [self caculateModelMatrix];
    
    [self.baseEffect prepareToDraw];
    glDrawArrays(GL_TRIANGLES, 0, 6);
}

- (GLKMatrix4) caculateModelMatrix {
    
    GLKMatrix4 modelMatrix = GLKMatrix4Identity;
    
    modelMatrix = GLKMatrix4Translate(modelMatrix, self.position.x, self.position.y, 0);
    modelMatrix = GLKMatrix4Translate(modelMatrix, self.contentSize.width/2, self.contentSize.height/2, 0);
    modelMatrix = GLKMatrix4Rotate(modelMatrix, GLKMathDegreesToRadians(RotateDegreeBasedOnMotion[self.currentMotion]), 0, 0, 1);
    //modelMatrix = GLKMatrix4Scale(modelMatrix, 0.25, 0.25, 0);

    return modelMatrix;
}

- (void)update {
    //NSLog(@"---------- update ----------");
    GLKVector2 nextMotionVector;
    switch (self.nextMotion) {
        case 0:
            nextMotionVector = GLKVector2Make(MOVE_SPEED, 0);
            break;
        case 1:
            nextMotionVector = GLKVector2Make((-1)*MOVE_SPEED, 0);
            break;
        case 2:
            nextMotionVector = GLKVector2Make(0, MOVE_SPEED);
            break;
        case 3:
            nextMotionVector = GLKVector2Make(0, (-1)*MOVE_SPEED);
            break;
        default:
            return;
    }
    GLKVector2 nextMotionPosition = GLKVector2Add(self.position, nextMotionVector);
    
    if (self.boundayX > 0 && self.boundayY > 0) {
        if (nextMotionPosition.x >= 0 &&
            nextMotionPosition.x <= self.boundayX-(self.contentSize.width) &&
            nextMotionPosition.y >= 0 &&
            nextMotionPosition.y <= self.boundayY-(self.contentSize.height) &&
            ![self bumpIntoWall:nextMotionPosition]) {
            self.position = nextMotionPosition;
            self.currentMotion = self.nextMotion;
        }
    }
    
    if (self.currentMotion != self.nextMotion) {
        GLKVector2 currentMotionVector;
        switch (self.currentMotion) {
            case 0:
                currentMotionVector = GLKVector2Make(MOVE_SPEED, 0);
                break;
            case 1:
                currentMotionVector = GLKVector2Make((-1)*MOVE_SPEED, 0);
                break;
            case 2:
                currentMotionVector = GLKVector2Make(0, MOVE_SPEED);
                break;
            case 3:
                currentMotionVector = GLKVector2Make(0, (-1)*MOVE_SPEED);
                break;
            default:
                return;
        }
        GLKVector2 currentMotionPosition = GLKVector2Add(self.position, currentMotionVector);
        
        if (self.boundayX > 0 && self.boundayY > 0) {
            if (currentMotionPosition.x >= 0 &&
                currentMotionPosition.x <= self.boundayX-(self.contentSize.width) &&
                currentMotionPosition.y >= 0 &&
                currentMotionPosition.y <= self.boundayY-(self.contentSize.height) &&
                ![self bumpIntoWall:currentMotionPosition]) {
                self.position = currentMotionPosition;
            }
        }

    }

}

- (BOOL) bumpIntoWall:(GLKVector2) updatedPosition {
    for (BaseMapSprite *mapSprite in self.mapSpriteArray) {
        BOOL xCollision =
            (mapSprite.position.x <= updatedPosition.x && mapSprite.position.x + [mapSprite getWidth] > updatedPosition.x) ||
            (updatedPosition.x <= mapSprite.position.x && updatedPosition.x + SQUARE_SIZE > mapSprite.position.x);
        BOOL yCollision =
        (mapSprite.position.y <= updatedPosition.y && mapSprite.position.y + [mapSprite getHeight] > updatedPosition.y) ||
        (updatedPosition.y <= mapSprite.position.y && updatedPosition.y + SQUARE_SIZE > mapSprite.position.y);
/*
        if (xCollision && yCollision) {
            NSLog(@"bumpIntoWall [%d, %d]", xCollision, yCollision);
            NSLog(@"updatedPosition [%f, %f]", updatedPosition.x, updatedPosition.y);
            NSLog(@"mapSprite.position [%f, %f]", mapSprite.position.x, mapSprite.position.y);
            NSLog(@"mapSprite getWH [%f, %f]", [mapSprite getWidth], [mapSprite getHeight]);
        }*/
        
        if (xCollision && yCollision) {
            return TRUE;
        }
    }
    
    return false;
}

- (void)setMoveBoundary:(float)boundaryX boundaryY:(float)boundaryY {
    self.boundayX = boundaryX;
    self.boundayY = boundaryY;
}

@end
