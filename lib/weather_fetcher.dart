// *.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.* //
// *                                     WEATHER FETCHER                                       * //
// *.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.* //
// *                                                                                           * //
// * This provides all necesary functions to interface with open weather and fetch data.       * //
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

import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'dart:convert';

// ********************************************************************************************* //
// *                                 WEATHER SERVICES CLASS                                    * //
// * ----------------------------------------------------------------------------------------- * //

class WeatherServices {
  //|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*
  //|* --------------------------------------------- VARIABLES
  late String _myApiKey;

  final Map<String, dynamic> _dailyValuesDefault = {
    'summ': 'na',
    'temp1': 'na',
    'temp2': 'na',
    'temp3': 'na',
    'temp4': 'na',
    'rain': 'na',
    'prep1': 'na',
    'prep2': 'na',
    'prep3': 'na',
    'prep4': 'na',
    'sunr': 'na',
    'suns': 'na',
    'moonr': 'na',
    'moons': 'na',
    'uvi2': 'na',
    'uvi3': 'na',
    'moon': 'na',
  };

  final Map<String, dynamic> _currentValuesDefault = {
    'desc': 'na',
    'temp': 'na',
    'prep': 'na',
    'uvi': 'na',
    'aqi': 'na',
    'hum': 'na',
    'cdes': 'na',
    'cico': 'na',
  };

  Map<String, dynamic> get dailyValuesDefault => _dailyValuesDefault;
  Map<String, dynamic> get currentValuesDefault => _currentValuesDefault;

  //|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*|*
  //|* ----------------------------------------- CLASS METHODS
  Future<void> initialize() async {
    _myApiKey = await readApiKeyFromFile();
    if (kDebugMode) {
      print('API Key: $_myApiKey');
    }
  }

  Future<String> readApiKeyFromFile() async {
    try {
      String apiKey = await rootBundle.loadString('assets/apikey.txt');
      return apiKey.trim();
    } catch (e) {
      if (kDebugMode) {
        print('Error reading API key from file: $e');
      }
      return '';
    }
  }

  Future<Map<String, dynamic>> dailyWeatherServices() async {
    // start with default na values
    Map<String, dynamic> dailyValues = _dailyValuesDefault;

    // --- first get the daily data and today's unix time
    // Access the "daily" and "hourly" arrays
    Map<String, dynamic> dailyData = await getDailyWeatherJson();

    // if calls to the api are bad, return the default na
    if (dailyData.isEmpty) {
      return dailyValues;
    }

    // today as reference, plus one to avoid confusion on midnight
    int daystart = (DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000);

    // --- get hourly data based on today's data in case app restarts
    List<dynamic> hourlyDataDynamic = await getHourlyWeatherJson(daystart);

    //if calls to the api are bad, return the default na
    if (hourlyDataDynamic.isEmpty) {
      return dailyValues;
    }

    // ensure list format to perform averages
    List<Map<String, dynamic>> hourlyData = hourlyDataDynamic.map((dynamic item) {
      return item as Map<String, dynamic>;
    }).toList();

    // --- parse into map
    // summary of day
    dailyValues['summ'] = dailyData['summary'];

    // temperature (excluding min/max in lieu of these 4)
    dailyValues['temp1'] = dailyData['temp']['morn'].round().toString();
    dailyValues['temp2'] = dailyData['temp']['day'].round().toString();
    dailyValues['temp3'] = dailyData['temp']['eve'].round().toString();
    dailyValues['temp4'] = dailyData['temp']['night'].round().toString();

    // sun and moon rises and sets
    dailyValues['sunr'] = unixTimeToHourOfDay(dailyData['sunrise']);
    dailyValues['suns'] = unixTimeToHourOfDay(dailyData['sunset']);
    dailyValues['moonr'] = unixTimeToHourOfDay(dailyData['moonrise']);
    dailyValues['moons'] = unixTimeToHourOfDay(dailyData['moonset']);

    // probability of precipitation
    List<String> tmpprep = averagePopPredictions(daystart, hourlyData);
    dailyValues['prep1'] = tmpprep[0];
    dailyValues['prep2'] = tmpprep[1];
    dailyValues['prep3'] = tmpprep[2];
    dailyValues['prep4'] = tmpprep[3];

    dailyValues['rain'] = dailyData['rain'] != null ? dailyData['rain'].toInt().toString() : '0';

    // Ultraviolet index
    List<String> tmpuvi = averageUviPredictions(daystart, hourlyData);
    dailyValues['uvi2'] = tmpuvi[1];
    dailyValues['uvi3'] = tmpuvi[2];

    // moon phase
    dailyValues['moon'] = moonPhase(dailyData['moon_phase']);

    return dailyValues;
  }

  Future<Map<String, dynamic>> currentWeatherServices() async {
    // start with default na values
    Map<String, dynamic> currentValues = _currentValuesDefault;

    // --- first get the current data to get the unix time
    Map<String, dynamic> currentData = await getCurrentWeatherJson();

    //if calls to the api are bad, return the default na
    if (currentData.isEmpty) {
      return currentValues;
    }

    // --- finally get air quality
    List<dynamic> aqiData = await getCurrentAqiJson();

    //if calls to the api are bad, return the default na
    if (aqiData.isEmpty) {
      return currentValues;
    }

    currentValues['desc'] = currentData['weather'][0]['description'];
    currentValues['temp'] = currentData['temp'].round().toString();
    currentValues['uvi'] = currentData['uvi'].round().toString();
    currentValues['aqi'] = averageAqiPrediction(aqiData);
    currentValues['hum'] = currentData['humidity'].round().toString();
    currentValues['cdes'] = currentData['weather'][0]['main'];
    currentValues['cico'] = currentData['weather'][0]['icon'];

    return currentValues;
  }

  String unixTimeToHourOfDay(int unixTime) {
    // Create a DateTime object from the Unix epoch time
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(unixTime * 1000).toLocal();

    // Extract the hour and minute components
    int hour = dateTime.hour;
    int minute = dateTime.minute;

    // Format the hour and minute as a string in 24-hour format (e.g., "08:00")
    String formattedHour = hour < 10 ? '0$hour' : '$hour';
    String formattedMinute = minute < 10 ? '0$minute' : '$minute';

    return '$formattedHour:$formattedMinute';
  }

  String averageAqiPrediction(List<dynamic> aqiData) {
    return aqiData[0]['main']['aqi'].toString();
  }

  String averageRainPredictions(List<Map<String, dynamic>> hourlyData) {
    // Convert all entries to local time
    List<DateTime> hourlyDataLocalTime = hourlyData.map((entry) {
      // Convert the Unix time of the entry to local time
      return DateTime.fromMillisecondsSinceEpoch(entry['dt'] * 1000).toLocal();
    }).toList();

    // Get the start of today and tomorrow in local time
    DateTime startOfToday = DateTime.now().toLocal();
    startOfToday = DateTime(startOfToday.year, startOfToday.month, startOfToday.day);
    DateTime startOfTomorrow = startOfToday.add(Duration(days: 1));

    // Filter indices for today's entries
    List<int> indicesForToday = [];
    for (int i = 0; i < hourlyDataLocalTime.length; i++) {
      DateTime entryTime = hourlyDataLocalTime[i];
      // Check if the entry's local time is after the start of today
      // and before the start of tomorrow
      if (entryTime.isAfter(startOfToday) && entryTime.isBefore(startOfTomorrow)) {
        indicesForToday.add(i);
      }
    }

    // Extract rain values from today's hourly data
    List<double> rainValues = indicesForToday.map((index) {
      return hourlyData[index]['rain'] != null
          ? (hourlyData[index]['rain'] as num).toDouble()
          : 0.0;
    }).toList();

    // Find the maximum rain value
    double maxRain = rainValues.isNotEmpty
        ? rainValues.reduce((value, element) => value > element ? value : element)
        : 0.0;

    return maxRain
        .toStringAsFixed(2); // Return the maximum rain value as a string with 2 decimal places
  }

  List<String> averagePopPredictions(int unixTime, List<Map<String, dynamic>> hourlyData) {
    List<double> averages = averageHourlyPredictions("pop", unixTime, hourlyData);

    List<String> popPrediction = averages.map((average) {
      if (average == 0) {
        return '0';
      }
      int percentage = (average * 100).toInt();
      return percentage.toString();
    }).toList();

    return popPrediction;
  }

  List<String> averageUviPredictions(int unixTime, List<Map<String, dynamic>> hourlyData) {
    List<double> averages = averageHourlyPredictions("uvi", unixTime, hourlyData);

    List<String> uviPrediction = averages.map((average) {
      if (average == 0) {
        return '0';
      }
      double percentage = (average * 10).ceilToDouble() / 10;
      return percentage.toInt().toString();
    }).toList();

    return uviPrediction;
  }

  String moonPhase(double phase) {
    // Convert the phase to a number of bars ('|')
    int numBars = (phase * 12).round();
    return '|' * numBars;
  }

  List<double> averageHourlyPredictions(
      String param, int unixTime, List<Map<String, dynamic>> hourlyData) {
    List<double> dailyPredictions = [];

    // Define the time intervals for the day
    List<List<int>> timeIntervals = [
      [4, 8],
      [9, 13],
      [14, 18],
      [19, 23],
    ];

    // Convert the Unix time to a DateTime object to get the start of the day
    DateTime dayStart = DateTime.fromMillisecondsSinceEpoch(unixTime * 1000).toLocal();

    // Filter hourly data for entries that correspond to the given day and time intervals
    for (var interval in timeIntervals) {
      List<Map<String, dynamic>> filteredData = hourlyData.where((entry) {
        DateTime entryTime = DateTime.fromMillisecondsSinceEpoch(entry['dt'] * 1000).toLocal();
        return entryTime.year == dayStart.year &&
            entryTime.month == dayStart.month &&
            entryTime.day == dayStart.day &&
            entryTime.hour >= interval[0] &&
            entryTime.hour <= interval[1];
      }).toList();

      // Extract values corresponding to the specified parameter from the filtered data
      List<double> values = filteredData.map((entry) {
        if (entry[param] == null || entry[param] is int) {
          return 0.0;
        }
        return (entry[param] as double);
      }).toList();

      if (values.isNotEmpty) {
        // Calculate the maximum value
        double max = values.reduce((value, element) => value > element ? value : element);

        // Calculate the average value
        double average = values.reduce((value, element) => value + element) / values.length;

        if (max == 0 || average == 0) {
          dailyPredictions.add(0);
          continue;
        }

        // Calculate the representative number using the weighted average approach
        double representativeNumber = (max - average) * 0.9 + average;

        // Add the representative number to the list of daily predictions
        dailyPredictions.add(representativeNumber);
      } else {
        // If there are no samples in the window then it is 0
        dailyPredictions.add(0);
      }
    }

    return dailyPredictions;
  }

  Future<List<dynamic>> getCurrentAqiJson() async {
    const String baseUrl =
        'https://api.openweathermap.org/data/2.5/air_pollution?lat=25.6802019&lon=-100.315258&appid=';

    Map<String, dynamic> data = {};

    try {
      String fetchUrl = '$baseUrl$_myApiKey';

      http.Response response = await http.get(Uri.parse(fetchUrl));
      if (response.statusCode == 200) {
        data = json.decode(response.body);
      } else {
        if (kDebugMode) {
          print('Request failed with status: ${response.statusCode}');
        }
        return [];
      }

      return data['list'];
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching current aqi: $e');
      }
      return [];
    }
  }

  Future<Map<String, dynamic>> getCurrentWeatherJson() async {
    const String baseUrl =
        'https://api.openweathermap.org/data/3.0/onecall?lat=25.6802019&lon=-100.315258&units=metric&lang=en&exclude=daily,hourly,minutely,alerts&appid=';

    Map<String, dynamic> data = {};

    try {
      String fetchUrl = '$baseUrl$_myApiKey';

      http.Response response = await http.get(Uri.parse(fetchUrl));
      if (response.statusCode == 200) {
        data = json.decode(response.body);
      } else {
        if (kDebugMode) {
          print('Request failed with status: ${response.statusCode}');
        }
        return {};
      }

      return data['current'];
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching current data: $e');
      }
      return {};
    }
  }

  Future<List<dynamic>> getHourlyWeatherJson(int daystart) async {
    // use today's to get hourly data
    String daystring = daystart.toString();

    String baseUrl =
        'https://api.openweathermap.org/data/3.0/onecall?lat=25.6802019&lon=-100.315258&units=metric&dt=$daystring&lang=en&exclude=current,daily,minutely,alerts&appid=';

    Map<String, dynamic> data = {};

    try {
      String fetchUrl = '$baseUrl$_myApiKey';

      http.Response response = await http.get(Uri.parse(fetchUrl));
      if (response.statusCode == 200) {
        data = json.decode(response.body);
      } else {
        if (kDebugMode) {
          print('Request failed with status: ${response.statusCode}');
        }
        return [];
      }

      return data['hourly'];
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching hourly data: $e');
      }
      return [];
    }
  }

  Future<Map<String, dynamic>> getDailyWeatherJson() async {
    const String baseUrl =
        'https://api.openweathermap.org/data/3.0/onecall?lat=25.6802019&lon=-100.315258&units=metric&lang=en&exclude=current,hourly,minutely,alerts&appid=';

    Map<String, dynamic> data = {};

    try {
      String fetchUrl = '$baseUrl$_myApiKey';

      http.Response response = await http.get(Uri.parse(fetchUrl));
      if (response.statusCode == 200) {
        // Decode the JSON response
        data = json.decode(response.body);
      } else {
        if (kDebugMode) {
          print('Request failed with status: ${response.statusCode}');
        }
        return {};
      }

      return data["daily"][0];
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching daily data: $e');
      }
      return {};
    }
  }
}

//EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF EOF//