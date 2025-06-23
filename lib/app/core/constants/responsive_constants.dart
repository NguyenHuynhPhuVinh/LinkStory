/// Responsive design constants and breakpoints
class ResponsiveConstants {
  // Design sizes
  static const double designWidth = 375.0; // iPhone X width
  static const double designHeight = 812.0; // iPhone X height

  // Breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  static const double desktopBreakpoint = 1200.0;

  // Grid configurations
  static const int mobileGridCount = 2;
  static const int tabletGridCount = 3;
  static const int desktopGridCount = 4;

  // Aspect ratios
  static const double mobileAspectRatio = 0.7;
  static const double tabletAspectRatio = 0.75;
  static const double desktopAspectRatio = 0.8;

  // Spacing
  static const double smallSpacing = 8.0;
  static const double mediumSpacing = 16.0;
  static const double largeSpacing = 24.0;
  static const double extraLargeSpacing = 32.0;

  // Font sizes
  static const double smallFontSize = 12.0;
  static const double mediumFontSize = 14.0;
  static const double largeFontSize = 16.0;
  static const double extraLargeFontSize = 18.0;
  static const double titleFontSize = 20.0;
  static const double headingFontSize = 24.0;

  // Icon sizes
  static const double smallIconSize = 16.0;
  static const double mediumIconSize = 20.0;
  static const double largeIconSize = 24.0;
  static const double extraLargeIconSize = 32.0;

  // Button sizes
  static const double smallButtonHeight = 32.0;
  static const double mediumButtonHeight = 40.0;
  static const double largeButtonHeight = 48.0;

  // Border radius
  static const double smallRadius = 4.0;
  static const double mediumRadius = 8.0;
  static const double largeRadius = 12.0;
  static const double extraLargeRadius = 16.0;

  // Elevation
  static const double lowElevation = 2.0;
  static const double mediumElevation = 4.0;
  static const double highElevation = 8.0;

  // Navigation bar
  static const double navBarHeight = 60.0;
  static const double navBarPadding = 16.0;
  static const double navBarIconSize = 24.0;
  static const double navBarFontSize = 12.0;

  // App bar
  static const double appBarHeight = 56.0;
  static const double appBarTitleFontSize = 18.0;

  // Card
  static const double cardPadding = 16.0;
  static const double cardMargin = 8.0;
  static const double cardRadius = 12.0;
  static const double cardElevation = 2.0;

  // List item
  static const double listItemHeight = 72.0;
  static const double listItemPadding = 16.0;

  // Bottom sheet
  static const double bottomSheetRadius = 20.0;
  static const double bottomSheetPadding = 20.0;

  // Dialog
  static const double dialogRadius = 16.0;
  static const double dialogPadding = 24.0;

  // Minimum touch target size (accessibility)
  static const double minTouchTargetSize = 44.0;

  // Maximum content width for large screens
  static const double maxContentWidth = 1200.0;

  // Safe area padding
  static const double safeAreaPadding = 16.0;

  // Animation durations
  static const int shortAnimationDuration = 200;
  static const int mediumAnimationDuration = 300;
  static const int longAnimationDuration = 500;

  // Opacity values
  static const double lowOpacity = 0.1;
  static const double mediumOpacity = 0.3;
  static const double highOpacity = 0.6;
  static const double veryHighOpacity = 0.8;

  // Z-index values
  static const int backgroundZIndex = 0;
  static const int contentZIndex = 1;
  static const int overlayZIndex = 10;
  static const int modalZIndex = 100;
  static const int tooltipZIndex = 1000;

  // Reading settings
  static const double minReadingFontSize = 12.0;
  static const double maxReadingFontSize = 24.0;
  static const double defaultReadingFontSize = 16.0;
  static const double readingLineHeight = 1.6;
  static const double readingPadding = 16.0;

  // Grid spacing
  static const double gridSpacing = 16.0;
  static const double gridRunSpacing = 16.0;

  // Image sizes
  static const double smallImageSize = 40.0;
  static const double mediumImageSize = 80.0;
  static const double largeImageSize = 120.0;
  static const double coverImageWidth = 150.0;
  static const double coverImageHeight = 200.0;

  // Loading indicator
  static const double loadingIndicatorSize = 24.0;
  static const double largeLoadingIndicatorSize = 48.0;

  // Shimmer
  static const double shimmerRadius = 8.0;
  static const int shimmerAnimationDuration = 1500;

  // Snackbar
  static const double snackbarRadius = 8.0;
  static const double snackbarPadding = 16.0;
  static const int snackbarDuration = 3000;

  // Progress indicator
  static const double progressIndicatorHeight = 4.0;
  static const double progressIndicatorRadius = 2.0;

  // Divider
  static const double dividerThickness = 1.0;
  static const double dividerIndent = 16.0;

  // Tab bar
  static const double tabBarHeight = 48.0;
  static const double tabBarIndicatorHeight = 2.0;

  // Slider
  static const double sliderHeight = 40.0;
  static const double sliderThumbRadius = 10.0;
  static const double sliderTrackHeight = 4.0;

  // Switch
  static const double switchWidth = 51.0;
  static const double switchHeight = 31.0;

  // Checkbox
  static const double checkboxSize = 20.0;

  // Radio button
  static const double radioButtonSize = 20.0;

  // Text field
  static const double textFieldHeight = 48.0;
  static const double textFieldRadius = 8.0;
  static const double textFieldPadding = 16.0;

  // Floating action button
  static const double fabSize = 56.0;
  static const double miniFabSize = 40.0;

  // Chip
  static const double chipHeight = 32.0;
  static const double chipRadius = 16.0;
  static const double chipPadding = 12.0;

  // Badge
  static const double badgeSize = 16.0;
  static const double badgeRadius = 8.0;

  // Tooltip
  static const double tooltipRadius = 4.0;
  static const double tooltipPadding = 8.0;
  static const double tooltipFontSize = 12.0;

  // Expansion tile
  static const double expansionTileHeight = 56.0;
  static const double expansionTilePadding = 16.0;

  // Stepper
  static const double stepperIconSize = 24.0;
  static const double stepperPadding = 16.0;

  // Data table
  static const double dataTableRowHeight = 48.0;
  static const double dataTableHeaderHeight = 56.0;
  static const double dataTablePadding = 16.0;

  // Calendar
  static const double calendarDaySize = 40.0;
  static const double calendarHeaderHeight = 48.0;

  // Time picker
  static const double timePickerDialSize = 280.0;
  static const double timePickerHandWidth = 2.0;

  // Color picker
  static const double colorPickerSize = 40.0;
  static const double colorPickerRadius = 20.0;

  // Range slider
  static const double rangeSliderHeight = 40.0;
  static const double rangeSliderThumbRadius = 10.0;
  static const double rangeSliderTrackHeight = 4.0;
}

/// Device type enum
enum DeviceType {
  mobile,
  tablet,
  desktop,
}

/// Screen size helper
class ScreenSize {
  static DeviceType getDeviceType(double width) {
    if (width < ResponsiveConstants.mobileBreakpoint) {
      return DeviceType.mobile;
    } else if (width < ResponsiveConstants.tabletBreakpoint) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  static bool isMobile(double width) => getDeviceType(width) == DeviceType.mobile;
  static bool isTablet(double width) => getDeviceType(width) == DeviceType.tablet;
  static bool isDesktop(double width) => getDeviceType(width) == DeviceType.desktop;
}
