// *.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.* //
// *                                     HOME SCREEN                                           * //
// *.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.* //
// *                                                                                           * //
// * This is the only functional screen of the app showing the weather                         * //
// *                                                                                           * //
// * -- Revision --                                                                            * //
// *   2024-04-25 -- version 1.0.0, the first usable                                           * //
// *                                                                                           * //
// * -- Author --                                                                              * //
// *   Alberto Bortoni                                                                         * //
// *                                                                                           * //
// * -- TODOS --                                                                               * //
// *                                                                                           * //
// *                                                                                           * //
// ~.~`~.~`~.~`~.~`~.~`~.~`~.~`~.~`~.~`~.~`~.~`~.~`~.~`~.~`~.~`~.~`~.~`~.~`~.~`~.~`~.~`~.~`~.~`~ //

import 'package:flutter/material.dart';
import 'myapp_styles.dart';
import 'dart:async';
import 'weather_fetcher.dart';
import 'package:background_fetch/background_fetch.dart';

// ********************************************************************************************* //
// *                                     HOME SCREEN CLASS                                     * //
// * ----------------------------------------------------------------------------------------- * //
class HomeScreen extends StatefulWidget {
  final double screenWidthPhone;
  final double screenHeightPhone;

  const HomeScreen({
    super.key,
    required this.screenWidthPhone,
    required this.screenHeightPhone,
  });

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*
  //|* --------------------------------------------- VARIABLES
  static const double row1Height = 70.0;
  static const double row2Height = 163.0;
  static const double row3Height = 163.0;
  static const double containerSpacing = 8.0;
  static const double borderWidth = 2;
  static const double screenWidth = 890;
  static const double screenHeight = 410;

  late String currentTime;

  WeatherServices weatherServices = WeatherServices();
  late Map<String, dynamic> dailyValues = weatherServices.dailyValuesDefault;
  late Map<String, dynamic> currentValues = weatherServices.currentValuesDefault;

  bool dailyValuesAged = true;
  bool currentValuesAged = true;

  //|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*
  //|* ----------------------------------------- CLASS METHODS
  Future<void> _updateDailyValues() async {
    Map<String, dynamic> newDailyValues = await weatherServices.dailyWeatherServices();
    setState(() {
      dailyValues = newDailyValues;
    });
  }

  Future<void> _updateCurrentValues() async {
    Map<String, dynamic> newCurrentValues = await weatherServices.currentWeatherServices();
    setState(() {
      currentValues = newCurrentValues;
    });
  }

  bool isDataOld() {
    // get the timestamps
    DateTime now = DateTime.now().toLocal();

    bool currentValuesAged = now.difference(currentValues['dt']).inMinutes > 21;
    bool dailyValuesAged = now.difference(dailyValues['dt']).inHours > 25;

    return (dailyValuesAged || currentValuesAged);
  }

  void updateTime() {
    DateTime now = DateTime.now();
    setState(() {
      currentTime = "${_getFormattedDate(now)} | ${_getFormattedTime(now)}";
    });
  }

  String _getFormattedDate(DateTime dateTime) {
    return "${_getWeekday(dateTime)}, ${_getMonth(dateTime)} ${dateTime.day}${_getDaySuffix(dateTime.day)}";
  }

  String _getWeekday(DateTime dateTime) {
    List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[dateTime.weekday - 1];
  }

  String _getMonth(DateTime dateTime) {
    List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[dateTime.month - 1];
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  String _getFormattedTime(DateTime dateTime) {
    String hour = dateTime.hour.toString().padLeft(2, '0');
    String minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _initializeWeatherServices() async {
    await weatherServices.initialize();
    _updateDailyValues();
    _updateCurrentValues();
  }

  //|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*
  //|* ------------------------------------ OVERRIDDEN METHODS
  @override
  void initState() {
    super.initState();
    updateTime();
    _initializeWeatherServices();

    // Update time every second
    Timer.periodic(const Duration(seconds: 10), (timer) {
      updateTime();
    });

    // Configure background fetch to get weather data even on bacground
    BackgroundFetch.configure(
      BackgroundFetchConfig(
        minimumFetchInterval: 15, //minutes
        forceAlarmManager: false,
        stopOnTerminate: true,
        startOnBoot: false,
        enableHeadless: true,
      ),
      (String taskId) async {
        // Fetch event callback
        await _updateCurrentValues();

        // Check if it's 5 am
        DateTime now = DateTime.now();
        if (now.hour == 5) {
          await _updateDailyValues();
        }
      },
    );
  }

  //|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*
  //|* ----------------------------------------------- WIDGETS
  @override
  Widget build(BuildContext context) {
    //double screenWidth = widget.screenWidth;
    //double screenHeight = widget.screenHeight;
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Row 1: Header
          Container(
            height: row1Height,
            width: screenWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: Colors.transparent,
                width: borderWidth,
              ),
            ),
            padding: const EdgeInsets.only(left: 10, top: 5, right: 10, bottom: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                myContainerSimple(
                  containerWidth: 550,
                  borderColor: Colors.transparent,
                  borderWidth: borderWidth,
                  alignment: Alignment.centerLeft,
                  child: Text(dailyValues['summ'], style: myPlText),
                ),
                const SizedBox(width: containerSpacing),
                myContainerSimple(
                  containerWidth: 300,
                  borderColor: Colors.transparent,
                  borderWidth: borderWidth,
                  alignment: Alignment.centerRight,
                  child: Text(currentTime, style: myDateText),
                ),
              ],
            ),
          ),

          myHorizontalLine(colorState: isDataOld()),
          const SizedBox(height: containerSpacing),

          // Row 2: Temperature Precipitation, rises
          Container(
            height: row2Height,
            width: screenWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: Colors.transparent,
                width: borderWidth,
              ),
            ),
            padding: const EdgeInsets.only(left: 5, top: 5, right: 5, bottom: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                myContainerQuadrangle(
                  containerWidth: 270,
                  borderColor: myOutlineColor,
                  borderWidth: borderWidth,
                  text: 'Temperature',
                  main: currentValues['temp'],
                  q1: dailyValues['temp1'],
                  q2: dailyValues['temp2'],
                  q3: dailyValues['temp3'],
                  q4: dailyValues['temp4'],
                ),
                const SizedBox(width: containerSpacing),
                myContainerQuadrangle(
                  containerWidth: 270,
                  borderColor: myOutlineColor,
                  borderWidth: borderWidth,
                  text: 'Rain/PoP',
                  main: dailyValues['rain'],
                  q1: dailyValues['prep1'],
                  q2: dailyValues['prep2'],
                  q3: dailyValues['prep3'],
                  q4: dailyValues['prep4'],
                ),
                const SizedBox(width: containerSpacing),
                myContainerSets(
                  containerWidth: 320,
                  borderColor: myOutlineColor,
                  borderWidth: borderWidth,
                  sunr: dailyValues['sunr'],
                  suns: dailyValues['suns'],
                  moonr: dailyValues['moonr'],
                  moons: dailyValues['moons'],
                ),
              ],
            ),
          ),

          // Row 3: UV, Air quality, Humidity, Cloud cover
          Container(
            height: row3Height,
            width: screenWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: Colors.transparent,
                width: borderWidth,
              ),
            ),
            padding: const EdgeInsets.only(left: 5, top: 5, right: 5, bottom: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                myContainerDual(
                  containerWidth: 220,
                  borderColor: myOutlineColor,
                  borderWidth: borderWidth,
                  text: 'UV Index',
                  main: currentValues['uvi'],
                  q1: dailyValues['uvi2'],
                  q2: dailyValues['uvi3'],
                ),
                const SizedBox(width: containerSpacing),
                myContainerSingle(
                  containerWidth: 170,
                  borderColor: myOutlineColor,
                  borderWidth: borderWidth,
                  text: 'Air Quality',
                  main: currentValues['aqi'],
                ),
                const SizedBox(width: containerSpacing),
                myContainerSingle(
                  containerWidth: 170,
                  borderColor: myOutlineColor,
                  borderWidth: borderWidth,
                  text: 'Humidity',
                  main: currentValues['hum'],
                ),
                const SizedBox(width: containerSpacing),
                myContainerMoon(
                  containerWidth: 80,
                  borderColor: myOutlineColor,
                  borderWidth: borderWidth,
                  text: 'Moon Phase',
                  main: dailyValues['moon'],
                ),
                const SizedBox(width: containerSpacing),
                myContainerCover(
                  containerWidth: 204,
                  borderColor: myOutlineColor,
                  borderWidth: borderWidth,
                  description: "Cloudy",
                  iconType: currentValues['cico'],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget myContainerSimple({
    required double containerWidth,
    required Color borderColor,
    required double borderWidth,
    required Alignment alignment,
    required Widget child,
  }) {
    return Container(
      width: containerWidth,
      alignment: alignment,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
      ),
      child: child,
    );
  }

  Widget myContainerSets({
    required double containerWidth,
    required Color borderColor,
    required double borderWidth,
    required String sunr,
    required String suns,
    required String moonr,
    required String moons,
  }) {
    SizedBox spaceGridType = const SizedBox(width: 2, height: 3);

    return Container(
      width: containerWidth,
      padding: const EdgeInsets.only(left: 10, top: 10, right: 10, bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(sunr, style: mySmallNumber),
              spaceGridType,
              Image.asset(
                'assets/sun.png',
                width: 50,
                height: 50,
              ),
              spaceGridType,
              Text(suns, style: mySmallNumber),
            ],
          ),
          spaceGridType,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(moonr, style: mySmallNumber),
              spaceGridType,
              Image.asset(
                'assets/moon.png',
                width: 50,
                height: 50,
              ),
              spaceGridType,
              Text(moons, style: mySmallNumber),
            ],
          ),
        ],
      ),
    );
  }

  Widget myContainerCover({
    required double containerWidth,
    required Color borderColor,
    required double borderWidth,
    required String description,
    required String iconType,
  }) {
    String imageUrl = 'https://openweathermap.org/img/wn/$iconType@4x.png';

    return Container(
      width: containerWidth,
      padding: const EdgeInsets.only(left: 10, top: 10, right: 10, bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
      ),
      child: Container(
          width: 140,
          height: 140,
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                return child;
              } else {
                return const CircularProgressIndicator();
              }
            },
            errorBuilder: (context, error, stackTrace) {
              return const IconPlaceholder(width: 140, height: 140);
            },
          )),
    );
  }

  Widget myContainerQuadrangle({
    required double containerWidth,
    required Color borderColor,
    required double borderWidth,
    required String text,
    required String main,
    required String q1,
    required String q2,
    required String q3,
    required String q4,
  }) {
    SizedBox spaceWidthType = const SizedBox(width: 22);
    SizedBox spaceGridType = const SizedBox(width: 15, height: 15);

    if (int.tryParse(main) != null) {
      main = int.parse(main) < 10 ? " $main" : main;
    }

    if (int.tryParse(q1) != null) {
      q1 = int.parse(q1) < 10 ? " $q1" : q1;
    }

    if (int.tryParse(q2) != null) {
      q2 = int.parse(q2) < 10 ? " $q2" : q2;
    }

    if (int.tryParse(q3) != null) {
      q3 = int.parse(q3) < 10 ? " $q3" : q3;
    }

    if (int.tryParse(q4) != null) {
      q4 = int.parse(q4) < 10 ? " $q4" : q4;
    }

    return Container(
      width: containerWidth,
      padding: const EdgeInsets.only(left: 10, top: 10, right: 10, bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // text
          RotatedBox(
            quarterTurns: -1,
            child: Text(text, style: mySmallText),
          ),

          const VerticalDivider(
            width: 1,
            thickness: 1,
            color: myIvoryColor,
          ),
          spaceWidthType,

          // Big number
          Text(main, style: myBigNumber),
          spaceWidthType,

          // Grid numbers
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(q1, style: mySmallNumber),
                  spaceGridType,
                  Text(q2, style: mySmallNumber),
                ],
              ),
              spaceGridType,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(q3, style: mySmallNumber),
                  spaceGridType,
                  Text(q4, style: mySmallNumber),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget myContainerDual({
    required double containerWidth,
    required Color borderColor,
    required double borderWidth,
    required String text,
    required String main,
    required String q1,
    required String q2,
  }) {
    SizedBox spaceWidthType = const SizedBox(width: 22);
    SizedBox spaceGridType = const SizedBox(width: 15, height: 15);

    if (int.tryParse(main) != null) {
      main = int.parse(main) < 10 ? " $main" : main;
    }

    if (int.tryParse(q1) != null) {
      q1 = int.parse(q1) < 10 ? " $q1" : q1;
    }

    if (int.tryParse(q2) != null) {
      q2 = int.parse(q2) < 10 ? " $q2" : q2;
    }

    return Container(
      width: containerWidth,
      padding: const EdgeInsets.only(left: 10, top: 10, right: 10, bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // text
          RotatedBox(
            quarterTurns: -1,
            child: Text(text, style: mySmallText),
          ),

          const VerticalDivider(
            width: 1,
            thickness: 1,
            color: myIvoryColor,
          ),
          spaceWidthType,

          // Big number
          Text(main, style: myBigNumber),
          spaceWidthType,

          // Grid numbers
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(q1, style: mySmallNumber),
                ],
              ),
              spaceGridType,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(q2, style: mySmallNumber),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget myContainerSingle({
    required double containerWidth,
    required Color borderColor,
    required double borderWidth,
    required String text,
    required String main,
  }) {
    SizedBox spaceWidthType = const SizedBox(width: 25);
    if (int.tryParse(main) != null) {
      main = int.parse(main) < 10 ? " $main" : main;
    }

    return Container(
      width: containerWidth,
      padding: const EdgeInsets.only(left: 10, top: 10, right: 10, bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // text
          RotatedBox(
            quarterTurns: -1,
            child: Text(text, style: mySmallText),
          ),

          const VerticalDivider(
            width: 1,
            thickness: 1,
            color: myIvoryColor,
          ),
          spaceWidthType,

          // Big number
          Text(main, style: myBigNumber),
        ],
      ),
    );
  }

  Widget myContainerMoon({
    required double containerWidth,
    required Color borderColor,
    required double borderWidth,
    required String text,
    required String main,
  }) {
    SizedBox spaceWidthType = const SizedBox(width: 5);

    return Container(
      width: containerWidth,
      padding: const EdgeInsets.only(left: 10, top: 8, right: 10, bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // text
          RotatedBox(
            quarterTurns: -1,
            child: Text(text, style: mySmallText),
          ),

          const VerticalDivider(
            width: 1,
            thickness: 1,
            color: myIvoryColor,
          ),
          spaceWidthType,

          // text
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              RotatedBox(
                quarterTurns: -1,
                child: Text(main, style: mySmallText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget myHorizontalLine({required bool colorState}) {
    Color color = colorState ? Colors.red : myOutlineColor;
    return Container(
      height: 5,
      width: screenWidth,
      color: color,
    );
  }
}

//EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF//