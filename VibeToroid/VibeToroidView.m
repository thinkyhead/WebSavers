//
//  VibeToroidView.m — Vibe toroid morphing shapes
//

#import "WebSaverView.h"

@interface VibeToroidView () {
    NSPopUpButton *shapePopup;
    NSSlider *particleCountSlider;
    NSTextField *particleCountLabel;
    NSSlider *speedSlider;
    NSTextField *speedLabel;
    NSSlider *morphIntervalSlider;
    NSTextField *morphIntervalLabel;
}
@end

@implementation VibeToroidView

- (CGFloat)configSheetHeight { return 320; }

- (void)buildConfigSheet {
    NSView *content = [configSheet contentView];
    CGFloat y = [self configSheetHeight] - 30;

    // Shape
    [content addSubview:[self labelAt:NSMakeRect(10, y, 110, 20) text:@"Shape:" alignment:NSTextAlignmentRight]];
    shapePopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(125, y - 3, 240, 25) pullsDown:NO];
    [shapePopup addItemsWithTitles:@[@"Trefoil (2,3)", @"Cinquefoil (3,5)", @"Twisted (5,7)", @"Loose (2,5)", @"Complex (3,4)", @"Branching (4,7)", @"Loose (2,7)", @"Tight (5,9)", @"Turbine (3,7)"]];
    [content addSubview:shapePopup];
    y -= 35;

    // Morph interval
    [content addSubview:[self labelAt:NSMakeRect(10, y, 110, 20) text:@"Morph every:" alignment:NSTextAlignmentRight]];
    morphIntervalSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(125, y - 3, 160, 20)];
    [morphIntervalSlider setMinValue:2]; [morphIntervalSlider setMaxValue:20]; [morphIntervalSlider setNumberOfTickMarks:19];
    [morphIntervalSlider setTarget:self]; [morphIntervalSlider setAction:@selector(sliderChanged:)];
    [content addSubview:morphIntervalSlider];
    morphIntervalLabel = [self valueLabelAt:NSMakeRect(290, y, 70, 20)];
    [content addSubview:morphIntervalLabel];
    y -= 32;

    // Particle count
    [content addSubview:[self labelAt:NSMakeRect(10, y, 110, 20) text:@"Particles:" alignment:NSTextAlignmentRight]];
    particleCountSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(125, y - 3, 160, 20)];
    [particleCountSlider setMinValue:1000]; [particleCountSlider setMaxValue:10000]; [particleCountSlider setNumberOfTickMarks:10];
    [particleCountSlider setTarget:self]; [particleCountSlider setAction:@selector(sliderChanged:)];
    [content addSubview:particleCountSlider];
    particleCountLabel = [self valueLabelAt:NSMakeRect(290, y, 70, 20)];
    [content addSubview:particleCountLabel];
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
    [defaults registerDefaults:@{@"shape":@0, @"particleCount":@5000, @"speed":@10, @"morphInterval":@8}];
    [shapePopup selectItemAtIndex:[defaults integerForKey:@"shape"]];
    [particleCountSlider setIntegerValue:[defaults integerForKey:@"particleCount"]];
    [speedSlider setIntegerValue:[defaults integerForKey:@"speed"]];
    [morphIntervalSlider setIntegerValue:[defaults integerForKey:@"morphInterval"]];
    [self updateValueLabels];
}

- (void)saveConfigSheet {
    ScreenSaverDefaults *defaults = [self defaults];
    [defaults setInteger:[shapePopup indexOfSelectedItem] forKey:@"shape"];
    [defaults setInteger:[particleCountSlider integerValue] forKey:@"particleCount"];
    [defaults setInteger:[speedSlider integerValue] forKey:@"speed"];
    [defaults setInteger:[morphIntervalSlider integerValue] forKey:@"morphInterval"];
    [defaults synchronize];
}

- (NSString*)settingsJS {
    ScreenSaverDefaults *defaults = [self defaults];
    return [NSString stringWithFormat:
        @"if (window.applySettings) applySettings({shapeIndex:%ld, particles:%ld, speed:%ld, morphInterval:%ld});",
        [defaults integerForKey:@"shape"],
        [defaults integerForKey:@"particleCount"],
        [defaults integerForKey:@"speed"],
        [defaults integerForKey:@"morphInterval"]];
}

- (void)updateValueLabels {
    if (particleCountSlider) [particleCountLabel setStringValue:[NSString stringWithFormat:@"%ld", [particleCountSlider integerValue]]];
    if (speedSlider) [speedLabel setStringValue:[NSString stringWithFormat:@"%ld", [speedSlider integerValue]]];
    if (morphIntervalSlider) [morphIntervalLabel setStringValue:[NSString stringWithFormat:@"%ld s", [morphIntervalSlider integerValue]]];
}

- (void)releaseControls {
    shapePopup = nil;
    particleCountSlider = nil; particleCountLabel = nil;
    speedSlider = nil; speedLabel = nil;
    morphIntervalSlider = nil; morphIntervalLabel = nil;
    [super releaseControls];
}

@end
