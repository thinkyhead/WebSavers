//
//  WebSaverView.m
//    Copyright (C) 2008 Gavin Brock http://brock-family.org/gavin
//
//    Simplified WebSaver that just loads Resources/index.html
//    Copyright (C) 2023 Scott Lahteine https://github.com/thinkyhead
//
//    This program is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    This program is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#define MGLog(...) NSLog(@"[MG] " __VA_ARGS__)

#import "WebSaverView.h"
#import "WKWebViewPrivate.h"

@implementation WEBSAVER_CLASS

- (id)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview {
    MGLog(@"initWithFrame:%@ isPreview:%d class:%@", NSStringFromRect(frame), isPreview, NSStringFromClass([self class]));
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        [self setAnimationTimeInterval:0.5];

        webView = [[WKWebView alloc] initWithFrame:frame];
        [webView setNavigationDelegate:self];
        MGLog(@"  webView=%p created, navigationDelegate=self (%p)", webView, self);

        // Sonoma ScreenSaverEngine view hierarchy occludes webview pausing animations and JS.
        [webView wvss_setWindowOcclusionDetectionEnabled: NO];

        // Any user agent will do
        [webView setCustomUserAgent:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8) AppleWebKit/536.25 (KHTML, like Gecko) Version/6.0 Safari/536.25"];

        // Prevent a white flash when first showing the view
        [webView setValue: @NO forKey: @"drawsBackground"];

        // When shown in the System Settings panel reduce the size
        if (isPreview) [self scaleUnitSquareToSize:NSMakeSize( 0.25, 0.25 )];

        // Put the webView into the WebSaverView as a sub-view
        [self addSubview:webView];

        // Call screensaverWillStop on screensaver.willstop notification
        [ NSDistributedNotificationCenter.defaultCenter
            addObserver:self
            selector:@selector(screensaverWillStop:)
            name:@"com.apple.screensaver.willstop"
            object:nil
        ];
    }

    return self;
}

- (void)setFrame:(NSRect)frameRect {
    MGLog(@"setFrame:%@", NSStringFromRect(frameRect));
    [super setFrame:frameRect];
    [webView setFrame:frameRect];
    [webView setFrameSize:[webView convertSize:frameRect.size fromView:nil]];
}

- (void)startAnimation {
    MGLog(@"startAnimation class:%@", NSStringFromClass([self class]));

    [super startAnimation];

    [self loadIndexWithConfig:YES];
}

- (void)stopAnimation {
    MGLog(@"stopAnimation class:%@", NSStringFromClass([self class]));

    [webView stopLoading];
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:"]]];

    [super stopAnimation];
}

- (void)doKeyUp:(NSTimer*)theTimer {
    [ [NSApplication sharedApplication]
        sendEvent:[NSEvent keyEventWithType:NSEventTypeKeyUp
            location:      NSMakePoint(1,1)
            modifierFlags: 0
            timestamp:     [[NSDate date] timeIntervalSinceReferenceDate]
            windowNumber:  [[self window] windowNumber]
            context:       [NSGraphicsContext currentContext]
            characters:    [theTimer userInfo]
            charactersIgnoringModifiers:[theTimer userInfo]
            isARepeat:     NO
            keyCode:       0
        ]
    ];
}

- (void)doKeyDown:(NSTimer*)theTimer {
    [[NSApplication sharedApplication]
        sendEvent: [NSEvent keyEventWithType:NSEventTypeKeyDown
            location:      NSMakePoint(1,1)
            modifierFlags: 0
            timestamp:     [[NSDate date] timeIntervalSinceReferenceDate]
            windowNumber:  [[self window] windowNumber]
            context:       [NSGraphicsContext currentContext]
            characters:    [theTimer userInfo]
            charactersIgnoringModifiers:[theTimer userInfo]
            isARepeat:     NO
            keyCode:       0
        ]
    ];
}

- (void)animateOneFrame { }

- (BOOL)hasConfigureSheet {
    BOOL result = [NSStringFromClass([self class]) isEqualToString:@"MatrixGridView"];
    MGLog(@"hasConfigureSheet returning %@ for class:%@", result ? @"YES" : @"NO", NSStringFromClass([self class]));
    return result;
}

- (NSWindow*)configureSheet {
    MGLog(@"configureSheet called (existing configSheet=%p)", configSheet);

    [self buildConfigSheet];
    [self loadDefaultsIntoSheet];

    MGLog(@"  returning configSheet=%p, parentWindow=%p", configSheet, [configSheet parentWindow]);
    return configSheet;
}

- (void)buildConfigSheet {
    MGLog(@"buildConfigSheet: creating new NSWindow");

    configSheet = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 380, 440)
                                             styleMask:NSWindowStyleMaskTitled
                                               backing:NSBackingStoreBuffered
                                                 defer:NO];
    [configSheet setTitle:@"MatrixGrid Settings"];
    MGLog(@"  configSheet=%p", configSheet);

    NSView *content = [configSheet contentView];
    CGFloat y = 440 - 30;

    // Theme
    NSTextField *themeLabel = [self labelAt:NSMakeRect(10, y, 110, 20) text:@"Theme:" alignment:NSTextAlignmentRight];
    [content addSubview:themeLabel];
    themePopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(125, y - 3, 240, 25) pullsDown:NO];
    [themePopup addItemsWithTitles:@[@"Green", @"Amber", @"Light", @"Atari 800"]];
    [content addSubview:themePopup];
    y -= 35;

    // Alpha
    alphaCheckbox = [self checkboxAt:NSMakeRect(125, y, 240, 20) title:@"Include Roman alphabet"];
    [content addSubview:alphaCheckbox];
    y -= 28;

    // Punctuation
    punctuationCheckbox = [self checkboxAt:NSMakeRect(125, y, 240, 20) title:@"Include punctuation"];
    [content addSubview:punctuationCheckbox];
    y -= 32;

    // Overlay
    NSTextField *overlayLabel = [self labelAt:NSMakeRect(10, y, 110, 20) text:@"Overlay:" alignment:NSTextAlignmentRight];
    [content addSubview:overlayLabel];
    overlayPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(125, y - 3, 240, 25) pullsDown:NO];
    [overlayPopup addItemsWithTitles:@[@"None", @"Scanlines", @"Shadow Mask"]];
    [content addSubview:overlayPopup];
    y -= 35;

    // Flip
    flipCheckbox = [self checkboxAt:NSMakeRect(125, y, 240, 20) title:@"Flip characters"];
    [content addSubview:flipCheckbox];
    y -= 32;

    // Change slider
    NSTextField *changeText = [self labelAt:NSMakeRect(10, y, 110, 20) text:@"Random change:" alignment:NSTextAlignmentRight];
    [content addSubview:changeText];
    changeSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(125, y - 3, 160, 20)];
    [changeSlider setMinValue:0];
    [changeSlider setMaxValue:10];
    [changeSlider setNumberOfTickMarks:11];
    [changeSlider setTarget:self];
    [changeSlider setAction:@selector(sliderChanged:)];
    [content addSubview:changeSlider];
    changeLabel = [self valueLabelAt:NSMakeRect(290, y, 70, 20)];
    [content addSubview:changeLabel];
    y -= 32;

    // FPS slider
    NSTextField *fpsText = [self labelAt:NSMakeRect(10, y, 110, 20) text:@"FPS:" alignment:NSTextAlignmentRight];
    [content addSubview:fpsText];
    fpsSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(125, y - 3, 160, 20)];
    [fpsSlider setMinValue:5];
    [fpsSlider setMaxValue:60];
    [fpsSlider setNumberOfTickMarks:12];
    [fpsSlider setTarget:self];
    [fpsSlider setAction:@selector(sliderChanged:)];
    [content addSubview:fpsSlider];
    fpsLabel = [self valueLabelAt:NSMakeRect(290, y, 70, 20)];
    [content addSubview:fpsLabel];
    y -= 32;

    // Min speed slider
    NSTextField *minText = [self labelAt:NSMakeRect(10, y, 110, 20) text:@"Min speed:" alignment:NSTextAlignmentRight];
    [content addSubview:minText];
    minSpeedSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(125, y - 3, 160, 20)];
    [minSpeedSlider setMinValue:0.1];
    [minSpeedSlider setMaxValue:1.0];
    [minSpeedSlider setTarget:self];
    [minSpeedSlider setAction:@selector(sliderChanged:)];
    [content addSubview:minSpeedSlider];
    minSpeedLabel = [self valueLabelAt:NSMakeRect(290, y, 70, 20)];
    [content addSubview:minSpeedLabel];
    y -= 32;

    // Max speed slider
    NSTextField *maxText = [self labelAt:NSMakeRect(10, y, 110, 20) text:@"Max speed:" alignment:NSTextAlignmentRight];
    [content addSubview:maxText];
    maxSpeedSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(125, y - 3, 160, 20)];
    [maxSpeedSlider setMinValue:0.1];
    [maxSpeedSlider setMaxValue:1.0];
    [maxSpeedSlider setTarget:self];
    [maxSpeedSlider setAction:@selector(sliderChanged:)];
    [content addSubview:maxSpeedSlider];
    maxSpeedLabel = [self valueLabelAt:NSMakeRect(290, y, 70, 20)];
    [content addSubview:maxSpeedLabel];
    y -= 32;

    // Fade slider
    NSTextField *fadeText = [self labelAt:NSMakeRect(10, y, 110, 20) text:@"Fade time:" alignment:NSTextAlignmentRight];
    [content addSubview:fadeText];
    fadeSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(125, y - 3, 160, 20)];
    [fadeSlider setMinValue:1];
    [fadeSlider setMaxValue:10];
    [fadeSlider setTarget:self];
    [fadeSlider setAction:@selector(sliderChanged:)];
    [content addSubview:fadeSlider];
    fadeLabel = [self valueLabelAt:NSMakeRect(290, y, 70, 20)];
    [content addSubview:fadeLabel];
    y -= 45;

    // OK button
    NSButton *okButton = [[NSButton alloc] initWithFrame:NSMakeRect(290, 10, 75, 28)];
    [okButton setTitle:@"OK"];
    [okButton setBezelStyle:NSBezelStyleRounded];
    [okButton setKeyEquivalent:@"\r"];
    [okButton setTarget:self];
    [okButton setAction:@selector(configOK:)];
    [content addSubview:okButton];

    // Cancel button
    NSButton *cancelButton = [[NSButton alloc] initWithFrame:NSMakeRect(210, 10, 75, 28)];
    [cancelButton setTitle:@"Cancel"];
    [cancelButton setBezelStyle:NSBezelStyleRounded];
    [cancelButton setTarget:self];
    [cancelButton setAction:@selector(configCancel:)];
    [content addSubview:cancelButton];

    MGLog(@"  sheet built: themePopup=%p alphaCheckbox=%p changeSlider=%p", themePopup, alphaCheckbox, changeSlider);
}

- (NSTextField*)labelAt:(NSRect)frame text:(NSString*)text alignment:(NSTextAlignment)align {
    NSTextField *label = [[NSTextField alloc] initWithFrame:frame];
    [label setStringValue:text];
    [label setBezeled:NO];
    [label setDrawsBackground:NO];
    [label setEditable:NO];
    [label setSelectable:NO];
    [label setAlignment:align];
    return label;
}

- (NSTextField*)valueLabelAt:(NSRect)frame {
    NSTextField *label = [[NSTextField alloc] initWithFrame:frame];
    [label setBezeled:NO];
    [label setDrawsBackground:NO];
    [label setEditable:NO];
    [label setSelectable:NO];
    [label setFont:[NSFont systemFontOfSize:11]];
    return label;
}

- (NSButton*)checkboxAt:(NSRect)frame title:(NSString*)title {
    NSButton *btn = [[NSButton alloc] initWithFrame:frame];
    [btn setButtonType:NSSwitchButton];
    [btn setTitle:title];
    return btn;
}

- (void)updateValueLabels {
    [changeLabel setStringValue:[NSString stringWithFormat:@"%ld", [changeSlider integerValue]]];
    [fpsLabel setStringValue:[NSString stringWithFormat:@"%ld FPS", [fpsSlider integerValue]]];
    [minSpeedLabel setStringValue:[NSString stringWithFormat:@"%.2f", [minSpeedSlider floatValue]]];
    [maxSpeedLabel setStringValue:[NSString stringWithFormat:@"%.2f", [maxSpeedSlider floatValue]]];
    [fadeLabel setStringValue:[NSString stringWithFormat:@"%ld s", [fadeSlider integerValue]]];
}

- (void)loadDefaultsIntoSheet {
    ScreenSaverDefaults *defaults = [self defaults];
    [defaults registerDefaults:@{
        @"theme": @3,
        @"alpha": @YES,
        @"punctuation": @NO,
        @"overlay": @0,
        @"flip": @YES,
        @"change": @4,
        @"fps": @30,
        @"minspeed": @0.2,
        @"maxspeed": @1.0,
        @"fadetime": @3
    }];

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
    MGLog(@"  defaults loaded into sheet");
}

- (ScreenSaverDefaults*)defaults {
    NSString *module = [NSString stringWithFormat:@"com.thinkyhead.saver.%@", NSStringFromClass([self class])];
    return [ScreenSaverDefaults defaultsForModuleWithName:module];
}

- (void)loadIndexWithConfig:(BOOL)useConfig {
    ScreenSaverDefaults *defaults = [self defaults];

    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"index" ofType:@"html"];
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
    MGLog(@"  loadIndexWithConfig:%@ path:%@", useConfig ? @"YES" : @"NO", path);

    if (useConfig && [self hasConfigureSheet]) {
        [defaults registerDefaults:@{
            @"theme": @3, @"alpha": @YES, @"punctuation": @NO, @"overlay": @0,
            @"flip": @YES, @"change": @4, @"fps": @30,
            @"minspeed": @0.2, @"maxspeed": @1.0, @"fadetime": @3
        }];
    }
}

// WKWebView navigation delegate - inject settings after page loads
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    MGLog(@"didFinishNavigation class:%@", NSStringFromClass([self class]));

    if ([self hasConfigureSheet]) {
        ScreenSaverDefaults *defaults = [self defaults];
        NSString *js = [NSString stringWithFormat:
            @"if (window.applySettings) applySettings({"
            @"theme: %ld, alpha: %@, punctuation: %@, overlay: %ld, flip: %@, "
            @"change: %ld, fps: %ld, minspeed: %.2f, maxspeed: %.2f, fadetime: %ld"
            @"});",
            [defaults integerForKey:@"theme"],
            [defaults boolForKey:@"alpha"] ? @"true" : @"false",
            [defaults boolForKey:@"punctuation"] ? @"true" : @"false",
            [defaults integerForKey:@"overlay"],
            [defaults boolForKey:@"flip"] ? @"true" : @"false",
            [defaults integerForKey:@"change"],
            [defaults integerForKey:@"fps"],
            [defaults floatForKey:@"minspeed"],
            [defaults floatForKey:@"maxspeed"],
            [defaults integerForKey:@"fadetime"]
        ];
        [webView evaluateJavaScript:js completionHandler:nil];
        MGLog(@"  settings JS injected");
    }
}

- (IBAction)sliderChanged:(id)sender {
    [self updateValueLabels];
}

- (IBAction)configCancel:(id)sender {
    MGLog(@"configCancel: configSheet=%p, parentWindow=%p", configSheet, [configSheet parentWindow]);
    [[NSApplication sharedApplication] endSheet:configSheet];
    configSheet = nil;
    themePopup = nil;
    alphaCheckbox = nil;
    punctuationCheckbox = nil;
    overlayPopup = nil;
    flipCheckbox = nil;
    changeSlider = nil;
    changeLabel = nil;
    fpsSlider = nil;
    fpsLabel = nil;
    minSpeedSlider = nil;
    minSpeedLabel = nil;
    maxSpeedSlider = nil;
    maxSpeedLabel = nil;
    fadeSlider = nil;
    fadeLabel = nil;
    MGLog(@"  controls nilled out");
}

- (IBAction)configOK:(id)sender {
    MGLog(@"configOK: configSheet=%p", configSheet);

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

    [self loadIndexWithConfig:YES];

    [[NSApplication sharedApplication] endSheet:configSheet];
    configSheet = nil;
    themePopup = nil;
    alphaCheckbox = nil;
    punctuationCheckbox = nil;
    overlayPopup = nil;
    flipCheckbox = nil;
    changeSlider = nil;
    changeLabel = nil;
    fpsSlider = nil;
    fpsLabel = nil;
    minSpeedSlider = nil;
    minSpeedLabel = nil;
    maxSpeedSlider = nil;
    maxSpeedLabel = nil;
    fadeSlider = nil;
    fadeLabel = nil;
    MGLog(@"  settings saved, controls nilled out");
}

- (void)dealloc {
    MGLog(@"dealloc class:%@", NSStringFromClass([self class]));
    [NSDistributedNotificationCenter.defaultCenter removeObserver:self];
    [webView setNavigationDelegate:nil];
}

- (void)screensaverWillStop:(NSNotification *)notification {
    MGLog(@"screensaverWillStop: isPreview=%d", self.isPreview);
    if (self.isPreview) return; // Don't kill the process during preview
    if (@available(macOS 14.0, *)) {
        MGLog(@"  calling exit(0) for real screensaver stop");
        exit(0);
    }
}

@end
