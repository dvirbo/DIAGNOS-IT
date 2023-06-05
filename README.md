# DIAGNOS-IT

The Handwriting Analysis App for Children is an innovative application developed using Flutter that aims to
revolutionize the way we analyze and assess children's handwriting skills. The app provides a comprehensive diagnostic tool to
evaluate a child's writing abilities and determine their progress in comparison to their peers, both nationwide and within
their own class or kindergarten

# Installation
To set up the project, follow these steps:
1.Ensure you have Flutter and Dart installed in your machine. For more information, refer to the official Flutter documentation.
2.Clone the repository.
3. Enter the project directory and run flutter pub get to get all necessary dependencies.
4. Run flutter run in your terminal to run the application on an emulator or a connected device.
# Usage
The app has two pages (currently): Home page and Canvas page.
## Home Page
The home page contains two text fields: Name and Age. The user has to fill both fields to enable the 'Draw Shapes' button. Clicking on the button will navigate the user to the canvas page.
## Canvas Page
The canvas page displays a pre-loaded image and an area for the user to draw shapes under the image. Users can interact with the canvas by:
Drawing shapes using touch or mouse interactions.
Use the left and right arrow buttons to switch between different pre-loaded images.
Click the 'Save' button at the bottom to save the drawn shapes to the image on Firebase Storage.
Click the 'Clear Canvas' button on the app bar to clear the canvas
Click the 'Exit' button on the app bar to return to the home page.
# Contributing
Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change. Please make sure to update tests as appropriate.
# License
This project is licensed under the MIT License.
