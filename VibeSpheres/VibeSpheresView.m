//
//  VibeSpheresView.m — Vibe spheres with starfield
//

#import "WebSaverView.h"

@interface VibeSpheresView () {
    NSSlider *countSlider;
    NSTextField *countLabel;
    NSSlider *starFieldSlider;
    NSTextField *starFieldLabel;
    NSSlider *speedSlider;
    NSTextField *speedLabel;
    NSSlider *colorCycleSlider;
    NSTextField *colorCycleLabel;
}
@end

@implementation VibeSpheresView

- (CGFloat)configSheetHeight { return 320; }

- (void)buildConfigSheet {
    NSView *content = [configSheet contentView];
    CGFloat y = [self configSheetHeight] - 30;

    // Sphere count
    [content addSubview:[self labelAt:NSMakeRect(10, y, 110, 20) text:@"Spheres:" alignment:NSTextAlignmentRight]];
    countSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(125, y - 3, 160, 20)];
    [countSlider setMinValue:50]; [countSlider setMaxValue:500]; [countSlider setNumberOfTickMarks:10];
    [countSlider setTarget:self]; [countSlider setAction:@selector(sliderChanged:)];
    [content addSubview:countSlider];
    countLabel = [self valueLabelAt:NSMakeRect(290, y, 70, 20)];
    [content addSubview:countLabel];
    y -= 32;

    // Star count
    [content addSubview:[self labelAt:NSMakeRect(10, y, 110, 20) text:@"Stars:" alignment:NSTextAlignmentRight]];
    starFieldSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(125, y - 3, 160, 20)];
    [starFieldSlider setMinValue:500]; [starFieldSlider setMaxValue:8000]; [starFieldSlider setNumberOfTickMarks:16];
    [starFieldSlider setTarget:self]; [starFieldSlider setAction:@selector(sliderChanged:)];
    [content addSubview:starFieldSlider];
    starFieldLabel = [self valueLabelAt:NSMakeRect(290, y, 70, 20)];
    [content addSubview:starFieldLabel];
    y -= 32;

    // Speed
    [content addSubview:[self labelAt:NSMakeRect(10, y, 110, 20) text:@"Speed:" alignment:NSTextAlignmentRight]];
    speedSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(125, y - 3, 160, 20)];
    [speedSlider setMinValue:1]; [speedSlider setMaxValue:20]; [speedSlider setNumberOfTickMarks:20];
    [speedSlider setTarget:self]; [speedSlider setAction:@selector(sliderChanged:)];
    [content addSubview:speedSlider];
    speedLabel = [self valueLabelAt:NSMakeRect(290, y, 70, 20)];
    [content addSubview:speedLabel];
    y -= 32;

    // Color cycle
    [content addSubview:[self labelAt:NSMakeRect(10, y, 110, 20) text:@"Color cycle:" alignment:NSTextAlignmentRight]];
    colorCycleSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(125, y - 3, 160, 20)];
    [colorCycleSlider setMinValue:1]; [colorCycleSlider setMaxValue:20]; [colorCycleSlider setNumberOfTickMarks:20];
    [colorCycleSlider setTarget:self]; [colorCycleSlider setAction:@selector(sliderChanged:)];
    [content addSubview:colorCycleSlider];
    colorCycleLabel = [self valueLabelAt:NSMakeRect(290, y, 70, 20)];
    [content addSubview:colorCycleLabel];
    y -= 45;
}

- (void)loadDefaultsIntoSheet {
    ScreenSaverDefaults *defaults = [self defaults];
    [defaults registerDefaults:@{@"sphereCount":@200, @"starCount":@3000, @"speed":@5, @"colorCycle":@5}];
    [countSlider setIntegerValue:[defaults integerForKey:@"sphereCount"]];
    [starFieldSlider setIntegerValue:[defaults integerForKey:@"starCount"]];
    [speedSlider setIntegerValue:[defaults integerForKey:@"speed"]];
    [colorCycleSlider setIntegerValue:[defaults integerForKey:@"colorCycle"]];
    [self updateValueLabels];
}

- (void)saveConfigSheet {
    ScreenSaverDefaults *defaults = [self defaults];
    [defaults setInteger:[countSlider integerValue] forKey:@"sphereCount"];
    [defaults setInteger:[starFieldSlider integerValue] forKey:@"starCount"];
    [defaults setInteger:[speedSlider integerValue] forKey:@"speed"];
    [defaults setInteger:[colorCycleSlider integerValue] forKey:@"colorCycle"];
    [defaults synchronize];
}

- (NSString*)settingsJS {
    ScreenSaverDefaults *defaults = [self defaults];
    return [NSString stringWithFormat:
        @"if (window.applySettings) applySettings({sphereCount:%ld, starCount:%ld, speed:%ld, colorCycle:%ld});",
        [defaults integerForKey:@"sphereCount"],
        [defaults integerForKey:@"starCount"],
        [defaults integerForKey:@"speed"],
        [defaults integerForKey:@"colorCycle"]];
}

- (void)updateValueLabels {
    if (countSlider) [countLabel setStringValue:[NSString stringWithFormat:@"%ld", [countSlider integerValue]]];
    if (starFieldSlider) [starFieldLabel setStringValue:[NSString stringWithFormat:@"%ld", [starFieldSlider integerValue]]];
    if (speedSlider) [speedLabel setStringValue:[NSString stringWithFormat:@"%ld", [speedSlider integerValue]]];
    if (colorCycleSlider) [colorCycleLabel setStringValue:[NSString stringWithFormat:@"%.1f", [colorCycleSlider floatValue]]];
}

- (void)releaseControls {
    countSlider = nil; countLabel = nil;
    starFieldSlider = nil; starFieldLabel = nil;
    speedSlider = nil; speedLabel = nil;
    colorCycleSlider = nil; colorCycleLabel = nil;
    [super releaseControls];
}

@end
