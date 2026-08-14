//
//  StarfieldView.m — Starfield animation
//

#import "WebSaverView.h"

@interface StarfieldView () {
    NSSlider *starCountSlider;
    NSTextField *starCountLabel;
    NSSlider *speedSlider;
    NSTextField *speedLabel;
}
@end

@implementation StarfieldView

- (CGFloat)configSheetHeight { return 280; }

- (void)buildConfigSheet {
    NSView *content = [configSheet contentView];
    CGFloat y = [self configSheetHeight] - 30;

    // Star count
    [content addSubview:[self labelAt:NSMakeRect(10, y, 110, 20) text:@"Star count:" alignment:NSTextAlignmentRight]];
    starCountSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(125, y - 3, 160, 20)];
    [starCountSlider setMinValue:1000]; [starCountSlider setMaxValue:10000]; [starCountSlider setNumberOfTickMarks:10];
    [starCountSlider setTarget:self]; [starCountSlider setAction:@selector(sliderChanged:)];
    [content addSubview:starCountSlider];
    starCountLabel = [self valueLabelAt:NSMakeRect(290, y, 70, 20)];
    [content addSubview:starCountLabel];
    y -= 32;

    // Speed
    [content addSubview:[self labelAt:NSMakeRect(10, y, 110, 20) text:@"Speed:" alignment:NSTextAlignmentRight]];
    speedSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(125, y - 3, 160, 20)];
    [speedSlider setMinValue:1]; [speedSlider setMaxValue:10]; [speedSlider setNumberOfTickMarks:10];
    [speedSlider setTarget:self]; [speedSlider setAction:@selector(sliderChanged:)];
    [content addSubview:speedSlider];
    speedLabel = [self valueLabelAt:NSMakeRect(290, y, 70, 20)];
    [content addSubview:speedLabel];
    y -= 45;
}

- (void)loadDefaultsIntoSheet {
    ScreenSaverDefaults *defaults = [self defaults];
    [defaults registerDefaults:@{@"starCount":@6000, @"speed":@7}];
    [starCountSlider setIntegerValue:[defaults integerForKey:@"starCount"]];
    [speedSlider setFloatValue:[defaults floatForKey:@"speed"]];
    [self updateValueLabels];
}

- (void)saveConfigSheet {
    ScreenSaverDefaults *defaults = [self defaults];
    [defaults setInteger:[starCountSlider integerValue] forKey:@"starCount"];
    [defaults setFloat:[speedSlider floatValue] forKey:@"speed"];
    [defaults synchronize];
}

- (NSString*)settingsJS {
    ScreenSaverDefaults *defaults = [self defaults];
    return [NSString stringWithFormat:
        @"if (window.applySettings) applySettings({starCount:%ld, speed:%.1f});",
        [defaults integerForKey:@"starCount"],
        [defaults floatForKey:@"speed"]];
}

- (void)updateValueLabels {
    if (starCountSlider) [starCountLabel setStringValue:[NSString stringWithFormat:@"%ld", [starCountSlider integerValue]]];
    if (speedSlider) [speedLabel setStringValue:[NSString stringWithFormat:@"%.1f", [speedSlider floatValue]]];
}

- (void)releaseControls {
    starCountSlider = nil; starCountLabel = nil;
    speedSlider = nil; speedLabel = nil;
    [super releaseControls];
}

@end
