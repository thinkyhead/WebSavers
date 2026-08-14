//
//  WebSaverView.h
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

#import <ScreenSaver/ScreenSaver.h>
#import <WebKit/WebKit.h>

// Debug logging macro (available to base and all subclass files)
#define MGLog(...) NSLog(@"[MG] " __VA_ARGS__)

// Base class that loads index.html from the bundle.
// Subclasses (one per saver) override the config-sheet hooks so only the
// current saver's controls/defaults/JS-injection code is built and run.
@interface WebSaverView : ScreenSaverView <WKNavigationDelegate>
{
@protected
    WKWebView *webView;
    BOOL isPreviewMode;
    NSWindow *configSheet;
}

// Lifecycle
- (id)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview;
- (void)startAnimation;
- (void)stopAnimation;
- (void)screensaverWillStop:(NSNotification*)note;

// Configuration
- (BOOL)hasConfigureSheet;
- (NSWindow*)configureSheet;

// Config-sheet hooks (override in subclasses)
- (NSString*)saverName;            // defaults to NSStringFromClass([self class])
- (CGFloat)configSheetHeight;      // defaults to 440
- (void)buildConfigSheet;          // add this saver's controls
- (void)loadDefaultsIntoSheet;     // populate controls from defaults
- (void)saveConfigSheet;           // write controls back to defaults (sync!)
- (NSString*)settingsJS;           // applySettings(...) JS injected after load
- (void)updateValueLabels;         // refresh value labels next to sliders
- (void)releaseControls;           // nil out control ivars (call super)

// Shared helpers
- (NSTextField*)labelAt:(NSRect)frame text:(NSString*)text alignment:(NSTextAlignment)align;
- (NSTextField*)valueLabelAt:(NSRect)frame;
- (NSButton*)checkboxAt:(NSRect)frame title:(NSString*)title;
- (ScreenSaverDefaults*)defaults;
- (void)loadIndexWithConfig:(BOOL)useConfig;

@end

// ============================================================================
// Individual saver classes - each implements only its own settings/behavior
// ============================================================================

// Matrix rain (classic)
@interface MatrixView : WebSaverView
@end

// Matrix grid with CSS animations
@interface MatrixGridView : MatrixView
@end

// Matrix 3D cube
@interface Matrix3DView : WebSaverView
@end

// Starfield animation
@interface StarfieldView : WebSaverView
@end

// Stringy 3D strings
@interface StringyView : WebSaverView
@end

// Vibe series - toroid morphing shapes
@interface VibeToroidView : WebSaverView
@end

// Vibe series - orbiting spheres
@interface VibeOrbitView : WebSaverView
@end

// Vibe series - solar system
@interface VibeSolarSystemView : WebSaverView
@end

// Vibe series - spheres with starfield
@interface VibeSpheresView : WebSaverView
@end
