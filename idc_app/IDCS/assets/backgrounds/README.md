# 제어판 배경

Backgrounds for the live control panel are drawn in code
(`lib/theme/panel_background.dart`) rather than shipped as images: a painter
weighs nothing, stays sharp at any screen size, and follows the light/dark
palette on its own.

To add an image-backed option instead, drop the file here, list it under
`assets:` in `pubspec.yaml`, and add a `PanelBackground` entry carrying
`assetPath` in place of `painterOf`.
