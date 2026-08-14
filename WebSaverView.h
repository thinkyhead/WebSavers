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

// Each saver target compiles this view under its own class name via the
// WEBSAVER_CLASS build setting (e.g. MatrixView, StarfieldView). Giving every
// bundle a distinct principal class prevents Objective-C class shadowing when
// ScreenSaverEngine loads multiple saver bundles into the same process, which
// otherwise causes the wrong saver to be instantiated on selection.
#ifndef WEBSAVER_CLASS
  #define WEBSAVER_CLASS WebSaverView
#endif

@interface WEBSAVER_CLASS : ScreenSaverView 
{
    WKWebView *webView;
}
@end
