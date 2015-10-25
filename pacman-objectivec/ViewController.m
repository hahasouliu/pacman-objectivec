//
//  ViewController.m
//  pacman-objectivec
//
//  Created by hahasouliu on 10/14/15.
//  Copyright © 2015 hahasouliu. All rights reserved.
//

#import "ViewController.h"
#import "BaseSprite.h"
#import "BaseMapSprite.h"

#define SPRITE_PATH_ROW 13
#define SPRITE_PATH_COL 8
#define SPRITE_SIZE 30
#define MAP_SPRITE_SHORT_SIDE (10.0f)
#define MAP_SPRITE_LONG_SIDE  (50.0f) // LONG_SIDE = SPRITE_SIZE + SHORT_SIDE*2

int VERTICAL_MAP_SPRITES[]   = {2, 1, 4, 1, 6, 1, 1, 2, 7, 2,
                            4, 3, 1, 4, 2, 4, 6, 4 ,7, 4,
                            1, 5, 2, 5, 3, 5, 5, 5, 6, 5,
                            7, 5, 3, 6, 5, 6, 1, 7, 2, 7,
                            6, 7, 7, 7, 1, 8, 2, 8, 4, 8,
                            6, 8, 7, 8, 1, 10, 3, 10, 4, 10,
                            5, 10, 7, 10, 1, 11, 3, 11, 4, 11,
                            5, 11, 7, 11};
int HORIZONTAL_MAP_SPRITES[] = {1, 1, 2, 1, 5, 1, 6, 1, 3, 2,
                            4, 2, 1, 3, 2, 3, 5, 3, 6, 3,
                            3, 4, 4, 4, 3, 5, 4, 5, 3, 7,
                            4, 7, 2, 8, 5, 8, 3, 9, 4, 9,
                            1, 10, 2, 10, 5, 10, 6, 10, 1,
                            12, 2, 12, 5, 12, 6, 12};

@interface ViewController ()
@property (assign) float screenWidth;
@property (assign) float screenHeight;
@property (assign) int mapLeftMargin;
@property (assign) int mapRightMargin;
@property (assign) int mapTopMargin;
@property (assign) int mapBottomMargin;
@property (assign) float timeSinceLastSpawn;
@property (assign) bool isTouchStart;
@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic, strong) GLKBaseEffect *baseEffect;
@property (nonatomic, strong) GLKBaseEffect * mapEffect;
@property (nonatomic, strong) BaseSprite *pacmanSprite;
@property (strong) NSMutableArray * children;
@property (strong) NSMutableArray * mapSpriteArray;
@property (assign) CGPoint touchStartPoint;
@property (assign) CGPoint touchEndPoint;
@property (nonatomic, weak) IBOutlet UILabel *labelTest;
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
@synthesize labelTest = _labelTest;


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


    // init margin values
    // x-shift for map sprites
    self.mapLeftMargin = (self.screenWidth - SPRITE_PATH_COL * SPRITE_SIZE
                                           - (SPRITE_PATH_COL-1) * MAP_SPRITE_SHORT_SIDE)
                                           / 2;
    // for right wall position
    self.mapRightMargin = self.mapLeftMargin;
    // for top wall position
    self.mapTopMargin = MAP_SPRITE_SHORT_SIDE;
    // y-shift for map sprites
    self.mapBottomMargin = self.screenHeight - SPRITE_PATH_ROW * SPRITE_SIZE
                            - SPRITE_PATH_ROW * MAP_SPRITE_SHORT_SIDE;
    NSLog(@"mapLeftMargin %d", self.mapLeftMargin);
    NSLog(@"mapRightMargin %d", self.mapRightMargin);
    NSLog(@"mapTopMargin %d", self.mapTopMargin);
    NSLog(@"mapBottomMargin %d", self.mapBottomMargin);
    
    // setup pacman
    self.pacmanSprite = [[BaseSprite alloc] initWithFile:@"pacman-2.png" effect:self.baseEffect];
    self.pacmanSprite.position = GLKVector2Make(self.mapLeftMargin, self.mapBottomMargin);
    [self.pacmanSprite setMoveBoundary:self.screenWidth boundaryY:self.screenHeight];
    
    // setup map
    [self initMap];
    
    // gesture recognize
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
    
    // label
    self.labelTest.text = @"Score";
    UIView *viewTest = self.labelTest;
    [_labelTest setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    NSMutableArray *myConstraints = [NSMutableArray array];
    [myConstraints addObjectsFromArray:
     [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[viewTest(64)]"
                                             options:NSLayoutFormatDirectionLeadingToTrailing
                                             metrics:nil
                                               views:NSDictionaryOfVariableBindings(viewTest)]];
    [myConstraints addObjectsFromArray:
         [NSLayoutConstraint constraintsWithVisualFormat:@"V:[viewTest(32)]-|"
                                             options:NSLayoutFormatDirectionLeadingToTrailing
                                             metrics:nil
                                             views:NSDictionaryOfVariableBindings(viewTest)]];
    [self.view addConstraints:myConstraints];

/*
    NSLayoutConstraint *myConstraint;
    [_labelTest setTranslatesAutoresizingMaskIntoConstraints:NO];
    myConstraint = [NSLayoutConstraint constraintWithItem:_labelTest attribute:NSLayoutAttributeBottom
                                                relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                   toItem:[_labelTest superview] attribute:NSLayoutAttributeBottom
                                               multiplier:1.0f constant:-50.0f];
    [self.view addConstraint:myConstraint];
    
    myConstraint = [NSLayoutConstraint constraintWithItem:_labelTest attribute:NSLayoutAttributeWidth
                                                relatedBy:NSLayoutRelationEqual
                                                   toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                               multiplier:1.0f constant:210.0f];
    [self.view addConstraint:myConstraint];
    
    //高度限制
    myConstraint = [NSLayoutConstraint constraintWithItem:_labelTest attribute:NSLayoutAttributeHeight
                                                relatedBy:NSLayoutRelationEqual
                                                   toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                               multiplier:1.0f constant:100.0f];
    [self.view addConstraint:myConstraint];
  */

}

- (void)initMap {
    BaseMapSprite *mapSprite;
    
    int verticalSpritesSize = (sizeof(VERTICAL_MAP_SPRITES)/sizeof(int));
    NSLog(@"verticalSpritesSize %d", verticalSpritesSize);
    for (int i = 0 ; i < verticalSpritesSize ; i+=2) {
        mapSprite = [[BaseMapSprite alloc] initWithFile:@"wall-vertical.png" effect:self.baseEffect];
        [mapSprite setSize:MAP_SPRITE_SHORT_SIDE height:MAP_SPRITE_LONG_SIDE];
        int x = self.mapLeftMargin + (VERTICAL_MAP_SPRITES[i] * SPRITE_SIZE)
                                   + ((VERTICAL_MAP_SPRITES[i]-1) * MAP_SPRITE_SHORT_SIDE);
        int y = self.mapBottomMargin + (VERTICAL_MAP_SPRITES[i+1] * SPRITE_SIZE)
                                     + ((VERTICAL_MAP_SPRITES[i+1] - 1) * MAP_SPRITE_SHORT_SIDE);
        mapSprite.position = GLKVector2Make(x, y);
        [self.mapSpriteArray addObject:mapSprite];
    }
    
    int horizontalSpritesSize = (sizeof(HORIZONTAL_MAP_SPRITES)/sizeof(int));
    NSLog(@"verticalSpritesSize %d", horizontalSpritesSize);
    for (int i = 0 ; i < horizontalSpritesSize ; i+=2) {
        mapSprite = [[BaseMapSprite alloc] initWithFile:@"wall-horizontal.png" effect:self.baseEffect];
        [mapSprite setSize:MAP_SPRITE_LONG_SIDE height:MAP_SPRITE_SHORT_SIDE];
        int x = self.mapLeftMargin + (HORIZONTAL_MAP_SPRITES[i] * SPRITE_SIZE)
                                   + ((HORIZONTAL_MAP_SPRITES[i]-1) * MAP_SPRITE_SHORT_SIDE);
        int y = self.mapBottomMargin + (HORIZONTAL_MAP_SPRITES[i+1] * SPRITE_SIZE)
                                     + ((HORIZONTAL_MAP_SPRITES[i+1]-1) * MAP_SPRITE_SHORT_SIDE);
        mapSprite.position = GLKVector2Make(x, y);
        [self.mapSpriteArray addObject:mapSprite];
        
    }
    
    int topBottomWallWidth  = SPRITE_SIZE*(SPRITE_PATH_COL) + MAP_SPRITE_SHORT_SIDE*(SPRITE_PATH_COL+1);
    int rightLeftWallHeight = SPRITE_SIZE*(SPRITE_PATH_ROW) + MAP_SPRITE_SHORT_SIDE*(SPRITE_PATH_ROW+1);
    
    // bottom wall
    mapSprite = [[BaseMapSprite alloc] initWithFile:@"solid-square.png" effect:self.baseEffect];
    [mapSprite setSize:topBottomWallWidth height:MAP_SPRITE_SHORT_SIDE];
    mapSprite.position = GLKVector2Make(self.mapLeftMargin - MAP_SPRITE_SHORT_SIDE,
                                        self.mapBottomMargin - MAP_SPRITE_SHORT_SIDE - 1);
    [self.mapSpriteArray addObject:mapSprite];
    
    // top wall
    mapSprite = [[BaseMapSprite alloc] initWithFile:@"solid-square.png" effect:self.baseEffect];
    [mapSprite setSize:topBottomWallWidth height:MAP_SPRITE_SHORT_SIDE];
    mapSprite.position = GLKVector2Make(self.mapLeftMargin - MAP_SPRITE_SHORT_SIDE, self.screenHeight-MAP_SPRITE_SHORT_SIDE);
    [self.mapSpriteArray addObject:mapSprite];

    // left wall
    mapSprite = [[BaseMapSprite alloc] initWithFile:@"solid-square.png" effect:self.baseEffect];
    [mapSprite setSize:MAP_SPRITE_SHORT_SIDE height:rightLeftWallHeight];
    mapSprite.position = GLKVector2Make(self.mapLeftMargin - MAP_SPRITE_SHORT_SIDE,
                                        self.mapBottomMargin - MAP_SPRITE_SHORT_SIDE - 1);
    [self.mapSpriteArray addObject:mapSprite];
    
    // right wall
    mapSprite = [[BaseMapSprite alloc] initWithFile:@"solid-square.png" effect:self.baseEffect];
    [mapSprite setSize:MAP_SPRITE_SHORT_SIDE height:rightLeftWallHeight];
    mapSprite.position = GLKVector2Make(self.screenWidth - self.mapRightMargin,
                                        self.mapBottomMargin - MAP_SPRITE_SHORT_SIDE - 1);
    [self.mapSpriteArray addObject:mapSprite];
    
    if (self.pacmanSprite) {
        self.pacmanSprite.mapSpriteArray = self.mapSpriteArray;
    } else {
        NSLog(@"initMap before pacman is setup");
    }
}

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
