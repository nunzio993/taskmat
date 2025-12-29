# TaskMate Mobile App

## Setup & Running

To run the application with a consistent port (useful for keeping the same browser tab open), use the `--web-port` flag.

### Recommended Command for Development
```bash
flutter run -d chrome --web-port 3000
```
This will always launch the app at `http://localhost:3000`.

### Development Tips
- **Hot Restart**: Do **NOT** stop and relaunch the app to see changes. Press `r` (lowercase) or `R` (uppercase) in the terminal where the app is running. This applies changes almost instantly (sub-1 second) and retains the session state (usually).
- **Slow Loading**: The initial blue loading screen is normal for Flutter Web in **Debug Mode** because it downloads the entire debugging engine and tools.
    - **Performance**: The app is much faster in `profile` or `release` mode (command: `flutter run -d chrome --release`), but you lose debugging capabilities.
    - **Renderer**: If loading is too slow, try `flutter run -d chrome --web-renderer html --web-port 3000`. It loads faster but might look slightly different (font rendering).

## Folder Structure
- `lib/core`: Shared widgets, theme, constants.
- `lib/features`: Feature-based modules (Auth, Tasks, Home).
