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

#define DebugLog(...)
//#define DebugLog NSLog

#import "WebSaverView.h"

@implementation WebSaverView

- (void)webView:(WKWebView *)sender didStartProvisionalLoadForFrame:(WKWebView *)frame
{
	DebugLog(@"webView:didStartProvisionalLoadForFrame: %@", frame);
}

- (void)webView:(WKWebView *)sender didCommitLoadForFrame:(WKWebView *)frame
{
	DebugLog(@"webView:didCommitLoadForFrame");
}

- (void)webView:(WKWebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WKWebView *)frame
{
	DebugLog(@"webView:didFailLoadWithError: %@", error);
}

- (void)webView:(WKWebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WKWebView *)frame
{
	DebugLog(@"webView:didFailProvisionalLoadWithError: %@", error);
}

- (void)webView:(WKWebView *)sender didFinishLoadForFrame:(WKWebView *)frame
{
	DebugLog(@"webView:didFinishLoadForFrame");
}

- (void)webView:(WKWebView *)sender didReceiveIcon:(NSImage *)image forFrame:(WKWebView *)frame
{
	DebugLog(@"webView:didReceiveIcon");
}

- (void)webView:(WKWebView *)sender serverRedirectedForDataSource:(WKWebView *)frame
{
	DebugLog(@"webView:serverRedirectedForDataSource");
}

- (void)webView:(WKWebView *)sender didReceiveTitle:(NSString *)title forFrame:(WKWebView *)frame
{
    DebugLog(@"webView:didReceiveTitle: %@", title);
}

- (id)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    DebugLog(@"webView:initWithFrame isPreview:%d", isPreview);
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
		[self setAnimationTimeInterval:0.5];

		webView = [[WKWebView alloc] initWithFrame:frame];

        // Any user agent will do
        [webView setCustomUserAgent:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8) AppleWebKit/536.25 (KHTML, like Gecko) Version/6.0 Safari/536.25"];

        // Prevent a white flash when first showing the view
        [webView setValue: @NO forKey: @"drawsBackground"];

        if (isPreview) [self scaleUnitSquareToSize:NSMakeSize( 0.25, 0.25 )];

		[self addSubview:webView];
	}

    return self;
}

- (void)setFrame:(NSRect)frameRect
{
	DebugLog(@"NSView:setFrame");
	//DebugLog(@"frameRect %d,%d %dx%d\n", frameRect.origin.x, frameRect.origin.y, frameRect.size.width, frameRect.size.height);
	[super setFrame:frameRect];
	[webView setFrame:frameRect];
	[webView setFrameSize:[webView convertSize:frameRect.size fromView:nil]];
}

- (void)startAnimation
{
	DebugLog(@"webView:startAnimation");

    [super startAnimation];

    [webView loadRequest:[NSMutableURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"index" ofType:@"html"]]]];
}

- (void)stopAnimation
{
	DebugLog(@"webView:stopAnimation");

    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:"]]];

    [super stopAnimation];
}

- (void)doKeyUp:(NSTimer*)theTimer {
	//DebugLog(@"doKeyUp");
    [[NSApplication sharedApplication] sendEvent:[NSEvent keyEventWithType:NSEventTypeKeyUp
		location:      NSMakePoint(1,1)
		modifierFlags: 0
		timestamp:     [[NSDate date] timeIntervalSinceReferenceDate]
		windowNumber:  [[self window] windowNumber]
		context:       [NSGraphicsContext currentContext]
		characters:    [theTimer userInfo]
		charactersIgnoringModifiers:[theTimer userInfo]
		isARepeat:     NO
		keyCode:       0]];
}


- (void)doKeyDown:(NSTimer*)theTimer {
	//DebugLog(@"doKeyDown");
    [[NSApplication sharedApplication] sendEvent:[NSEvent keyEventWithType:NSEventTypeKeyDown
		location:      NSMakePoint(1,1)
		modifierFlags: 0
		timestamp:     [[NSDate date] timeIntervalSinceReferenceDate]
		windowNumber:  [[self window] windowNumber]
		context:       [NSGraphicsContext currentContext]
		characters:    [theTimer userInfo]
		charactersIgnoringModifiers:[theTimer userInfo]
		isARepeat:     NO
		keyCode:      0]];
}


- (void)animateOneFrame { }

- (BOOL)hasConfigureSheet { return NO; }

@end
