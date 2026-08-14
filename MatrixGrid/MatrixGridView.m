//
//  MatrixGridView.m — Matrix grid with CSS animations
//

#import "WebSaverView.h"

@interface MatrixGridView () {
    NSPopUpButton *themePopup;
    NSPopUpButton *overlayPopup;
    NSButton *flipCheckbox;
    NSSlider *fpsSlider;
    NSTextField *fpsLabel;
    NSSlider *changeSlider;
    NSTextField *changeLabel;
    NSButton *alphaCheckbox;
    NSButton *punctuationCheckbox;
    NSSlider *minSpeedSlider;
    NSTextField *minSpeedLabel;
    NSSlider *maxSpeedSlider;
    NSTextField *maxSpeedLabel;
    NSSlider *fadeSlider;
    NSTextField *fadeLabel;
}
@end

@implementation MatrixGridView

- (CGFloat)configSheetHeight { return 400; }

- (void)buildConfigSheet {
    NSView *content = [configSheet contentView];
    CGFloat y = [self configSheetHeight] - 30;

    // Theme
    [content addSubview:[self labelAt:NSMakeRect(10, y, 110, 20) text:@"Theme:" alignment:NSTextAlignmentRight]];
    themePopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(125, y - 3, 240, 25) pullsDown:NO];
    [themePopup addItemsWithTitles:@[@"Green", @"Amber", @"Light", @"Atari 800"]];
    [content addSubview:themePopup];
    y -= 35;

    // Overlay
    [content addSubview:[self labelAt:NSMakeRect(10, y, 110, 20) text:@"Overlay:" alignment:NSTextAlignmentRight]];
    overlayPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(125, y - 3, 240, 25) pullsDown:NO];
    [overlayPopup addItemsWithTitles:@[@"None", @"Scanlines", @"Shadow Mask"]];
    [content addSubview:overlayPopup];
    y -= 35;

    // Flip
    flipCheckbox = [self checkboxAt:NSMakeRect(125, y, 240, 20) title:@"Flip characters"];
    [content addSubview:flipCheckbox];
    y -= 32;

    // FPS
    [content addSubview:[self labelAt:NSMakeRect(10, y, 110, 20) text:@"FPS:" alignment:NSTextAlignmentRight]];
    fpsSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(125, y - 3, 160, 20)];
    [fpsSlider setMinValue:5]; [fpsSlider setMaxValue:60]; [fpsSlider setNumberOfTickMarks:12];
    [fpsSlider setTarget:self]; [fpsSlider setAction:@selector(sliderChanged:)];
    [content addSubview:fpsSlider];
    fpsLabel = [self valueLabelAt:NSMakeRect(290, y, 70, 20)];
    [content addSubview:fpsLabel];
    y -= 32;

    // Random change
    [content addSubview:[self labelAt:NSMakeRect(10, y, 110, 20) text:@"Random change:" alignment:NSTextAlignmentRight]];
    changeSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(125, y - 3, 160, 20)];
    [changeSlider setMinValue:0]; [changeSlider setMaxValue:10]; [changeSlider setNumberOfTickMarks:11];
    [changeSlider setTarget:self]; [changeSlider setAction:@selector(sliderChanged:)];
    [content addSubview:changeSlider];
    changeLabel = [self valueLabelAt:NSMakeRect(290, y, 70, 20)];
    [content addSubview:changeLabel];
    y -= 32;

    // Alpha
    alphaCheckbox = [self checkboxAt:NSMakeRect(125, y, 240, 20) title:@"Include Roman alphabet"];
    [content addSubview:alphaCheckbox];
    y -= 28;

    // Punctuation
    punctuationCheckbox = [self checkboxAt:NSMakeRect(125, y, 240, 20) title:@"Include punctuation"];
    [content addSubview:punctuationCheckbox];
    y -= 32;

    // Min/Max speed
    [content addSubview:[self labelAt:NSMakeRect(10, y, 110, 20) text:@"Min speed:" alignment:NSTextAlignmentRight]];
    minSpeedSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(125, y - 3, 160, 20)];
    [minSpeedSlider setMinValue:0.1]; [minSpeedSlider setMaxValue:1.0];
    [minSpeedSlider setTarget:self]; [minSpeedSlider setAction:@selector(sliderChanged:)];
    [content addSubview:minSpeedSlider];
    minSpeedLabel = [self valueLabelAt:NSMakeRect(290, y, 70, 20)];
    [content addSubview:minSpeedLabel];
    y -= 32;

    [content addSubview:[self labelAt:NSMakeRect(10, y, 110, 20) text:@"Max speed:" alignment:NSTextAlignmentRight]];
    maxSpeedSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(125, y - 3, 160, 20)];
    [maxSpeedSlider setMinValue:0.1]; [maxSpeedSlider setMaxValue:1.0];
    [maxSpeedSlider setTarget:self]; [maxSpeedSlider setAction:@selector(sliderChanged:)];
    [content addSubview:maxSpeedSlider];
    maxSpeedLabel = [self valueLabelAt:NSMakeRect(290, y, 70, 20)];
    [content addSubview:maxSpeedLabel];
    y -= 32;

    // Fade
    [content addSubview:[self labelAt:NSMakeRect(10, y, 110, 20) text:@"Fade time:" alignment:NSTextAlignmentRight]];
    fadeSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(125, y - 3, 160, 20)];
    [fadeSlider setMinValue:1]; [fadeSlider setMaxValue:10]; [fadeSlider setNumberOfTickMarks:10];
    [fadeSlider setTarget:self]; [fadeSlider setAction:@selector(sliderChanged:)];
    [content addSubview:fadeSlider];
    fadeLabel = [self valueLabelAt:NSMakeRect(290, y, 70, 20)];
    [content addSubview:fadeLabel];
    y -= 45;
}

- (void)loadDefaultsIntoSheet {
    ScreenSaverDefaults *defaults = [self defaults];
    [defaults registerDefaults:@{@"theme":@0, @"alpha":@YES, @"punctuation":@NO, @"overlay":@0, @"flip":@YES, @"change":@4, @"fps":@30, @"minspeed":@0.2, @"maxspeed":@1.0, @"fadetime":@3}];
    [themePopup selectItemAtIndex:[defaults integerForKey:@"theme"]];
    [alphaCheckbox setState:[defaults boolForKey:@"alpha"] ? NSControlStateValueOn : NSControlStateValueOff];
    [punctuationCheckbox setState:[defaults boolForKey:@"punctuation"] ? NSControlStateValueOn : NSControlStateValueOff];
    [overlayPopup selectItemAtIndex:[defaults integerForKey:@"overlay"]];
    [flipCheckbox setState:[defaults boolForKey:@"flip"] ? NSControlStateValueOn : NSControlStateValueOff];
    [changeSlider setIntegerValue:[defaults integerForKey:@"change"]];
    [fpsSlider setIntegerValue:[defaults integerForKey:@"fps"]];
    [minSpeedSlider setFloatValue:[defaults floatForKey:@"minspeed"]];
    [maxSpeedSlider setFloatValue:[defaults floatForKey:@"maxspeed"]];
    [fadeSlider setIntegerValue:[defaults integerForKey:@"fadetime"]];
    [self updateValueLabels];
}

- (void)saveConfigSheet {
    ScreenSaverDefaults *defaults = [self defaults];
    [defaults setInteger:[themePopup indexOfSelectedItem] forKey:@"theme"];
    [defaults setBool:[alphaCheckbox state] == NSControlStateValueOn forKey:@"alpha"];
    [defaults setBool:[punctuationCheckbox state] == NSControlStateValueOn forKey:@"punctuation"];
    [defaults setInteger:[overlayPopup indexOfSelectedItem] forKey:@"overlay"];
    [defaults setBool:[flipCheckbox state] == NSControlStateValueOn forKey:@"flip"];
    [defaults setInteger:[changeSlider integerValue] forKey:@"change"];
    [defaults setInteger:[fpsSlider integerValue] forKey:@"fps"];
    [defaults setFloat:[minSpeedSlider floatValue] forKey:@"minspeed"];
    [defaults setFloat:[maxSpeedSlider floatValue] forKey:@"maxspeed"];
    [defaults setInteger:[fadeSlider integerValue] forKey:@"fadetime"];
    [defaults synchronize];
}

- (NSString*)settingsJS {
    ScreenSaverDefaults *defaults = [self defaults];
    return [NSString stringWithFormat:
        @"if (window.applySettings) applySettings({theme:%ld, alpha:%@, punctuation:%@, overlay:%ld, flip:%@, change:%ld, fps:%ld, minspeed:%.2f, maxspeed:%.2f, fadetime:%ld});",
        [defaults integerForKey:@"theme"],
        [defaults boolForKey:@"alpha"] ? @"true" : @"false",
        [defaults boolForKey:@"punctuation"] ? @"true" : @"false",
        [defaults integerForKey:@"overlay"],
        [defaults boolForKey:@"flip"] ? @"true" : @"false",
        [defaults integerForKey:@"change"],
        [defaults integerForKey:@"fps"],
        [defaults floatForKey:@"minspeed"],
        [defaults floatForKey:@"maxspeed"],
        [defaults integerForKey:@"fadetime"]];
}

- (void)updateValueLabels {
    if (changeSlider) [changeLabel setStringValue:[NSString stringWithFormat:@"%ld", [changeSlider integerValue]]];
    if (fpsSlider) [fpsLabel setStringValue:[NSString stringWithFormat:@"%ld FPS", [fpsSlider integerValue]]];
    if (minSpeedSlider) [minSpeedLabel setStringValue:[NSString stringWithFormat:@"%.2f", [minSpeedSlider floatValue]]];
    if (maxSpeedSlider) [maxSpeedLabel setStringValue:[NSString stringWithFormat:@"%.2f", [maxSpeedSlider floatValue]]];
    if (fadeSlider) [fadeLabel setStringValue:[NSString stringWithFormat:@"%ld s", [fadeSlider integerValue]]];
}

- (void)releaseControls {
    themePopup = nil; overlayPopup = nil; flipCheckbox = nil;
    fpsSlider = nil; fpsLabel = nil;
    changeSlider = nil; changeLabel = nil;
    alphaCheckbox = nil; punctuationCheckbox = nil;
    minSpeedSlider = nil; minSpeedLabel = nil;
    maxSpeedSlider = nil; maxSpeedLabel = nil;
    fadeSlider = nil; fadeLabel = nil;
    [super releaseControls];
}

@end
