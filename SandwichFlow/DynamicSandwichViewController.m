//
//  DynamicSandwichViewController.m
//  SandwichFlow
//
//  Created by Fangzhou Lu on 9/28/13.
//  Copyright (c) 2013 Colin Eberhardt. All rights reserved.
//

#import "DynamicSandwichViewController.h"
#import "SandwichViewController.h"
#import "AppDelegate.h"

@interface DynamicSandwichViewController ()<UICollisionBehaviorDelegate>

@end

@implementation DynamicSandwichViewController{
    NSMutableArray *_views;
    UIGravityBehavior *_gravity;
    UIDynamicAnimator *_animator;
    CGPoint _previousTouchPoint;
    BOOL _draggingView;
    UISnapBehavior *_snap;
    BOOL _viewDocked;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
//    // Background image
//    UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Background-LowerLayer.png"]];
//    [self.view addSubview:backgroundImageView];
//    
//    //header logo
//    UIImageView* header = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Sarnie.png"]];
//    header.center = CGPointMake(220, 190);
//    [self.view addSubview:header];
    
    // 1. add the lower background layer
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Background-LowerLayer.png"]];
    backgroundImageView.frame = CGRectInset(self.view.frame, -20.0f, -20.0f);
    [self.view addSubview:backgroundImageView];
    [self addMOtionEffectToView:backgroundImageView magnitude:80.0f];
    
    // 2. add the background mid layer
    UIImageView *backgroundImageView2 = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Background-MidLayer.png" ]];
    [self.view addSubview:backgroundImageView2];
    
    // 3. add the foreground image
    UIImageView *header = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Sarnie.png"]];
    header.center = CGPointMake(160, 150);
    [self.view addSubview:header];
    [self addMOtionEffectToView:header magnitude:-40.0f];
    
    _animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    _gravity = [[UIGravityBehavior alloc] init];
    [_animator addBehavior:_gravity];
    _gravity.magnitude = 4.0f;
    
    _views = [NSMutableArray new];
    float offset = 250.0f;
    for (NSDictionary *sandwich in [self sandwiches]) {
        [_views addObject:[self addRecipeAtOffset:offset forSandwich:sandwich]];
        offset -= 50.0f;
    }
}

- (void)addMOtionEffectToView:(UIView *)view magnitude:(float)magnitude
{
    UIInterpolatingMotionEffect *xMotion =
    [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x"
                                                    type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    xMotion.minimumRelativeValue = @(-magnitude);
    xMotion.maximumRelativeValue = @(magnitude);
    
    UIInterpolatingMotionEffect *yMotion =
    [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y"
                                                    type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    yMotion.minimumRelativeValue = @(-magnitude);
    yMotion.maximumRelativeValue = @(magnitude);
    
    UIMotionEffectGroup *group = [[UIMotionEffectGroup alloc] init];
    group.motionEffects = @[xMotion, yMotion];
    
    [view addMotionEffect:group];
    
}

- (NSArray *)sandwiches
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    return  appDelegate.sandwiches;
}

- (UIView *)addRecipeAtOffset:(float)offset forSandwich:(NSDictionary *)sandwich
{
    CGRect frameForView = CGRectOffset(self.view.bounds, 0.0, self.view.bounds.size.height - offset);
    
    // 1. Create the view controller
    UIStoryboard *mystroryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    SandwichViewController *viewController = [mystroryboard instantiateViewControllerWithIdentifier:@"SandwichVC"];
    
    // 2. Set the frame and provide some data
    UIView *view = viewController.view;
    view.frame = frameForView;
    viewController.sandwich = sandwich;
    
    // 3. add as a child
    [self addChildViewController:viewController];
    [self.view addSubview:view];
    [viewController didMoveToParentViewController:self];
    
    // 4. Add a gesture recognizer
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [viewController.view addGestureRecognizer:pan];
    
    // 5. Create a collision
    UICollisionBehavior *collision = [[UICollisionBehavior alloc] initWithItems:@[view]];
    [_animator addBehavior:collision];
    
    // 6. lower boundary, where the tab rests.
    float boundary = view.frame.origin.y + view.frame.size.height + 1;
    CGPoint boundaryStart = CGPointMake(0.0, boundary);
    CGPoint boundaryEnd = CGPointMake(self.view.bounds.size.width, boundary);
    [collision addBoundaryWithIdentifier:@1 fromPoint:boundaryStart toPoint:boundaryEnd];
    
    boundaryStart = CGPointMake(0.0, 0.0);
    boundaryEnd = CGPointMake(self.view.bounds.size.width, 0.0);
    [collision addBoundaryWithIdentifier:@2 fromPoint:boundaryStart toPoint:boundaryEnd];
    collision.collisionDelegate = self;
    
    
    // 7. apply some gravity
    [_gravity addItem:view];
    
    UIDynamicItemBehavior *itemBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[view]];
    [_animator addBehavior:itemBehavior];
    
    return view;
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture
{
    CGPoint touchPoint = [gesture locationInView:self.view];
    UIView *draggedView = gesture.view;
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        CGPoint dragStartLocation = [gesture locationInView:draggedView];
        if (dragStartLocation.y < 200.0f) {
            _draggingView = YES;
            _previousTouchPoint = touchPoint;
        }
    }else if (gesture.state == UIGestureRecognizerStateChanged && _draggingView) {
        float yOffset = _previousTouchPoint.y - touchPoint.y;
        gesture.view.center = CGPointMake(draggedView.center.x, draggedView.center.y - yOffset);
        _previousTouchPoint = touchPoint;
    } else if (gesture.state == UIGestureRecognizerStateEnded && _draggingView) {
        [self tryDockView:draggedView];
        [self addVelocityToView:draggedView fromGesture:gesture];
        [_animator updateItemUsingCurrentState:draggedView];
        _draggingView = NO;
    }
}

- (UIDynamicItemBehavior *)itemBehaviourForView:(UIView *)view
{
    for (UIDynamicItemBehavior *behaviour in _animator.behaviors) {
        if (behaviour.class == [UIDynamicItemBehavior class] && [behaviour.items firstObject] == view) {
            return behaviour;
        }
    }
    return nil;
}

- (void)addVelocityToView:(UIView *)view fromGesture:gesture
{
    CGPoint vel = [gesture velocityInView:self.view];
    vel.x = 0;
    UIDynamicItemBehavior *behaviour = [self itemBehaviourForView:view];
    [behaviour addLinearVelocity:vel forItem:view];
}

- (void)tryDockView:(UIView *)view
{
    BOOL viewHasReachedDockLocation = view.frame.origin.y < 100.0;
    if (viewHasReachedDockLocation) {
        if (!_viewDocked) {
            _snap = [[UISnapBehavior alloc] initWithItem:view snapToPoint:self.view.center];
            [_animator addBehavior:_snap];
            [self setAlphaWhenViewDocked:view alpha:0.0];
            _viewDocked = YES;
        }
    } else {
        if (_viewDocked) {
            [_animator removeBehavior:_snap];
            [self setAlphaWhenViewDocked:view alpha:1.0];
            _viewDocked = NO;
        }
    }
}

- (void)setAlphaWhenViewDocked:(UIView *)view alpha:(CGFloat)alpha
{
    for (UIView *aView in _views) {
        if (aView != view) {
            aView.alpha = alpha;
        }
    }
}

- (void)collisionBehavior:(UICollisionBehavior *)behavior
      beganContactForItem:(id<UIDynamicItem>)item
   withBoundaryIdentifier:(id<NSCopying>)identifier
                  atPoint:(CGPoint)p
{
    if ([@2 isEqual:identifier]) {
        UIView *view = (UIView *)item;
        [self tryDockView:view];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
