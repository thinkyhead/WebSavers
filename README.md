# WebSavers

WebKit-based Screensavers for macOS implemented as HTML/CSS/JS in an Xcode (14.3) project.

Adapted from [WebSaver](//github.com/brockgr/websaver) by @brockgr, *et.al.*, and modified to use a local `index.html` file.

There are currently no configuration dialogs or exposed options, but since there are "themes" implemented in **Matrix** and **MatrixGrid** that will be added later, with the configuration values passed to the script as URL arguments.

## Included Examples:

- **Matrix** is adapted from a common "Matrix Rain" HTML Canvas example project that appears in many places on the web. It has been slightly improved by adding a scanline overlay effect.
- **Matrix3D** expands on **Matrix**, applying the basic "Matrix Rain" Canvas-based animation to the sides of a rotating cube, implemented in `THREE.js`.
- **MatrixGrid** is a re-implementation of **Matrix** using CSS animations for a cleaner result with less overhead and no incomplete erase. This version creates a fixed grid of DIVs and produces the animation just by setting the `innerHTML` and manipulating the `opacity`, `display`, and `color` CSS attributes.
- **Starfield** is a simple "Starfield" animation adapted from a [CodePen sketch](//codepen.io/nodws/pen/pejBNb), which itself is based on [demo code](//github.com/curran/HTML5Examples/tree/gh-pages/canvas/starfield) by @curran.
- **Stringy** is a cool "3D Strings" animation adapted from a [CodePen sketch](//codepen.io/yashbhardwaj/pen/QWKKgb).

## Build and Install

- Open the `WebSavers.xcodeproj` file in Xcode.
- Select one of the schemes in the **Product** > **Schemes** submenu.
- Run the **Product** > **Build for** > **Running** command.
- Right-click on an item in the "Products" group and choose **Show in Finder**.
- Double-click any `.saver` file to install it.

## Add a ScreenSaver

- Create a new Target from an existing one using the **Duplicate** command in the WebSavers Project panel.
- Edit the Build Settings to use `Info.plist` as the .plist file.
- Delete the newly-created `Info-blah.plist` file (and Trash it).
- Create a folder with your new `index.html` and any other files that you need for implementation.
- Drag the folder onto the project's "Resources" group in Xcode.
- Use the Inspector to ensure that the files only belong to your new Target.
- Also make sure the files from the Target that you duplicated are unchecked for the new Target.
- Select **Product** > **Scheme** > **Manage Schemes…** and add a new Scheme (if needed). Give it a good name. Feel free to remove the Test Plan from the scheme.
- Edit the "All Savers" Scheme and add your new Scheme to the "Build" list. Only "Run" and "Archive" are needed.
