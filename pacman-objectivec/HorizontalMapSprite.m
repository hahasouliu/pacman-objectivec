//
//  HorizontalMapSprite.m
//  pacman-objectivec
//
//  Created by hahasouliu on 10/22/15.
//  Copyright © 2015 hahasouliu. All rights reserved.
//

#import "HorizontalMapSprite.h"

#define SQUARE_WIDTH 50.0f
#define SQUARE_HEIGHT 10.0f

typedef struct {
    GLKVector3 positionCoordinates;
    GLKVector2 textureCoordinates;
} VertexData;

VertexData HorizontalMapVertices[] = {
    {{-SQUARE_WIDTH/2, -SQUARE_HEIGHT/2, 0.0f}, {0.0f, 0.0f}},
    {{SQUARE_WIDTH/2, -SQUARE_HEIGHT/2, 0.0f}, {1.0f, 0.0f}},
    {{-SQUARE_WIDTH/2, SQUARE_HEIGHT/2, 0.0f}, {0.0f, 1.0f}},
    {{-SQUARE_WIDTH/2, SQUARE_HEIGHT/2, 0.0f}, {0.0f, 1.0f}},
    {{SQUARE_WIDTH/2, -SQUARE_HEIGHT/2, 0.0f}, {1.0f, 0.0f}},
    {{SQUARE_WIDTH/2, SQUARE_HEIGHT/2, 0.0f}, {1.0f, 1.0f}}
};

@interface HorizontalMapSprite()

@property (nonatomic, weak) GLKBaseEffect *baseEffect;

@end


@implementation HorizontalMapSprite {
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
        
    }
    return self;
}

- (void)render {
    glGenBuffers(1, &_vertextBufferId);
    glBindBuffer(GL_ARRAY_BUFFER, _vertextBufferId);
    glBufferData(GL_ARRAY_BUFFER, sizeof(HorizontalMapVertices), HorizontalMapVertices, GL_STATIC_DRAW);
    
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
    modelMatrix = GLKMatrix4Translate(modelMatrix, SQUARE_WIDTH/2, SQUARE_HEIGHT/2, 0);
    return modelMatrix;
}

- (float) getWidth {
    return SQUARE_WIDTH;
}

- (float) getHeight {
    return SQUARE_HEIGHT;
}


@end

