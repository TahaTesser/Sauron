# AGENTS.md

## Overview

This project provides a unified desktop application for generating, running, and validating screenshot-based UI tests across Android (Jetpack Compose) and iOS (Swift/UIView/SwiftUI) platforms. It integrates native rendering and diffing tools with a consistent developer experience in a desktop UI.

* ✅ Generate platform-specific screenshot tests:

  * Android: `@Preview`-annotated composables in `screenshotTest` source set.
  * iOS: Swift snapshot tests using `FBSnapshotTestCase` or `SnapshotTesting`.
* ✅ Run native test commands:

  * Android: `./gradlew validateDebugScreenshotTest` / `recordDebugScreenshotTest`
  * iOS: `xcodebuild test` with configurable simulator and env flags
* ✅ Parse output to collect:

  * Baseline, actual, and diff images
  * Test result logs and failure cases
* ✅ Perform or ingest pixel/perceptual diffs
* ✅ Generate unified diff report:

  * Side-by-side collage of expected, actual, and diff images
  * Rendered consistently across platforms

### App Features

* Generate Tests – Select components/screens and generate screenshot tests for chosen modules (Android/iOS).
* Run Tests – Trigger native screenshot test runs (Android, iOS, or both) from the app.
* Review Diffs – Collect and visualize results with highlighters.
* Record Baselines – Update baseline images after intentional UI changes.
* Export Report – Generate HTML or bundled visual diff summaries.

### Notes

* Android tests use Compose Preview Screenshot Testing
* iOS tests use FBSnapshotTestCase (preferred) or SnapshotTesting
* All diffs and images are filesystem-based and can be stored for CI consumption
