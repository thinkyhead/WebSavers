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
#include <mach/mach.h>
#include <mach/mach_host.h>
#include <sys/sysctl.h>
#include <IOKit/IOKitLib.h>

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

    // HermesBoard and P5Alert: gather live system stats and push to JS every 2s
    if ([NSStringFromClass([self class]) isEqualToString:@"HermesBoardView"] ||
        [NSStringFromClass([self class]) isEqualToString:@"P5AlertView"]) {
        statsTimer = [NSTimer scheduledTimerWithTimeInterval:2.0
                                                      target:self
                                                    selector:@selector(pushSystemStats)
                                                    userInfo:nil
                                                     repeats:YES];
    }
}

- (void)stopAnimation {
    MGLog(@"stopAnimation class:%@", NSStringFromClass([self class]));
    [statsTimer invalidate];
    statsTimer = nil;
    [webView stopLoading];
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:"]]];
    [super stopAnimation];
}

- (void)pushSystemStats {
    // CPU usage based on tick deltas
    double cpuUsage = 0;
    host_cpu_load_info_data_t cpuLoad;
    mach_msg_type_number_t count = HOST_CPU_LOAD_INFO_COUNT;
    if (host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, (host_info_t)&cpuLoad, &count) == KERN_SUCCESS) {
        if (hasPrevCpu) {
            natural_t prevTotal = prevCpuLoad.cpu_ticks[CPU_STATE_USER] + prevCpuLoad.cpu_ticks[CPU_STATE_SYSTEM] + prevCpuLoad.cpu_ticks[CPU_STATE_IDLE] + prevCpuLoad.cpu_ticks[CPU_STATE_NICE];
            natural_t total = cpuLoad.cpu_ticks[CPU_STATE_USER] + cpuLoad.cpu_ticks[CPU_STATE_SYSTEM] + cpuLoad.cpu_ticks[CPU_STATE_IDLE] + cpuLoad.cpu_ticks[CPU_STATE_NICE];
            natural_t delta = total - prevTotal;
            if (delta > 0) {
                natural_t used = (cpuLoad.cpu_ticks[CPU_STATE_USER] - prevCpuLoad.cpu_ticks[CPU_STATE_USER]) +
                                 (cpuLoad.cpu_ticks[CPU_STATE_SYSTEM] - prevCpuLoad.cpu_ticks[CPU_STATE_SYSTEM]);
                cpuUsage = 100.0 * used / delta;
            }
        }
        prevCpuLoad = cpuLoad;
        hasPrevCpu = true;
    }

    // Memory: total physical + active/wired/compressed components
    int64_t memTotal = 0, memActive = 0, memWired = 0, memCompressed = 0;
    vm_size_t pageSize;
    host_page_size(mach_host_self(), &pageSize);
    vm_statistics64_data_t vmStats;
    mach_msg_type_number_t vmCount = HOST_VM_INFO64_COUNT;
    if (host_statistics64(mach_host_self(), HOST_VM_INFO64, (host_info_t)&vmStats, &vmCount) == KERN_SUCCESS) {
        memActive     = (int64_t)vmStats.active_count     * pageSize;
        memWired      = (int64_t)vmStats.wire_count       * pageSize;
        memCompressed = (int64_t)vmStats.compressor_page_count * pageSize;
    }
    // Total physical memory (hw.memsize)
    size_t len = sizeof(memTotal);
    sysctlbyname("hw.memsize", &memTotal, &len, NULL, 0);

    // Thermal via IOKit (TC0D = CPU die temp)
    double temp = 0;
    io_service_t platformExpert = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"));
    if (platformExpert) {
        CFTypeRef key = CFStringCreateWithCString(kCFAllocatorDefault, "TC0D", kCFStringEncodingUTF8);
        CFTypeRef val = IORegistryEntryCreateCFProperty(platformExpert, key, kCFAllocatorDefault, 0);
        if (val) {
            if (CFGetTypeID(val) == CFDataGetTypeID()) {
                const uint8_t *data = CFDataGetBytePtr((CFDataRef)val);
                if (CFDataGetLength((CFDataRef)val) >= 2) {
                    temp = (data[0] * 256 + data[1]) / 256.0;
                }
            }
            CFRelease(val);
        }
        CFRelease(key);
        IOObjectRelease(platformExpert);
    }

    NSString *js = [NSString stringWithFormat:
        @"if (window.applySystemStats) applySystemStats({cpu: %.1f, memory: %lld, memTotal: %lld, memActive: %lld, memWired: %lld, memCompressed: %lld, temperature: %.1f});",
        cpuUsage, memActive + memWired + memCompressed, memTotal, memActive, memWired, memCompressed, temp];
    [webView evaluateJavaScript:js completionHandler:nil];
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
    // All savers expose options
    MGLog(@"hasConfigureSheet returning YES for class:%@", NSStringFromClass([self class]));
    return YES;
}

- (NSWindow*)configureSheet {
    MGLog(@"configureSheet called (existing configSheet=%p)", configSheet);
    // The system retains the window we return (readonly, strong property)
    // and re-presents it each time Options is clicked. Build it ONCE and
    // return the same window every call; just refresh the control values
    // from the saved settings. Nilling/rebuilding breaks re-presentation.
    if (!configSheet) {
        [self buildConfigSheet];
    }
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
    if ([cls isEqualToString:@"VibeToroidView"]) height = 320;
    if ([cls isEqualToString:@"VibeOrbitView"]) height = 300;
    if ([cls isEqualToString:@"VibeSpheresView"]) height = 320;
    if ([cls isEqualToString:@"HermesBoardView"]) height = 200;

    configSheet = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, width, height)
                                             styleMask:NSWindowStyleMaskTitled
                                               backing:NSBackingStoreBuffered
                                                 defer:NO];
    NSString *title = [cls stringByReplacingOccurrencesOfString:@"View" withString:@""];
    if (![cls isEqualToString:@"HermesBoardView"]) title = [title stringByAppendingString:@" Settings"];
    [configSheet setTitle:title];

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
    else if ([cls isEqualToString:@"VibeToroidView"]) {
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
    else if ([cls isEqualToString:@"VibeOrbitView"]) {
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
    else if ([cls isEqualToString:@"VibeSpheresView"]) {
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
    else if ([cls isEqualToString:@"HermesBoardView"]) {
        // Clock toggle
        clockCheckbox = [self checkboxAt:NSMakeRect(125, y, 240, 20) title:@"Show clock"];
        [content addSubview:clockCheckbox];
        y -= 28;

        // Clock position
        [content addSubview:[self labelAt:NSMakeRect(10, y, 110, 20) text:@"Clock position:" alignment:NSTextAlignmentRight]];
        clockPositionPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(125, y - 3, 240, 25) pullsDown:NO];
        [clockPositionPopup addItemsWithTitles:@[@"Top", @"Bottom"]];
        [content addSubview:clockPositionPopup];
        y -= 35;

        // Show seconds
        secondsCheckbox = [self checkboxAt:NSMakeRect(125, y, 240, 20) title:@"Show seconds"];
        [content addSubview:secondsCheckbox];
        y -= 35;

        // Show image
        imageCheckbox = [self checkboxAt:NSMakeRect(125, y, 240, 20) title:@"Show image"];
        [content addSubview:imageCheckbox];
        y -= 45;
    }
    else if ([cls isEqualToString:@"P5AlertView"]) {
        // Show alert (for development)
        showAlertCheckbox = [self checkboxAt:NSMakeRect(125, y, 240, 20) title:@"Show alert"];
        [content addSubview:showAlertCheckbox];
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
    if (countSlider) [countLabel setStringValue:[NSString stringWithFormat:@"%ld", [countSlider integerValue]]];
    if (spreadSlider) [spreadLabel setStringValue:[NSString stringWithFormat:@"%ld", [spreadSlider integerValue]]];
    if (starFieldSlider) [starFieldLabel setStringValue:[NSString stringWithFormat:@"%ld", [starFieldSlider integerValue]]];
    if (colorCycleSlider) [colorCycleLabel setStringValue:[NSString stringWithFormat:@"%.1f", [colorCycleSlider floatValue]]];
    if (particleCountSlider) [particleCountLabel setStringValue:[NSString stringWithFormat:@"%ld", [particleCountSlider integerValue]]];
    if (morphIntervalSlider) [morphIntervalLabel setStringValue:[NSString stringWithFormat:@"%ld s", [morphIntervalSlider integerValue]]];
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
    else if ([cls isEqualToString:@"VibeToroidView"]) {
        [defaults registerDefaults:@{@"shape":@0, @"particleCount":@5000, @"speed":@10, @"morphInterval":@8}];
        [shapePopup selectItemAtIndex:[defaults integerForKey:@"shape"]];
        [particleCountSlider setIntegerValue:[defaults integerForKey:@"particleCount"]];
        [speedSlider setIntegerValue:[defaults integerForKey:@"speed"]];
        [morphIntervalSlider setIntegerValue:[defaults integerForKey:@"morphInterval"]];
    }
    else if ([cls isEqualToString:@"VibeOrbitView"]) {
        [defaults registerDefaults:@{@"count":@200, @"speed":@10, @"spread":@10}];
        [countSlider setIntegerValue:[defaults integerForKey:@"count"]];
        [speedSlider setIntegerValue:[defaults integerForKey:@"speed"]];
        [spreadSlider setIntegerValue:[defaults integerForKey:@"spread"]];
    }
    else if ([cls isEqualToString:@"VibeSpheresView"]) {
        [defaults registerDefaults:@{@"sphereCount":@200, @"starCount":@3000, @"speed":@5, @"colorCycle":@5}];
        [countSlider setIntegerValue:[defaults integerForKey:@"sphereCount"]];
        [starFieldSlider setIntegerValue:[defaults integerForKey:@"starCount"]];
        [speedSlider setIntegerValue:[defaults integerForKey:@"speed"]];
        [colorCycleSlider setIntegerValue:[defaults integerForKey:@"colorCycle"]];
    }
    else if ([cls isEqualToString:@"HermesBoardView"]) {
        [defaults registerDefaults:@{@"clock":@YES, @"clockPosition":@0, @"seconds":@YES, @"image":@NO}];
        [clockCheckbox setState:[defaults boolForKey:@"clock"] ? NSControlStateValueOn : NSControlStateValueOff];
        [clockPositionPopup selectItemAtIndex:[defaults integerForKey:@"clockPosition"]];
        [secondsCheckbox setState:[defaults boolForKey:@"seconds"] ? NSControlStateValueOn : NSControlStateValueOff];
        [imageCheckbox setState:[defaults boolForKey:@"image"] ? NSControlStateValueOn : NSControlStateValueOff];
    }
    else if ([cls isEqualToString:@"P5AlertView"]) {
        [defaults registerDefaults:@{@"showAlert":@NO}];
        [showAlertCheckbox setState:[defaults boolForKey:@"showAlert"] ? NSControlStateValueOn : NSControlStateValueOff];
    }

    [self updateValueLabels];
    MGLog(@"  defaults loaded for %@", cls);
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
    else if ([cls isEqualToString:@"VibeToroidView"]) {
        js = [NSString stringWithFormat:
            @"if (window.applySettings) applySettings({shapeIndex:%ld, particles:%ld, speed:%ld, morphInterval:%ld});",
            [defaults integerForKey:@"shape"],
            [defaults integerForKey:@"particleCount"],
            [defaults integerForKey:@"speed"],
            [defaults integerForKey:@"morphInterval"]];
    }
    else if ([cls isEqualToString:@"VibeOrbitView"]) {
        js = [NSString stringWithFormat:
            @"if (window.applySettings) applySettings({count:%ld, speed:%ld, spread:%ld});",
            [defaults integerForKey:@"count"],
            [defaults integerForKey:@"speed"],
            [defaults integerForKey:@"spread"]];
    }
    else if ([cls isEqualToString:@"VibeSpheresView"]) {
        js = [NSString stringWithFormat:
            @"if (window.applySettings) applySettings({sphereCount:%ld, starCount:%ld, speed:%ld, colorCycle:%ld});",
            [defaults integerForKey:@"sphereCount"],
            [defaults integerForKey:@"starCount"],
            [defaults integerForKey:@"speed"],
            [defaults integerForKey:@"colorCycle"]];
    }
    else if ([cls isEqualToString:@"HermesBoardView"]) {
        js = [NSString stringWithFormat:
            @"if (window.applySettings) applySettings({clock:%@, clockPosition:%ld, seconds:%@, image:%@});",
            [defaults boolForKey:@"clock"] ? @"true" : @"false",
            [defaults integerForKey:@"clockPosition"],
            [defaults boolForKey:@"seconds"] ? @"true" : @"false",
            [defaults boolForKey:@"image"] ? @"true" : @"false"];
    }
    else if ([cls isEqualToString:@"P5AlertView"]) {
        js = [NSString stringWithFormat:
            @"if (window.applySettings) applySettings({showAlert:%@});",
            [defaults boolForKey:@"showAlert"] ? @"true" : @"false"];
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
    // Keep configSheet retained (the system owns it via the readonly strong
    // configureSheet property). We re-present the same window next time, so
    // don't nil controls here — configureSheet just reloads values.
    MGLog(@"  sheet ended, retained for reuse");
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
    else if ([cls isEqualToString:@"VibeToroidView"]) {
        [defaults setInteger:[shapePopup indexOfSelectedItem] forKey:@"shape"];
        [defaults setInteger:[particleCountSlider integerValue] forKey:@"particleCount"];
        [defaults setInteger:[speedSlider integerValue] forKey:@"speed"];
        [defaults setInteger:[morphIntervalSlider integerValue] forKey:@"morphInterval"];
    }
    else if ([cls isEqualToString:@"VibeOrbitView"]) {
        [defaults setInteger:[countSlider integerValue] forKey:@"count"];
        [defaults setInteger:[speedSlider integerValue] forKey:@"speed"];
        [defaults setInteger:[spreadSlider integerValue] forKey:@"spread"];
    }
    else if ([cls isEqualToString:@"VibeSpheresView"]) {
        [defaults setInteger:[countSlider integerValue] forKey:@"sphereCount"];
        [defaults setInteger:[starFieldSlider integerValue] forKey:@"starCount"];
        [defaults setInteger:[speedSlider integerValue] forKey:@"speed"];
        [defaults setInteger:[colorCycleSlider integerValue] forKey:@"colorCycle"];
    }
    else if ([cls isEqualToString:@"HermesBoardView"]) {
        [defaults setBool:[clockCheckbox state] == NSControlStateValueOn forKey:@"clock"];
        [defaults setInteger:[clockPositionPopup indexOfSelectedItem] forKey:@"clockPosition"];
        [defaults setBool:[secondsCheckbox state] == NSControlStateValueOn forKey:@"seconds"];
        [defaults setBool:[imageCheckbox state] == NSControlStateValueOn forKey:@"image"];
    }
    else if ([cls isEqualToString:@"P5AlertView"]) {
        [defaults setBool:[showAlertCheckbox state] == NSControlStateValueOn forKey:@"showAlert"];
    }

    [defaults synchronize];
    [self loadIndexWithConfig:YES];

    [[NSApplication sharedApplication] endSheet:configSheet];
    // Keep configSheet retained (the system owns it via the readonly strong
    // configureSheet property). We re-present the same window next time, so
    // don't nil controls here — configureSheet just reloads values.
    MGLog(@"  settings saved for %@", cls);
}

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
