# MediaPipe Hand Gesture Recognition - Setup Instructions

## Step 1: Install CocoaPods Dependencies

Run the following command in your terminal from the project directory:

```bash
cd /Users/I838841/Desktop/TestProductdummy
pod install
```

After installation, **close your current Xcode project** and open the newly created `.xcworkspace` file instead:
```bash
open TestProductdummy.xcworkspace
```

## Step 2: Download the Gesture Recognizer Model

1. Download the gesture recognizer model from:
   https://storage.googleapis.com/mediapipe-models/gesture_recognizer/gesture_recognizer/float16/1/gesture_recognizer.task

2. In Xcode, drag and drop the `gesture_recognizer.task` file into your project
3. Make sure "Copy items if needed" is checked
4. Make sure the file is added to the TestProductdummy target

## Step 3: Update Info.plist for Camera Permission

You need to add camera usage description to your Info.plist:

1. In Xcode, select the TestProductdummy project in the Navigator
2. Select the TestProductdummy target
3. Go to the "Info" tab
4. Click the "+" button to add a new key
5. Add: **Privacy - Camera Usage Description**
6. Set the value to: "This app requires camera access to perform hand gesture recognition"

Or you can add this directly to Info.plist file:
```xml
<key>NSCameraUsageDescription</key>
<string>This app requires camera access to perform hand gesture recognition</string>
```

## Step 4: Add Files to Xcode Project

Make sure all the new Swift files are added to your Xcode project:
- GestureRecognizerService.swift
- CameraManager.swift
- CameraView.swift
- ContentView.swift (updated)

If they're not visible in Xcode, drag them from Finder into your Xcode project.

## Step 5: Build and Run

1. Select your target device or simulator
2. Build the project (⌘+B)
3. Run the app (⌘+R)
4. Grant camera permission when prompted
5. Try making hand gestures in front of the camera!

## Supported Gestures

The model recognizes these gestures:
- None
- Closed_Fist
- Open_Palm
- Pointing_Up
- Thumb_Down
- Thumb_Up
- Victory
- ILoveYou

## Troubleshooting

- If you get build errors about MediaPipeTasksVision, make sure you opened the .xcworkspace file, not the .xcodeproj
- If camera doesn't work, check that you've added the camera permission to Info.plist
- If the model isn't found, verify the gesture_recognizer.task file is in your project and added to the target
- Make sure you're running on a physical device or simulator with iOS 15.0+
