//
//  VibeOrbitView.m — Vibe orbiting spheres
//

#import "WebSaverView.h"

@interface VibeOrbitView () {
    NSSlider *countSlider;
    NSTextField *countLabel;
    NSSlider *speedSlider;
    NSTextField *speedLabel;
    NSSlider *spreadSlider;
    NSTextField *spreadLabel;
}
@end

@implementation VibeOrbitView

- (CGFloat)configSheetHeight { return 300; }

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

    // Spread
    [content addSubview:[self labelAt:NSMakeRect(10, y, 110, 20) text:@"Spread:" alignment:NSTextAlignmentRight]];
    spreadSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(125, y - 3, 160, 20)];
    [spreadSlider setMinValue:5]; [spreadSlider setMaxValue:20]; [spreadSlider setNumberOfTickMarks:16];
    [spreadSlider setTarget:self]; [spreadSlider setAction:@selector(sliderChanged:)];
    [content addSubview:spreadSlider];
    spreadLabel = [self valueLabelAt:NSMakeRect(290, y, 70, 20)];
    [content addSubview:spreadLabel];
    y -= 32;

    // Speed
    [content addSubview:[self labelAt:NSMakeRect(10, y, 110, 20) text:@"Speed:" alignment:NSTextAlignmentRight]];
    speedSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(125, y - 3, 160, 20)];
    [speedSlider setMinValue:1]; [speedSlider setMaxValue:20]; [speedSlider setNumberOfTickMarks:20];
    [speedSlider setTarget:self]; [speedSlider setAction:@selector(sliderChanged:)];
    [content addSubview:speedSlider];
    speedLabel = [self valueLabelAt:NSMakeRect(290, y, 70, 20)];
    [content addSubview:speedLabel];
    y -= 45;
}

- (void)loadDefaultsIntoSheet {
    ScreenSaverDefaults *defaults = [self defaults];
    [defaults registerDefaults:@{@"count":@200, @"speed":@10, @"spread":@10}];
    [countSlider setIntegerValue:[defaults integerForKey:@"count"]];
    [speedSlider setIntegerValue:[defaults integerForKey:@"speed"]];
    [spreadSlider setIntegerValue:[defaults integerForKey:@"spread"]];
    [self updateValueLabels];
}

- (void)saveConfigSheet {
    ScreenSaverDefaults *defaults = [self defaults];
    [defaults setInteger:[countSlider integerValue] forKey:@"count"];
    [defaults setInteger:[speedSlider integerValue] forKey:@"speed"];
    [defaults setInteger:[spreadSlider integerValue] forKey:@"spread"];
    [defaults synchronize];
}

- (NSString*)settingsJS {
    ScreenSaverDefaults *defaults = [self defaults];
    return [NSString stringWithFormat:
        @"if (window.applySettings) applySettings({count:%ld, speed:%ld, spread:%ld});",
        [defaults integerForKey:@"count"],
        [defaults integerForKey:@"speed"],
        [defaults integerForKey:@"spread"]];
}

- (void)updateValueLabels {
    if (countSlider) [countLabel setStringValue:[NSString stringWithFormat:@"%ld", [countSlider integerValue]]];
    if (speedSlider) [speedLabel setStringValue:[NSString stringWithFormat:@"%ld", [speedSlider integerValue]]];
    if (spreadSlider) [spreadLabel setStringValue:[NSString stringWithFormat:@"%ld", [spreadSlider integerValue]]];
}

- (void)releaseControls {
    countSlider = nil; countLabel = nil;
    speedSlider = nil; speedLabel = nil;
    spreadSlider = nil; spreadLabel = nil;
    [super releaseControls];
}

@end
