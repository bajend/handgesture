# Setup Instructions

## Prerequisites

*   **Xcode 13.0+**
*   **iOS 15.0+ Device** (Physical device required for camera features)
*   **CocoaPods** (Install via `sudo gem install cocoapods` if you don't have it)

## Step 1: Install Dependencies

1.  Open Terminal and navigate to the project directory:
    ```bash
    cd path/to/TestProductdummy
    ```

2.  Install the required pods:
    ```bash
    pod install
    ```

3.  **Crucial Step**: Close any open Xcode windows. From now on, **always** open the workspace file, not the project file:
    ```bash
    open TestProductdummy.xcworkspace
    ```

## Step 2: Verify Project Configuration

1.  **Signing & Capabilities**:
    *   Select the project in the Project Navigator (blue icon).
    *   Select the **TestProductdummy** target.
    *   Go to the **Signing & Capabilities** tab.
    *   Ensure a valid **Team** is selected.
    *   Ensure the **Bundle Identifier** is unique if you are deploying to your own device.

2.  **Camera Permissions**:
    *   Verify that `Privacy - Camera Usage Description` is present in the **Info** tab.
    *   (This should already be set up, but good to double-check).

3.  **Model File**:
    *   Ensure `gesture_recognizer.task` is present in the project navigator and is included in the "Copy Bundle Resources" build phase.

## Step 3: Build and Run

1.  Connect your iPhone/iPad to your Mac.
2.  Select your device from the run destination menu in Xcode.
3.  Build and Run (**Cmd + R**).
4.  On your device, grant camera permissions when prompted.

## Troubleshooting

*   **"No such module 'MediaPipeTasksVision'"**:
    *   Ensure you opened `.xcworkspace` and not `.xcodeproj`.
    *   Try running `pod install` again.

*   **"Code signing failed"**:
    *   Go to **Signing & Capabilities** and ensure "Automatically manage signing" is checked and a valid Team is selected.

*   **App crashes on launch**:
    *   Check the Xcode console for error messages.
    *   Ensure `gesture_recognizer.task` is correctly added to the target.

*   **Camera is black**:
    *   Check if you granted camera permissions.
    *   Verify the privacy key in `Info.plist`.
