//
//  VibeSolarSystemView.m — Vibe solar system
//

#import "WebSaverView.h"

@interface VibeSolarSystemView () {
    NSSlider *planetSlider;
    NSTextField *planetLabel;
    NSButton *asteroidCheckbox;
    NSSlider *camSpeedSlider;
    NSTextField *camSpeedLabel;
}
@end

@implementation VibeSolarSystemView

- (CGFloat)configSheetHeight { return 280; }

- (void)buildConfigSheet {
    NSView *content = [configSheet contentView];
    CGFloat y = [self configSheetHeight] - 30;

    // Planet count
    [content addSubview:[self labelAt:NSMakeRect(10, y, 110, 20) text:@"Planets:" alignment:NSTextAlignmentRight]];
    planetSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(125, y - 3, 160, 20)];
    [planetSlider setMinValue:3]; [planetSlider setMaxValue:10]; [planetSlider setNumberOfTickMarks:8];
    [planetSlider setTarget:self]; [planetSlider setAction:@selector(sliderChanged:)];
    [content addSubview:planetSlider];
    planetLabel = [self valueLabelAt:NSMakeRect(290, y, 70, 20)];
    [content addSubview:planetLabel];
    y -= 32;

    // Asteroids
    asteroidCheckbox = [self checkboxAt:NSMakeRect(125, y, 240, 20) title:@"Show asteroids"];
    [content addSubview:asteroidCheckbox];
    y -= 32;

    // Camera speed
    [content addSubview:[self labelAt:NSMakeRect(10, y, 110, 20) text:@"Camera speed:" alignment:NSTextAlignmentRight]];
    camSpeedSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(125, y - 3, 160, 20)];
    [camSpeedSlider setMinValue:0.1]; [camSpeedSlider setMaxValue:3.0]; [camSpeedSlider setNumberOfTickMarks:10];
    [camSpeedSlider setTarget:self]; [camSpeedSlider setAction:@selector(sliderChanged:)];
    [content addSubview:camSpeedSlider];
    camSpeedLabel = [self valueLabelAt:NSMakeRect(290, y, 70, 20)];
    [content addSubview:camSpeedLabel];
    y -= 45;
}

- (void)loadDefaultsIntoSheet {
    ScreenSaverDefaults *defaults = [self defaults];
    [defaults registerDefaults:@{@"planets":@6, @"asteroids":@YES, @"camSpeed":@1.0}];
    [planetSlider setIntegerValue:[defaults integerForKey:@"planets"]];
    [asteroidCheckbox setState:[defaults boolForKey:@"asteroids"] ? NSControlStateValueOn : NSControlStateValueOff];
    [camSpeedSlider setFloatValue:[defaults floatForKey:@"camSpeed"]];
    [self updateValueLabels];
}

- (void)saveConfigSheet {
    ScreenSaverDefaults *defaults = [self defaults];
    [defaults setInteger:[planetSlider integerValue] forKey:@"planets"];
    [defaults setBool:[asteroidCheckbox state] == NSControlStateValueOn forKey:@"asteroids"];
    [defaults setFloat:[camSpeedSlider floatValue] forKey:@"camSpeed"];
    [defaults synchronize];
}

- (NSString*)settingsJS {
    ScreenSaverDefaults *defaults = [self defaults];
    return [NSString stringWithFormat:
        @"if (window.applySettings) applySettings({planets:%ld, asteroids:%@, camSpeed:%.1f});",
        [defaults integerForKey:@"planets"],
        [defaults boolForKey:@"asteroids"] ? @"true" : @"false",
        [defaults floatForKey:@"camSpeed"]];
}

- (void)updateValueLabels {
    if (planetSlider) [planetLabel setStringValue:[NSString stringWithFormat:@"%ld", [planetSlider integerValue]]];
    if (camSpeedSlider) [camSpeedLabel setStringValue:[NSString stringWithFormat:@"%.1f×", [camSpeedSlider floatValue]]];
}

- (void)releaseControls {
    planetSlider = nil; planetLabel = nil;
    asteroidCheckbox = nil;
    camSpeedSlider = nil; camSpeedLabel = nil;
    [super releaseControls];
}

@end
