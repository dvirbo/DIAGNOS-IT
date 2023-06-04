# DIAGNOS-IT

Draw Shapes App
This Flutter app helps users draw shapes on images. The user needs to enter their name and age on the home page. After clicking the 'Draw Shapes' button, they will be taken to the canvas page where they can draw shapes on pre-loaded images. The app includes support for accelerometer sensors and supports Firebase for image storage.
Installation
To set up the project, follow these steps:
Ensure you have Flutter and Dart installed in your machine. For more information, refer to the official Flutter documentation.
Clone the repository.
Enter the project directory and run flutter pub get to get all necessary dependencies.
Run flutter run in your terminal to run the application on an emulator or a connected device.
Usage
The app has two pages: Home page and Canvas page.
Home Page
The home page contains two text fields: Name and Age. The user has to fill both fields to enable the 'Draw Shapes' button. Clicking on the button will navigate the user to the canvas page.
Canvas Page
The canvas page displays a pre-loaded image and an area for the user to draw shapes under the image. Users can interact with the canvas by:
Drawing shapes using touch or mouse interactions.
Use the left and right arrow buttons to switch between different pre-loaded images.
Click the 'Save' button at the bottom to save the drawn shapes to the image on Firebase Storage.
Click the 'Clear Canvas' button on the app bar to clear the canvas
Click the 'Exit' button on the app bar to return to the home page.
Contributing
Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change. Please make sure to update tests as appropriate.
License
This project is licensed under the MIT License.