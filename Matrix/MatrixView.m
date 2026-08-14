//
//  MatrixView.m — Matrix rain (classic)
//

#import "WebSaverView.h"

@interface MatrixView () {
    NSPopUpButton *themePopup;
    NSPopUpButton *overlayPopup;
    NSButton *flipCheckbox;
    NSSlider *fpsSlider;
    NSTextField *fpsLabel;
}
@end

@implementation MatrixView

- (CGFloat)configSheetHeight { return 190; }

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
}

- (void)loadDefaultsIntoSheet {
    ScreenSaverDefaults *defaults = [self defaults];
    [defaults registerDefaults:@{@"theme":@0, @"overlay":@1, @"flip":@NO, @"fps":@30}];
    [themePopup selectItemAtIndex:[defaults integerForKey:@"theme"]];
    [overlayPopup selectItemAtIndex:[defaults integerForKey:@"overlay"]];
    [flipCheckbox setState:[defaults boolForKey:@"flip"] ? NSControlStateValueOn : NSControlStateValueOff];
    [fpsSlider setIntegerValue:[defaults integerForKey:@"fps"]];
    [self updateValueLabels];
}

- (void)saveConfigSheet {
    ScreenSaverDefaults *defaults = [self defaults];
    [defaults setInteger:[themePopup indexOfSelectedItem] forKey:@"theme"];
    [defaults setInteger:[overlayPopup indexOfSelectedItem] forKey:@"overlay"];
    [defaults setBool:[flipCheckbox state] == NSControlStateValueOn forKey:@"flip"];
    [defaults setInteger:[fpsSlider integerValue] forKey:@"fps"];
    [defaults synchronize];
}

- (NSString*)settingsJS {
    ScreenSaverDefaults *defaults = [self defaults];
    return [NSString stringWithFormat:
        @"if (window.applySettings) applySettings({theme:%ld, overlay:%ld, flip:%@, fps:%ld});",
        [defaults integerForKey:@"theme"],
        [defaults integerForKey:@"overlay"],
        [defaults boolForKey:@"flip"] ? @"true" : @"false",
        [defaults integerForKey:@"fps"]];
}

- (void)updateValueLabels {
    if (fpsSlider) [fpsLabel setStringValue:[NSString stringWithFormat:@"%ld FPS", [fpsSlider integerValue]]];
}

- (void)releaseControls {
    themePopup = nil; overlayPopup = nil; flipCheckbox = nil;
    fpsSlider = nil; fpsLabel = nil;
    [super releaseControls];
}

@end
