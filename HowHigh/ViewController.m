//
//  ViewController.m
//  HowHigh
//
//  Created by Cameron Ehrlich on 9/19/14.
//  Copyright (c) 2014 Lucky Bunny LLC. All rights reserved.
//

#import "ViewController.h"
#import <UIView+Positioning.h>
#import <UIColor+Hex.h>
#import <UIView+Shimmer.h>
#import <ReactiveCocoa.h>

@interface ViewController ()

@property (nonatomic, strong) CMAltimeter *altimeter;
@property (nonatomic, assign) double currentMeters;
@property (nonatomic, assign) double unitMultiple;
@property (nonatomic, assign) BOOL isMeasuing;

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) ADBannerView *bannerView;
@property (strong, nonatomic) UIButton *beginMeasuringButton;
@property (strong, nonatomic) UILabel *feedbackLabel;
@property (strong, nonatomic) UILabel *instructionsLabel;
@property (strong, nonatomic) UIPickerView *unitPicker;

@property (strong, nonatomic) IBOutlet UIImageView *backgroundImageView;

@end

@implementation ViewController

- (UIColor *)mainColor
{
    UIColor *mainColor = [[UIColor colorWithHex:0x699fd2] colorWithAlphaComponent:0.95];
    return mainColor;
}

- (UIColor *)secondaryColor
{
    UIColor *mainColor = [[UIColor colorWithHex:0xc0c0c7] colorWithAlphaComponent:1];
    return mainColor;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.backgroundImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    [self.backgroundImageView setImage:[UIImage imageNamed:@"clouds"]];
    [self.backgroundImageView setContentMode:UIViewContentModeScaleAspectFill];

    UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
    UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
    
    [effectView setFrame:self.backgroundImageView.bounds];
    [self.backgroundImageView addSubview:effectView];
    [self.view addSubview:self.backgroundImageView];
    
    self.contentView = [[UIView alloc] initWithFrame:self.view.bounds];
    UIInterpolatingMotionEffect *motionEffectX = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    UIInterpolatingMotionEffect *motionEffectY = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    [motionEffectX setMinimumRelativeValue:@(-10.0)];
    [motionEffectX setMaximumRelativeValue:@(10.0)];
    [motionEffectY setMinimumRelativeValue:@(-10.0)];
    [motionEffectY setMaximumRelativeValue:@(10.0)];
    [self.contentView addMotionEffect:motionEffectX];
    [self.contentView addMotionEffect:motionEffectY];
    [self.view addSubview:self.contentView];

    self.bannerView = [[ADBannerView alloc] initWithAdType:ADAdTypeBanner];
    [self.bannerView setFrame:CGRectMake(0, [[UIApplication sharedApplication] statusBarFrame].size.height, self.view.bounds.size.width, 50)];
    [self.bannerView setDelegate:self];
    [self.bannerView setAlpha:0];
    [self.view addSubview:self.bannerView];
    
    self.instructionsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.bannerView.origin.y + self.bannerView.height + (self.bannerView.height/2), self.view.width, self.bannerView.height)];
    [self.instructionsLabel setTextColor:[self secondaryColor]];
    [self.instructionsLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:37]];
    [self.instructionsLabel setTextAlignment:NSTextAlignmentCenter];
    [self.instructionsLabel setAdjustsFontSizeToFitWidth:YES];
    [self.instructionsLabel setNumberOfLines:3];
    [self.instructionsLabel setShadowColor:[UIColor whiteColor]];
    [self.instructionsLabel setShadowOffset:CGSizeMake(0, 0)];
    [self.instructionsLabel.layer setShadowOpacity:0.2];
    [self.instructionsLabel.layer setShadowRadius:10];
    [self.instructionsLabel setAdjustsFontSizeToFitWidth:YES];
    [self.contentView addSubview:self.instructionsLabel];
    
    self.beginMeasuringButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.beginMeasuringButton setFrame:CGRectMake(0, self.view.bounds.size.height - 70, self.view.bounds.size.width, 50)];
    [self.beginMeasuringButton setTitle:@"Start" forState:UIControlStateNormal];
    [self.beginMeasuringButton.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Bold" size:35]];
    [self.beginMeasuringButton setTitleColor:[self mainColor] forState:UIControlStateNormal];
    [self.beginMeasuringButton setTitleColor:[[self mainColor] colorWithAlphaComponent:0.3] forState:UIControlStateHighlighted];
    [self.beginMeasuringButton setClipsToBounds:NO];
    [self.beginMeasuringButton.layer setMasksToBounds:NO];
    [self.beginMeasuringButton addTarget:self action:@selector(startMeasurement:) forControlEvents:UIControlEventTouchUpInside];
    [self.beginMeasuringButton.titleLabel setShadowColor:[UIColor whiteColor]];
    [self.beginMeasuringButton.titleLabel setShadowOffset:CGSizeMake(0, 0)];
    [self.beginMeasuringButton.titleLabel.layer setShadowOpacity:0.2];
    [self.beginMeasuringButton.titleLabel.layer setShadowRadius:6];
    [self.beginMeasuringButton setEnabled:NO];
    [self.view addSubview:self.beginMeasuringButton];
    
    self.unitPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, self.beginMeasuringButton.frame.origin.y - 200, self.view.bounds.size.width, 200)];
    [self.unitPicker setDelegate:self];
    [self.unitPicker setDataSource:self];
    [self.unitPicker setShowsSelectionIndicator:YES];
    [self.view addSubview:self.unitPicker];
    
    CGFloat labelStartingPoint = self.bannerView.frame.origin.y + self.bannerView.bounds.size.height;
    self.feedbackLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, labelStartingPoint, self.view.bounds.size.width, self.unitPicker.frame.origin.y - self.bannerView.frame.origin.y + self.bannerView.bounds.size.height)];
    [self.feedbackLabel setTextColor:[self mainColor]];
    [self.feedbackLabel setFont:[UIFont fontWithName:@"HelveticaNeue-UltraLight" size:200]];
    [self.feedbackLabel setClipsToBounds:NO];
    [self.feedbackLabel setAdjustsFontSizeToFitWidth:YES];
    [self.feedbackLabel setTextAlignment:NSTextAlignmentCenter];
    [self.feedbackLabel setShadowColor:[UIColor whiteColor]];
    [self.feedbackLabel setShadowOffset:CGSizeMake(0, 0)];
    [self.feedbackLabel.layer setShadowOpacity:0.2];
    [self.feedbackLabel.layer setShadowRadius:10];
    [self.contentView addSubview:self.feedbackLabel];
    
    self.altimeter = [[CMAltimeter alloc] init];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.unitPicker selectRow:1 inComponent:0 animated:NO];
    [self pickerView:self.unitPicker didSelectRow:1 inComponent:0];
    
    [self.instructionsLabel setText:@"HowHigh attempts to measure height \nusing the new built-in Barometer."];
    [self resetFeedbackDisplay];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!self.isMeasuing) {
            [self.beginMeasuringButton setEnabled:YES];
            [self.beginMeasuringButton startShimmering];
            [self.instructionsLabel setText:@"Place device flat on starting surface.\nPress \"Start\" to begin measuring."];
        }
    });
}

- (void)resetFeedbackDisplay
{
    [self.unitPicker selectRow:1 inComponent:0 animated:YES];
    [self.feedbackLabel setText:@"--"];
}

- (void)updateFeedbackDisplay
{
//     Add transition (must be called after myLabel has been displayed)
//    CATransition *animation = [CATransition animation];
//    animation.duration = 0.2;
//    animation.type = kCATransitionFade;
//    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
//    [self.feedbackLabel.layer addAnimation:animation forKey:@"changeTextTransition"];
//    
//    // Change the text
//    self.feedbackLabel.text = [NSString stringWithFormat:@"%.1f", MAX(0, self.currentMeters * self.unitMultiple)];
    self.feedbackLabel.text = [NSString stringWithFormat:@"%.1f", MAX(0, self.currentMeters * self.unitMultiple)];
}

- (IBAction)startMeasurement:(id)sender
{
    if ([CMAltimeter isRelativeAltitudeAvailable]) {
        
        [self.altimeter stopRelativeAltitudeUpdates];

        [self.beginMeasuringButton stopShimmering];
        self.isMeasuing = NO;
        [self.instructionsLabel setText:@"Starting..."];
        [self.beginMeasuringButton setTitle:@"Reset" forState:UIControlStateNormal];
        [self resetFeedbackDisplay];
        
        
        [self.altimeter startRelativeAltitudeUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMAltitudeData *altitudeData, NSError *error) {
            self.isMeasuing = YES;
            [self.instructionsLabel setText:@"Lift your device to measure\nHowHigh it has moved."];
            self.currentMeters = altitudeData.relativeAltitude.doubleValue;
            [self updateFeedbackDisplay];
            
        }];
    }else{
        [self.instructionsLabel setTextColor:[[UIColor redColor] colorWithAlphaComponent:0.35]];
        [self.instructionsLabel setText:@"You must have an iPhone 6 or 6 Plus\nto use this app because it requires\nthe built-in barometer."];
    }
}

#pragma mark -
#pragma mark UIPickerViewDelegate and DataSource
-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    switch (row) {
        case 0:
            return @"Inches";
        case 1:
            return @"Feet";
        case 2:
            return @"Yards";
        default:
            return @"ERROR";
    }
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return 3;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    switch (row) {
        case 0:
            self.unitMultiple = 39.3701;
            break;
        case 1:
            self.unitMultiple = 3.28084;
            break;
        case 2:
            self.unitMultiple = 1.09361;
            break;
        default:
            break;
    }
    
    if (self.isMeasuing) {
        [self updateFeedbackDisplay];
    }
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, pickerView.width, [self pickerView:pickerView rowHeightForComponent:component])];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:40]];
    [label setTextColor:[self secondaryColor]];
    [label setShadowColor:[UIColor whiteColor]];
    [label setShadowOffset:CGSizeMake(0, 0)];
    [label.layer setShadowOpacity:0.2];
    [label.layer setShadowRadius:10];
    [label setText:[self pickerView:pickerView titleForRow:row forComponent:component]];
    return label;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return 50.0;
}

#pragma mark -
#pragma mark ADBannerADViewDelegate
- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    NSLog(@"%s", __FUNCTION__);
    [UIView animateWithDuration:0.5 animations:^{
        [self.bannerView setAlpha:1];
    }];
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    NSLog(@"%s", __FUNCTION__);
    [UIView animateWithDuration:0.5 animations:^{
        [self.bannerView setAlpha:0];
    }];
}


- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end
