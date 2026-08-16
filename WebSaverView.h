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

#ifndef WEBSAVER_CLASS
  #define WEBSAVER_CLASS WebSaverView
#endif

@interface WEBSAVER_CLASS : ScreenSaverView <WKNavigationDelegate>
{
    WKWebView *webView;
    NSWindow *configSheet;

    // Matrix / MatrixGrid
    NSPopUpButton *themePopup;
    NSButton *alphaCheckbox;
    NSButton *punctuationCheckbox;
    NSPopUpButton *overlayPopup;
    NSButton *flipCheckbox;
    NSSlider *changeSlider;
    NSTextField *changeLabel;
    NSSlider *fpsSlider;
    NSTextField *fpsLabel;
    NSSlider *minSpeedSlider;
    NSTextField *minSpeedLabel;
    NSSlider *maxSpeedSlider;
    NSTextField *maxSpeedLabel;
    NSSlider *fadeSlider;
    NSTextField *fadeLabel;

    // Starfield
    NSSlider *starCountSlider;
    NSTextField *starCountLabel;
    NSSlider *speedSlider;
    NSTextField *speedLabel;

    // Stringy
    NSSlider *trailCountSlider;
    NSTextField *trailCountLabel;
    NSSlider *trailLengthSlider;
    NSTextField *trailLengthLabel;

    // Matrix3D
    NSPopUpButton *colorPopup;
    NSSlider *fontSizeSlider;
    NSTextField *fontSizeLabel;

    // VibeOrbit / VibeSpheres
    NSSlider *countSlider;
    NSTextField *countLabel;
    NSSlider *spreadSlider;
    NSTextField *spreadLabel;

    // VibeSpheres
    NSSlider *starFieldSlider;
    NSTextField *starFieldLabel;
    NSSlider *colorCycleSlider;
    NSTextField *colorCycleLabel;

    // VibeToroid
    NSPopUpButton *shapePopup;
    NSSlider *particleCountSlider;
    NSTextField *particleCountLabel;
    NSSlider *morphIntervalSlider;
    NSTextField *morphIntervalLabel;

    // HermesBoard
    NSButton *clockCheckbox;
    NSPopUpButton *clockPositionPopup;
    NSButton *secondsCheckbox;
    NSButton *imageCheckbox;

    NSTimer *statsTimer;
    host_cpu_load_info_data_t prevCpuLoad;
    bool hasPrevCpu;
}

- (IBAction)configCancel:(id)sender;
- (IBAction)configOK:(id)sender;
- (IBAction)sliderChanged:(id)sender;

@end
