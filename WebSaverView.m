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

#import "WebSaverView.h"
#import "WKWebViewPrivate.h"

@implementation WebSaverView

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

- (NSString*)saverName {
    return NSStringFromClass([self class]);
}

- (CGFloat)configSheetHeight { return 440; }

- (BOOL)hasConfigureSheet {
    MGLog(@"hasConfigureSheet returning YES for class:%@", NSStringFromClass([self class]));
    return YES;
}

- (NSWindow*)configureSheet {
    MGLog(@"configureSheet called (existing configSheet=%p, isVisible=%d)", configSheet, configSheet ? [configSheet isVisible] : -1);

    // The system retains the window we return (readonly, strong property) and
    // re-presents the SAME window each time Options is clicked. The saver view
    // can be deallocated between panel-exit and re-entry, which would release
    // an instance-held window and orphan the system's cached reference — so the
    // sheet window must be a per-class singleton that outlives any one view.
    if (!configSheet) {
        MGLog(@"  [configureSheet] creating window");
        configSheet = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 380, [self configSheetHeight])
                                                 styleMask:NSWindowStyleMaskTitled
                                                   backing:NSBackingStoreBuffered
                                                     defer:NO];

        NSString *cls = [self saverName];
        NSString *title = [cls stringByReplacingOccurrencesOfString:@"View" withString:@""];
        [configSheet setTitle:[title stringByAppendingString:@" Settings"]];

        NSView *content = [configSheet contentView];

        [self buildConfigSheet];  // subclass adds its controls to `content`

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
    }

    [self loadDefaultsIntoSheet];
    MGLog(@"  returning configSheet=%p, parentWindow=%p, isSheet=%d",
          configSheet, [configSheet parentWindow],
          configSheet ? [configSheet isSheet] : -1);
    return configSheet;
}

// Default: no controls. Subclasses override.
- (void)buildConfigSheet {
    MGLog(@"buildConfigSheet (base, no controls) class:%@", [self saverName]);
}

- (void)loadDefaultsIntoSheet {
    MGLog(@"  defaults loaded for %@", [self saverName]);
    [self updateValueLabels];
}

- (void)saveConfigSheet {
    // Subclasses write + synchronize their own defaults object.
}

- (NSString*)settingsJS { return nil; }

- (void)updateValueLabels { }

- (void)releaseControls {
    configSheet = nil;
}

#pragma mark - Shared helpers

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

- (ScreenSaverDefaults*)defaults {
    // Key settings per-display so each screen has independent settings
    // Get the display ID from the screen containing this view's window
    CGDirectDisplayID displayID = 0;
    NSScreen *screen = [[self window] screen];
    if (screen) {
        displayID = [[[screen deviceDescription] objectForKey:@"NSScreenNumber"] unsignedIntValue];
    }
    NSString *module = [NSString stringWithFormat:@"com.thinkyhead.saver.%@.%u", NSStringFromClass([self class]), displayID];
    ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:module];

    // Settings versioning — bump this when settings schema changes so
    // stale options from an older build don't break the saver.
    static const NSInteger kSettingsVersion = 1;
    NSInteger storedVersion = [defaults integerForKey:@"settingsVersion"];
    if (storedVersion != kSettingsVersion) {
        MGLog(@"settings version mismatch (stored:%ld, current:%ld) — resetting defaults", (long)storedVersion, (long)kSettingsVersion);
        NSDictionary *oldDict = [defaults dictionaryRepresentation];
        for (NSString *key in oldDict) {
            [defaults removeObjectForKey:key];
        }
        [defaults setInteger:kSettingsVersion forKey:@"settingsVersion"];
        [defaults synchronize];
    }

    return defaults;
}

- (void)loadIndexWithConfig:(BOOL)useConfig {
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"index" ofType:@"html"];
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
    MGLog(@"  loadIndexWithConfig:%@ path:%@", useConfig ? @"YES" : @"NO", path);
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    MGLog(@"didFinishNavigation class:%@", NSStringFromClass([self class]));
    NSString *js = [self settingsJS];
    if (js) {
        [webView evaluateJavaScript:js completionHandler:nil];
        MGLog(@"  settings JS injected: %@", js);
    }
}

#pragma mark - Actions

- (IBAction)sliderChanged:(id)sender {
    [self updateValueLabels];
}

- (IBAction)configCancel:(id)sender {
    MGLog(@"configCancel: configSheet=%p, isVisible=%d, isSheet=%d", configSheet, [configSheet isVisible], [configSheet isSheet]);
    [[NSApplication sharedApplication] endSheet:configSheet];
    // Defer cleanup so the sheet animation can fully complete
    // before we release the window (otherwise the window might
    // get deallocated mid-animation and the sheet won't re-show).
    [self performSelector:@selector(releaseControls) withObject:nil afterDelay:0.1];
    MGLog(@"  deferred controls release");
}

- (IBAction)configOK:(id)sender {
    MGLog(@"configOK: configSheet=%p", configSheet);
    // saveConfigSheet writes via [self defaults] and synchronizes the SAME
    // instance, so the write is flushed before we reload the page.
    [self saveConfigSheet];
    [self loadIndexWithConfig:YES];

    MGLog(@"configOK: ending sheet configSheet=%p, isVisible=%d, isSheet=%d", configSheet, [configSheet isVisible], [configSheet isSheet]);
    [[NSApplication sharedApplication] endSheet:configSheet];
    // Defer cleanup so the sheet animation can fully complete
    // before we release the window (otherwise the window might
    // get deallocated mid-animation and the sheet won't re-show).
    [self performSelector:@selector(releaseControls) withObject:nil afterDelay:0.1];
    MGLog(@"  settings saved for %@", [self saverName]);
}

#pragma mark - Cleanup

- (void)dealloc {
    MGLog(@"dealloc class:%@", NSStringFromClass([self class]));
    [NSDistributedNotificationCenter.defaultCenter removeObserver:self];
    [webView setNavigationDelegate:nil];
}

- (void)screensaverWillStop:(NSNotification *)notification {
    MGLog(@"screensaverWillStop: isPreview=%d", self.isPreview);
    // Only exit the real (full-screen) screensaver run. Never kill the process
    // during preview — System Settings / the Wallpaper settings host owns our
    // lifecycle and killing it leaves a stale reference (Options sheet dies,
    // or the host crashes). isPreview is the reliable discriminator; a
    // hardcoded host-name blacklist is fragile (names change per macOS version).
    if (self.isPreview) return;
    if (@available(macOS 14.0, *)) {
        MGLog(@"  calling exit(0) for real screensaver stop");
        exit(0);
    }
}

@end
