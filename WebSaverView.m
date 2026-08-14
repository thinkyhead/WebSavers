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

#pragma mark - Config Sheet

- (BOOL)hasConfigureSheet {
    // All savers except the Vibe series expose options
    NSString *cls = NSStringFromClass([self class]);
    BOOL result = ![cls hasPrefix:@"Vibe"];
    MGLog(@"hasConfigureSheet returning %@ for class:%@", result ? @"YES" : @"NO", cls);
    return result;
}

- (NSWindow*)configureSheet {
    MGLog(@"configureSheet called (existing configSheet=%p)", configSheet);
    [self buildConfigSheet];
    [self loadDefaultsIntoSheet];
    MGLog(@"  returning configSheet=%p, parentWindow=%p", configSheet, [configSheet parentWindow]);
    return configSheet;
}

- (NSString*)saverName {
    return NSStringFromClass([self class]);
}

- (void)buildConfigSheet {
    NSString *cls = [self saverName];
    MGLog(@"buildConfigSheet: creating sheet for %@", cls);

    CGFloat width = 380, height = 440;
    if ([cls isEqualToString:@"StarfieldView"] || [cls isEqualToString:@"StringyView"]) height = 280;
    if ([cls isEqualToString:@"Matrix3DView"]) height = 320;

    configSheet = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, width, height)
                                             styleMask:NSWindowStyleMaskTitled
                                               backing:NSBackingStoreBuffered
                                                 defer:NO];
    [configSheet setTitle:[cls stringByReplacingOccurrencesOfString:@"View" withString:@""]];

    NSView *content = [configSheet contentView];
    CGFloat y = height - 30;

    if ([cls isEqualToString:@"MatrixGridView"] || [cls isEqualToString:@"MatrixView"]) {
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

        // Change slider (MatrixGrid) or Alpha (Matrix)
        if ([cls isEqualToString:@"MatrixGridView"]) {
            [content addSubview:[self labelAt:NSMakeRect(10, y, 110, 20) text:@"Random change:" alignment:NSTextAlignmentRight]];
            changeSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(125, y - 3, 160, 20)];
            [changeSlider setMinValue:0]; [changeSlider setMaxValue:10]; [changeSlider setNumberOfTickMarks:11];
            [changeSlider setTarget:self]; [changeSlider setAction:@selector(sliderChanged:)];
            [content addSubview:changeSlider];
            changeLabel = [self valueLabelAt:NSMakeRect(290, y, 70, 20)];
            [content addSubview:changeLabel];
            y -= 32;

            alphaCheckbox = [self checkboxAt:NSMakeRect(125, y, 240, 20) title:@"Include Roman alphabet"];
            [content addSubview:alphaCheckbox];
            y -= 28;
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
    }
    else if ([cls isEqualToString:@"StarfieldView"]) {
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
    else if ([cls isEqualToString:@"StringyView"]) {
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
    else if ([cls isEqualToString:@"Matrix3DView"]) {
        // Drop color
        [content addSubview:[self labelAt:NSMakeRect(10, y, 110, 20) text:@"Color:" alignment:NSTextAlignmentRight]];
        colorPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(125, y - 3, 240, 25) pullsDown:NO];
        [colorPopup addItemsWithTitles:@[@"Green", @"Amber", @"White", @"Blue"]];
        [content addSubview:colorPopup];
        y -= 35;

        // Font size
        [content addSubview:[self labelAt:NSMakeRect(10, y, 110, 20) text:@"Font size:" alignment:NSTextAlignmentRight]];
        fontSizeSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(125, y - 3, 160, 20)];
        [fontSizeSlider setMinValue:12]; [fontSizeSlider setMaxValue:48]; [fontSizeSlider setNumberOfTickMarks:13];
        [fontSizeSlider setTarget:self]; [fontSizeSlider setAction:@selector(sliderChanged:)];
        [content addSubview:fontSizeSlider];
        fontSizeLabel = [self valueLabelAt:NSMakeRect(290, y, 70, 20)];
        [content addSubview:fontSizeLabel];
        y -= 32;

        // Overlay
        [content addSubview:[self labelAt:NSMakeRect(10, y, 110, 20) text:@"Overlay:" alignment:NSTextAlignmentRight]];
        overlayPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(125, y - 3, 240, 25) pullsDown:NO];
        [overlayPopup addItemsWithTitles:@[@"None", @"Scanlines", @"Shadow Mask"]];
        [content addSubview:overlayPopup];
        y -= 45;
    }

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

    MGLog(@"  sheet built for %@", cls);
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
    if (changeSlider) [changeLabel setStringValue:[NSString stringWithFormat:@"%ld", [changeSlider integerValue]]];
    if (fpsSlider) [fpsLabel setStringValue:[NSString stringWithFormat:@"%ld FPS", [fpsSlider integerValue]]];
    if (minSpeedSlider) [minSpeedLabel setStringValue:[NSString stringWithFormat:@"%.2f", [minSpeedSlider floatValue]]];
    if (maxSpeedSlider) [maxSpeedLabel setStringValue:[NSString stringWithFormat:@"%.2f", [maxSpeedSlider floatValue]]];
    if (fadeSlider) [fadeLabel setStringValue:[NSString stringWithFormat:@"%ld s", [fadeSlider integerValue]]];
    if (starCountSlider) [starCountLabel setStringValue:[NSString stringWithFormat:@"%ld", [starCountSlider integerValue]]];
    if (speedSlider) [speedLabel setStringValue:[NSString stringWithFormat:@"%.1f", [speedSlider floatValue]]];
    if (trailCountSlider) [trailCountLabel setStringValue:[NSString stringWithFormat:@"%ld", [trailCountSlider integerValue]]];
    if (trailLengthSlider) [trailLengthLabel setStringValue:[NSString stringWithFormat:@"%ld", [trailLengthSlider integerValue]]];
    if (fontSizeSlider) [fontSizeLabel setStringValue:[NSString stringWithFormat:@"%ld", [fontSizeSlider integerValue]]];
}

- (void)loadDefaultsIntoSheet {
    ScreenSaverDefaults *defaults = [self defaults];
    NSString *cls = [self saverName];

    if ([cls isEqualToString:@"MatrixGridView"]) {
        [defaults registerDefaults:@{@"theme":@3, @"alpha":@YES, @"punctuation":@NO, @"overlay":@0, @"flip":@YES, @"change":@4, @"fps":@30, @"minspeed":@0.2, @"maxspeed":@1.0, @"fadetime":@3}];
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
    }
    else if ([cls isEqualToString:@"MatrixView"]) {
        [defaults registerDefaults:@{@"theme":@0, @"overlay":@1, @"flip":@NO, @"fps":@30}];
        [themePopup selectItemAtIndex:[defaults integerForKey:@"theme"]];
        [overlayPopup selectItemAtIndex:[defaults integerForKey:@"overlay"]];
        [flipCheckbox setState:[defaults boolForKey:@"flip"] ? NSControlStateValueOn : NSControlStateValueOff];
        [fpsSlider setIntegerValue:[defaults integerForKey:@"fps"]];
    }
    else if ([cls isEqualToString:@"StarfieldView"]) {
        [defaults registerDefaults:@{@"starCount":@6000, @"speed":@7}];
        [starCountSlider setIntegerValue:[defaults integerForKey:@"starCount"]];
        [speedSlider setFloatValue:[defaults floatForKey:@"speed"]];
    }
    else if ([cls isEqualToString:@"StringyView"]) {
        [defaults registerDefaults:@{@"fps":@30, @"trailCount":@10, @"trailLength":@10}];
        [fpsSlider setIntegerValue:[defaults integerForKey:@"fps"]];
        [trailCountSlider setIntegerValue:[defaults integerForKey:@"trailCount"]];
        [trailLengthSlider setIntegerValue:[defaults integerForKey:@"trailLength"]];
    }
    else if ([cls isEqualToString:@"Matrix3DView"]) {
        [defaults registerDefaults:@{@"color":@0, @"fontSize":@24, @"overlay":@0}];
        [colorPopup selectItemAtIndex:[defaults integerForKey:@"color"]];
        [fontSizeSlider setIntegerValue:[defaults integerForKey:@"fontSize"]];
        [overlayPopup selectItemAtIndex:[defaults integerForKey:@"overlay"]];
    }

    [self updateValueLabels];
    MGLog(@"  defaults loaded for %@", cls);
}

- (ScreenSaverDefaults*)defaults {
    NSString *module = [NSString stringWithFormat:@"com.thinkyhead.saver.%@", NSStringFromClass([self class])];
    return [ScreenSaverDefaults defaultsForModuleWithName:module];
}

- (void)loadIndexWithConfig:(BOOL)useConfig {
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"index" ofType:@"html"];
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
    MGLog(@"  loadIndexWithConfig:%@ path:%@", useConfig ? @"YES" : @"NO", path);
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    MGLog(@"didFinishNavigation class:%@", NSStringFromClass([self class]));

    NSString *cls = [self saverName];
    ScreenSaverDefaults *defaults = [self defaults];
    NSString *js = nil;

    if ([cls isEqualToString:@"MatrixGridView"]) {
        js = [NSString stringWithFormat:
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
    else if ([cls isEqualToString:@"MatrixView"]) {
        js = [NSString stringWithFormat:
            @"if (window.applySettings) applySettings({theme:%ld, overlay:%ld, flip:%@, fps:%ld});",
            [defaults integerForKey:@"theme"],
            [defaults integerForKey:@"overlay"],
            [defaults boolForKey:@"flip"] ? @"true" : @"false",
            [defaults integerForKey:@"fps"]];
    }
    else if ([cls isEqualToString:@"StarfieldView"]) {
        js = [NSString stringWithFormat:
            @"if (window.applySettings) applySettings({starCount:%ld, speed:%.1f});",
            [defaults integerForKey:@"starCount"],
            [defaults floatForKey:@"speed"]];
    }
    else if ([cls isEqualToString:@"StringyView"]) {
        js = [NSString stringWithFormat:
            @"if (window.applySettings) applySettings({fps:%ld, trailCount:%ld, trailLength:%ld});",
            [defaults integerForKey:@"fps"],
            [defaults integerForKey:@"trailCount"],
            [defaults integerForKey:@"trailLength"]];
    }
    else if ([cls isEqualToString:@"Matrix3DView"]) {
        js = [NSString stringWithFormat:
            @"if (window.applySettings) applySettings({color:%ld, fontSize:%ld, overlay:%ld});",
            [defaults integerForKey:@"color"],
            [defaults integerForKey:@"fontSize"],
            [defaults integerForKey:@"overlay"]];
    }

    if (js) {
        [webView evaluateJavaScript:js completionHandler:nil];
        MGLog(@"  settings JS injected: %@", js);
    }
}

- (IBAction)sliderChanged:(id)sender {
    [self updateValueLabels];
}

- (IBAction)configCancel:(id)sender {
    MGLog(@"configCancel: configSheet=%p", configSheet);
    [[NSApplication sharedApplication] endSheet:configSheet];
    [self releaseControls];
    MGLog(@"  controls nilled out");
}

- (IBAction)configOK:(id)sender {
    MGLog(@"configOK: configSheet=%p", configSheet);
    ScreenSaverDefaults *defaults = [self defaults];
    NSString *cls = [self saverName];

    if ([cls isEqualToString:@"MatrixGridView"]) {
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
    }
    else if ([cls isEqualToString:@"MatrixView"]) {
        [defaults setInteger:[themePopup indexOfSelectedItem] forKey:@"theme"];
        [defaults setInteger:[overlayPopup indexOfSelectedItem] forKey:@"overlay"];
        [defaults setBool:[flipCheckbox state] == NSControlStateValueOn forKey:@"flip"];
        [defaults setInteger:[fpsSlider integerValue] forKey:@"fps"];
    }
    else if ([cls isEqualToString:@"StarfieldView"]) {
        [defaults setInteger:[starCountSlider integerValue] forKey:@"starCount"];
        [defaults setFloat:[speedSlider floatValue] forKey:@"speed"];
    }
    else if ([cls isEqualToString:@"StringyView"]) {
        [defaults setInteger:[fpsSlider integerValue] forKey:@"fps"];
        [defaults setInteger:[trailCountSlider integerValue] forKey:@"trailCount"];
        [defaults setInteger:[trailLengthSlider integerValue] forKey:@"trailLength"];
    }
    else if ([cls isEqualToString:@"Matrix3DView"]) {
        [defaults setInteger:[colorPopup indexOfSelectedItem] forKey:@"color"];
        [defaults setInteger:[fontSizeSlider integerValue] forKey:@"fontSize"];
        [defaults setInteger:[overlayPopup indexOfSelectedItem] forKey:@"overlay"];
    }

    [defaults synchronize];
    [self loadIndexWithConfig:YES];

    [[NSApplication sharedApplication] endSheet:configSheet];
    [self releaseControls];
    MGLog(@"  settings saved for %@", cls);
}

- (void)releaseControls {
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
    starCountSlider = nil;
    starCountLabel = nil;
    speedSlider = nil;
    speedLabel = nil;
    trailCountSlider = nil;
    trailCountLabel = nil;
    trailLengthSlider = nil;
    trailLengthLabel = nil;
    colorPopup = nil;
    fontSizeSlider = nil;
    fontSizeLabel = nil;
}

- (void)dealloc {
    MGLog(@"dealloc class:%@", NSStringFromClass([self class]));
    [NSDistributedNotificationCenter.defaultCenter removeObserver:self];
    [webView setNavigationDelegate:nil];
}

- (void)screensaverWillStop:(NSNotification *)notification {
    MGLog(@"screensaverWillStop: isPreview=%d", self.isPreview);
    if (self.isPreview) return;
    if (@available(macOS 14.0, *)) {
        MGLog(@"  calling exit(0) for real screensaver stop");
        exit(0);
    }
}

@end
