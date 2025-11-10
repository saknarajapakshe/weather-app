# Personalized Weather Dashboard

A Flutter mobile application that displays personalized weather information based on a student index number.

## Features

✅ **Student Index Input**: Enter your student index to derive coordinates  
✅ **Coordinate Calculation**: Automatically calculates latitude and longitude from index  
✅ **Weather API Integration**: Fetches real-time weather data from Open-Meteo API  
✅ **Weather Display**: Shows temperature (°C), wind speed, and weather code  
✅ **Request URL Display**: Shows the exact API request URL for verification  
✅ **Loading Indicator**: Visual feedback while fetching data  
✅ **Error Handling**: Friendly error messages when network fails  
✅ **Offline Cache**: Saves last successful result and displays it when offline  
✅ **Cached Data Indicator**: Shows "(CACHED)" tag when displaying offline data  
✅ **Clean UI**: Material Design 3 with cards and proper layout

## Coordinate Derivation Formula

From student index (e.g., `194174`):

```
firstTwo = int(index[0..1])  // e.g., 19
nextTwo = int(index[2..3])   // e.g., 41
lat = 5 + (firstTwo / 10.0)  // Result: 6.9
lon = 79 + (nextTwo / 10.0)  // Result: 83.1
```

## API Used

**Open-Meteo API** (No API key required):

```
https://api.open-meteo.com/v1/forecast?latitude=LAT&longitude=LON&current_weather=true
```

## Dependencies

- `http: ^1.1.0` - For making HTTP requests to the weather API
- `shared_preferences: ^2.2.2` - For caching weather data locally
- `intl: ^0.19.0` - For formatting date/time

## Setup Instructions

1. **Install Flutter**: Make sure Flutter SDK is installed on your system
2. **Clone/Download**: Get the project files
3. **Install Dependencies**:
   ```bash
   flutter pub get
   ```
4. **Run the App**:
   ```bash
   flutter run
   ```

## How to Use

1. **Enter Student Index**: The app pre-fills with `194174` - change it to your index
2. **Tap "Fetch Weather"**: The app will:
   - Calculate coordinates from your index
   - Display lat/lon (2 decimal places)
   - Make API request to Open-Meteo
   - Show loading indicator
   - Display weather data with timestamp
   - Cache the result locally
3. **View Results**: See temperature, wind speed, weather code, and last updated time
4. **Check Request URL**: Scroll down to see the exact API URL used
5. **Test Offline Mode**:
   - Turn on Airplane Mode
   - Tap "Fetch Weather" again
   - See cached data with "CACHED" tag

## Project Structure

```
weather_app/
├── lib/
│   └── main.dart          # Main application code
├── android/               # Android platform files
├── ios/                   # iOS platform files
├── pubspec.yaml           # Dependencies configuration
└── README.md             # This file
```

## Implementation Details

### Coordinate Calculation

- Extracts first 4 digits from student index
- First two digits: used for latitude calculation
- Next two digits: used for longitude calculation
- Ensures coordinates fall within Sri Lanka region

### Weather Data Fetching

- Uses HTTP GET request to Open-Meteo API
- 10-second timeout for network requests
- Parses JSON response
- Extracts: temperature, windspeed, weathercode

### Caching System

- Uses `shared_preferences` package
- Saves all weather data as JSON
- Loads cached data on app startup
- Displays cached data when network fails
- Shows "CACHED" badge for offline data

### Error Handling

- Invalid index format detection
- Network timeout handling
- API error status codes
- User-friendly error messages
- Graceful fallback to cached data

## Testing Scenarios

### Online Mode

1. Enter valid student index
2. Tap "Fetch Weather"
3. Verify coordinates are calculated correctly
4. Verify weather data is displayed
5. Check request URL is visible

### Offline Mode

1. Fetch weather successfully (online)
2. Enable Airplane Mode
3. Tap "Fetch Weather" again
4. Verify error message appears
5. Verify cached data is shown with "CACHED" tag

## Deliverables Checklist

- [x] Full Flutter project
- [ ] report\_<index>.pdf with:
  - [ ] Student index
  - [ ] Coordinate formula explanation
  - [ ] Screenshot(s) showing request URL
  - [ ] 3-5 sentence reflection
- [ ] video\_<index>.mp4 (≤60s) showing:
  - [ ] Enter/confirm student index
  - [ ] Fetch weather (online)
  - [ ] Toggle Airplane Mode
  - [ ] Show error + cached state

## Screenshot Locations for Report

Include these in your report:

1. **Main Screen**: Student index input and fetch button
2. **Coordinates Display**: Showing calculated lat/lon
3. **Weather Data**: Temperature, wind speed, weather code, timestamp
4. **Request URL**: The exact API URL (visible at bottom)
5. **Cached State**: With "CACHED" tag when offline

## Reflection Template

```
During this project, I learned:
1. How to integrate REST APIs in Flutter using the http package
2. Implementing local data persistence with shared_preferences
3. Handling network errors and providing offline functionality
4. Creating clean, user-friendly UIs with Material Design

Challenges faced:
- [Your specific challenge]
- [How you solved it]

Key takeaway: [Your main learning]
```

## Notes

- Default student index: `224000X`
- Coordinates are displayed with 2 decimal precision
- Weather code is shown as raw number from API
- Last updated time uses device clock
- Cache persists between app sessions
- Works on Android, iOS, Windows, macOS, Linux, Web

## Author

Student Index: 224223N  
Date: November 10, 2025

## License

This project is for educational purposes as part of the Wireless Communication and Mobile Networks course.
