//
//  ViewController.m
//  pacman-objectivec
//
//  Created by hahasouliu on 10/14/15.
//  Copyright © 2015 hahasouliu. All rights reserved.
//

#import "ViewController.h"
#import "MapSprite.h"
#import "BaseSprite.h"
#import "BaseMapSprite.h"
#import "VerticalMapSprite.h"
#import "HorizontalMapSprite.h"


int VERTICAL_SPRITES[]   = {2, 1, 4, 1, 6, 1, 1, 2, 7, 2,
                            4, 3, 1, 4, 2, 4, 6, 4 ,7, 4,
                            1, 5, 2, 5, 3, 5, 5, 5, 6, 5,
                            7, 5, 1, 6, 2, 6, 3, 6, 5, 6,
                            6, 6, 7, 6, 3, 7, 5, 7, 1, 8,
                            2, 8, 6, 8, 7, 8, 1, 9, 2, 9,
                            4, 9, 6, 9, 7, 9, 1, 11, 3, 11,
                            4, 11, 5, 11, 7, 11, 1, 12, 3, 12,
                            4, 12, 5, 12, 7, 12};
int HORIZONTAL_SPRITES[] = {1, 1, 2, 1, 5, 1, 6, 1, 3, 2,
                            4, 2, 1, 3, 2, 3, 5, 3, 6, 3,
                            0, 4, 3, 4, 4, 4, 7, 4, 3, 5,
                            4, 5, 0, 7, 7, 7, 0, 8, 3, 8,
                            4, 8, 7, 8, 2, 9, 5, 9, 0, 10,
                            3, 10, 4, 10, 7, 10, 1, 11, 2, 11,
                            5, 11, 6, 11, 1, 13, 2, 13, 5, 13,
                            6, 13};

@interface ViewController ()
@property (assign) float screenWidth;
@property (assign) float screenHeight;
@property (assign) float timeSinceLastSpawn;
@property (assign) bool isTouchStart;
@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic, strong) GLKBaseEffect *baseEffect;
@property (nonatomic, strong) GLKBaseEffect * mapEffect;
@property (nonatomic, strong) BaseSprite *pacmanSprite;
@property (nonatomic, strong) MapSprite * mapSprite;
@property (strong) NSMutableArray * children;
@property (strong) NSMutableArray * mapSpriteArray;
@property (assign) CGPoint touchStartPoint;
@property (assign) CGPoint touchEndPoint;
@end

@implementation ViewController {
    GLuint _vertextBufferId;
}

@synthesize context = _context;
@synthesize children = _children;
@synthesize timeSinceLastSpawn = _timeSinceLastSpawn;
@synthesize isTouchStart = _isTouchStart;
@synthesize touchStartPoint = _touchStartPoint;
@synthesize touchEndPoint = _touchEndPoint;


- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder]) ) {
        // init children array
        self.children = [[NSMutableArray alloc] initWithCapacity:20];
        self.mapSpriteArray = [[NSMutableArray alloc] initWithCapacity:100];
    }
    return self;
}

- (void)viewDidLoad {
    // Do any additional setup after loading the view, typically from a nib.
    
    [super viewDidLoad];
    
    self.screenWidth = [[UIScreen mainScreen] bounds].size.width;
    self.screenHeight = [[UIScreen mainScreen] bounds].size.height;
    NSLog(@"Screen size [%f, %f]", self.screenWidth, self.screenHeight);
    NSLog(@"Screen size 2 [%f, %f]", self.view.bounds.size.width, self.view.bounds.size.height);
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    [EAGLContext setCurrentContext:self.context];
    
    // init effect
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, self.screenWidth, 0, self.screenHeight, -1024, 1024);
    self.baseEffect = [[GLKBaseEffect alloc] init];
    self.baseEffect.transform.projectionMatrix = projectionMatrix;
    
    // setup pacman
    self.pacmanSprite = [[BaseSprite alloc] initWithFile:@"pacman-2.png" effect:self.baseEffect];
    self.pacmanSprite.position = GLKVector2Make(5, 9);
    [self.pacmanSprite setMoveBoundary:self.screenWidth boundaryY:self.screenHeight];


    // setup map
    GLKMatrix4 projectionMatrixForMap = GLKMatrix4MakeOrtho(0, 320, 0, 568, -1024, 1024);
    self.mapEffect = [[GLKBaseEffect alloc] init];
    self.mapEffect.transform.projectionMatrix = projectionMatrixForMap;
    self.mapSprite = [[MapSprite alloc] initWithFile:@"map-1.png" effect:self.mapEffect];
    [self initMap];
    
    
    // gesture recognize
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)];
    [self.view addGestureRecognizer:tapRecognizer];
    
    UISwipeGestureRecognizer *swipeUpRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeUp:)];
    UISwipeGestureRecognizer *swipeDownRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeDown:)];
    UISwipeGestureRecognizer *swipeRightRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeRight:)];
    UISwipeGestureRecognizer *swipeLeftRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeLeft:)];
    
    swipeUpRecognizer.direction = UISwipeGestureRecognizerDirectionUp;
    swipeDownRecognizer.direction = UISwipeGestureRecognizerDirectionDown;
    swipeRightRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    swipeLeftRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipeUpRecognizer];
    [self.view addGestureRecognizer:swipeDownRecognizer];
    [self.view addGestureRecognizer:swipeRightRecognizer];
    [self.view addGestureRecognizer:swipeLeftRecognizer];
    
    // init touch
    self.isTouchStart = false;
}

- (void)initMap {
    BaseMapSprite *mapSprite;
    
    int verticalSpritesSize = (sizeof(VERTICAL_SPRITES)/sizeof(int));
    NSLog(@"verticalSpritesSize %d", verticalSpritesSize);
    for (int i = 0 ; i < verticalSpritesSize ; i+=2) {
        mapSprite = [[VerticalMapSprite alloc] initWithFile:@"wall-vertical.png" effect:self.baseEffect];
        int x = 5 + (VERTICAL_SPRITES[i] * 30) + ((VERTICAL_SPRITES[i]-1) * 10);
        int y;
        if (VERTICAL_SPRITES[i+1] == 0) {
            y = -1;
        } else {
            y = 9 + (VERTICAL_SPRITES[i+1] * 30) + ((VERTICAL_SPRITES[i+1] - 1) * 10);
        }
        mapSprite.position = GLKVector2Make(x, y);
        [self.mapSpriteArray addObject:mapSprite];
    }
    
    int horizontalSpritesSize = (sizeof(HORIZONTAL_SPRITES)/sizeof(int));
    NSLog(@"verticalSpritesSize %d", horizontalSpritesSize);
    for (int i = 0 ; i < horizontalSpritesSize ; i+=2) {
        mapSprite = [[HorizontalMapSprite alloc] initWithFile:@"wall-horizontal.png" effect:self.baseEffect];
        
        int x;
        if (HORIZONTAL_SPRITES[i] == 0) {
            x = -5;
        } else {
            x = 5 + (HORIZONTAL_SPRITES[i] * 30) + ((HORIZONTAL_SPRITES[i]-1) * 10);
        }
        int y = 9 + (HORIZONTAL_SPRITES[i+1] * 30) + ((HORIZONTAL_SPRITES[i+1]-1) * 10);
        mapSprite.position = GLKVector2Make(x, y);
        [self.mapSpriteArray addObject:mapSprite];
        
    }
    
    self.pacmanSprite.mapSpriteArray = self.mapSpriteArray;
}



/*
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    self.touchStartPoint = [[touches anyObject] locationInView:self.view];
    NSLog(@"touchesBegan [%f, %f]", self.touchStartPoint.x, self.touchStartPoint.y);
    self.isTouchStart = true;
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    //CGPoint touchMovingPoint = [[touches anyObject] locationInView:self.view];
    //NSLog(@"touchesMoved [%f, %f]", touchMovingPoint.x, touchMovingPoint.y);
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    self.touchEndPoint = [[touches anyObject] locationInView:self.view];
    NSLog(@"touchesEnded [%f, %f]", self.touchEndPoint.x, self.touchEndPoint.y);
    
    if (self.isTouchStart) {
        self.isTouchStart = false;
        [self calculateMotion];
    }
}
*/

- (void)handleTapFrom:(UITapGestureRecognizer *)recognizer {
    
    // 1
    CGPoint touchLocation = [recognizer locationInView:recognizer.view];
    touchLocation = CGPointMake(touchLocation.x, self.screenHeight - touchLocation.y);
    NSLog(@"handleTapFrom [%f, %f]", touchLocation.x, touchLocation.y);
}

- (void)handleSwipeUp:(UISwipeGestureRecognizer *)recognizer {
    NSLog(@"Swipe up");
    self.pacmanSprite.nextMotion = 2;
    //self.pacmanSprite.moveVelocity = GLKVector2Make(0, MOVE_SPEED);
}

- (void)handleSwipeDown:(UISwipeGestureRecognizer *)recognizer {
    NSLog(@"Swipe down");
    self.pacmanSprite.nextMotion = 3;
}

- (void)handleSwipeRight:(UISwipeGestureRecognizer *)recognizer {
    NSLog(@"Swipe right");
    self.pacmanSprite.nextMotion = 0;
}

- (void)handleSwipeLeft:(UISwipeGestureRecognizer *)recognizer {
    NSLog(@"Swipe left");
    self.pacmanSprite.nextMotion = 1;
}

- (void)addGhost {
    BaseSprite * ghost = [[BaseSprite alloc] initWithFile:@"red-ghost-1.png" effect:self.baseEffect];
    [self.children addObject:ghost];
    
    int minY = 0;
    int maxY = self.screenHeight - ghost.contentSize.height;
    //NSLog(@"ghost x %f", ghost.contentSize.width/4);
    //NSLog(@"ghost y [%d, %d]", minY, maxY);
    int rangeY = maxY - minY;
    int actualY = (arc4random() % rangeY) + minY;
    
    
    ghost.position = GLKVector2Make(320, actualY);
    
    int minVelocity = self.screenWidth/20;
    int maxVelocity = self.screenWidth/10;
    int rangeVelocity = maxVelocity - minVelocity;
    int actualVelocity = (arc4random() % rangeVelocity) + minVelocity;
    
    ghost.moveVelocity = GLKVector2Make(-actualVelocity, 0);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    NSLog(@"didReceiveMemoryWarning");
    [EAGLContext setCurrentContext:self.context];
    glDeleteBuffers(1, &_vertextBufferId);
    
    GLuint textureBufferId = self.pacmanSprite.textureInfo.name;
    glDeleteTextures(1, &textureBufferId);
    
    self.baseEffect = nil;
    self.context = nil;
    [EAGLContext setCurrentContext:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

#pragma mark - GLKViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    //NSLog(@"drawInRect %@", view);
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);
    
    //[self.mapSprite render];
    [self.pacmanSprite render];
    for (BaseMapSprite *mapSprite in self.mapSpriteArray) {
        [mapSprite render];
    }
    for (BaseSprite * sprite in self.children) {
        [sprite render];
    }
}

- (void)update {
    //NSLog(@"TimeSinceLastUpdate %f", self.timeSinceLastUpdate);
    [self.pacmanSprite update];
    
    self.timeSinceLastSpawn += self.timeSinceLastUpdate;
    if (self.timeSinceLastSpawn > 1.0) {
        self.timeSinceLastSpawn = 0;
        //[self addGhost];
    }
    
    for (BaseSprite * sprite in self.children) {
        [sprite update];
    }
}

@end
