// *.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.* //
// *                                                                                           * //
// *                             _   _               __  __       _   _                        * //
// *         __      _____  __ _| |_| |__   ___ _ __|  \/  | __ _| |_| |_ ___ _ __ ___         * //
// *         \ \ /\ / / _ \/ _` | __| '_ \ / _ \ '__| |\/| |/ _` | __| __/ _ \ '__/ __|        * //
// *          \ V  V /  __/ (_| | |_| | | |  __/ |  | |  | | (_| | |_| ||  __/ |  \__ \        * //
// *           \_/\_/ \___|\__,_|\__|_| |_|\___|_|  |_|  |_|\__,_|\__|\__\___|_|  |___/        * //
// *                                                                                           * //
// *                                                                                           * //
// *.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.* //
// *                                                                                           * //
// * This app is designed to pull weather data for Monterrey and display it on a single,       * //
// * landscape screen mode and update values either daily (for average day values), or         * //
// * constantly (for current values like temperature)                                          * //
// * https://openweathermap.org/                                                               * //
// *                                                                                           * //
// * -- Revision --                                                                            * //
// *   2024-03-16 -- version 1.0.0, the first usable                                           * //
// *                                                                                           * //
// * -- Author --                                                                              * //
// *   Alberto Bortoni                                                                         * //
// *                                                                                           * //
// * -- TODOS --                                                                               * //
// *                                                                                           * //
// *                                                                                           * //
// ~.~`~.~`~.~`~.~`~.~`~.~`~.~`~.~`~.~`~.~`~.~`~.~`~.~`~.~`~.~`~.~`~.~`~.~`~.~`~.~`~.~`~.~`~.~`~ //

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';
import 'myapp_styles.dart';

// ********************************************************************************************* //
// *                                      MAIN APP CLASS                                       * //
// * ----------------------------------------------------------------------------------------- * //
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  //|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*
  //|* ----------------------------------------------- WIDGETS
  @override
  Widget build(BuildContext context) {
    double screenWidthPhone = MediaQuery.of(context).size.width;
    double screenHeightPhone = MediaQuery.of(context).size.height;

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);

    return MaterialApp(
      title: 'weatherMatters',
      theme: ThemeData(
        primarySwatch: myIvoryMaterialColor,
        colorScheme: const ColorScheme.dark(
          background: myDarkColor,
          onBackground: myDarkColor,
          primary: myIvoryColor,
          onPrimary: myIvoryColor,
          secondary: myIvoryColor,
          onSecondary: myIvoryColor,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(style: raisedButtonStyle),
        toggleButtonsTheme: toggleButtonStyle,
        textTheme: const TextTheme(
          bodyLarge: myTextStyle,
          labelLarge: myButtonTextStyle,
          displayLarge: myTextStyle,
          displayMedium: myTextStyle,
        ),
      ),
      home: HomeScreen(screenWidthPhone: screenWidthPhone, screenHeightPhone: screenHeightPhone),
    );
  }
}

//EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF//