//
//  StringyView.m — Stringy 3D strings
//

#import "WebSaverView.h"

@interface StringyView () {
    NSSlider *fpsSlider;
    NSTextField *fpsLabel;
    NSSlider *trailCountSlider;
    NSTextField *trailCountLabel;
    NSSlider *trailLengthSlider;
    NSTextField *trailLengthLabel;
}
@end

@implementation StringyView

- (CGFloat)configSheetHeight { return 280; }

- (void)buildConfigSheet {
    NSView *content = [configSheet contentView];
    CGFloat y = [self configSheetHeight] - 30;

    // FPS
    [content addSubview:[self labelAt:NSMakeRect(10, y, 110, 20) text:@"FPS:" alignment:NSTextAlignmentRight]];
    fpsSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(125, y - 3, 160, 20)];
    [fpsSlider setMinValue:10]; [fpsSlider setMaxValue:60]; [fpsSlider setNumberOfTickMarks:11];
    [fpsSlider setTarget:self]; [fpsSlider setAction:@selector(sliderChanged:)];
    [content addSubview:fpsSlider];
    fpsLabel = [self valueLabelAt:NSMakeRect(290, y, 70, 20)];
    [content addSubview:fpsLabel];
    y -= 32;

    // Trail count
    [content addSubview:[self labelAt:NSMakeRect(10, y, 110, 20) text:@"Trails:" alignment:NSTextAlignmentRight]];
    trailCountSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(125, y - 3, 160, 20)];
    [trailCountSlider setMinValue:3]; [trailCountSlider setMaxValue:30]; [trailCountSlider setNumberOfTickMarks:14];
    [trailCountSlider setTarget:self]; [trailCountSlider setAction:@selector(sliderChanged:)];
    [content addSubview:trailCountSlider];
    trailCountLabel = [self valueLabelAt:NSMakeRect(290, y, 70, 20)];
    [content addSubview:trailCountLabel];
    y -= 32;

    // Trail length
    [content addSubview:[self labelAt:NSMakeRect(10, y, 110, 20) text:@"Trail length:" alignment:NSTextAlignmentRight]];
    trailLengthSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(125, y - 3, 160, 20)];
    [trailLengthSlider setMinValue:3]; [trailLengthSlider setMaxValue:20]; [trailLengthSlider setNumberOfTickMarks:18];
    [trailLengthSlider setTarget:self]; [trailLengthSlider setAction:@selector(sliderChanged:)];
    [content addSubview:trailLengthSlider];
    trailLengthLabel = [self valueLabelAt:NSMakeRect(290, y, 70, 20)];
    [content addSubview:trailLengthLabel];
    y -= 45;
}

- (void)loadDefaultsIntoSheet {
    ScreenSaverDefaults *defaults = [self defaults];
    [defaults registerDefaults:@{@"fps":@30, @"trailCount":@10, @"trailLength":@10}];
    [fpsSlider setIntegerValue:[defaults integerForKey:@"fps"]];
    [trailCountSlider setIntegerValue:[defaults integerForKey:@"trailCount"]];
    [trailLengthSlider setIntegerValue:[defaults integerForKey:@"trailLength"]];
    [self updateValueLabels];
}

- (void)saveConfigSheet {
    ScreenSaverDefaults *defaults = [self defaults];
    [defaults setInteger:[fpsSlider integerValue] forKey:@"fps"];
    [defaults setInteger:[trailCountSlider integerValue] forKey:@"trailCount"];
    [defaults setInteger:[trailLengthSlider integerValue] forKey:@"trailLength"];
    [defaults synchronize];
}

- (NSString*)settingsJS {
    ScreenSaverDefaults *defaults = [self defaults];
    return [NSString stringWithFormat:
        @"if (window.applySettings) applySettings({fps:%ld, trailCount:%ld, trailLength:%ld});",
        [defaults integerForKey:@"fps"],
        [defaults integerForKey:@"trailCount"],
        [defaults integerForKey:@"trailLength"]];
}

- (void)updateValueLabels {
    if (fpsSlider) [fpsLabel setStringValue:[NSString stringWithFormat:@"%ld FPS", [fpsSlider integerValue]]];
    if (trailCountSlider) [trailCountLabel setStringValue:[NSString stringWithFormat:@"%ld", [trailCountSlider integerValue]]];
    if (trailLengthSlider) [trailLengthLabel setStringValue:[NSString stringWithFormat:@"%ld", [trailLengthSlider integerValue]]];
}

- (void)releaseControls {
    fpsSlider = nil; fpsLabel = nil;
    trailCountSlider = nil; trailCountLabel = nil;
    trailLengthSlider = nil; trailLengthLabel = nil;
    [super releaseControls];
}

@end
