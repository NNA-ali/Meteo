// ignore: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
// ignore: depend_on_referenced_packages

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const WeatherPage(),
    );
  }
}

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final TextEditingController _cityController = TextEditingController();
  Map<String, dynamic>? _cityCoordinates;
  Map<String, dynamic>? _weatherData;

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _fetchCityData(String cityName) async {
    final dio = Dio();
    final response = await dio.get(
      'https://api.api-ninjas.com/v1/city?name=$cityName',
      options: Options(
        headers: {'X-Api-Key': dotenv.env['CITY_API_KEY']},
      ),
    );
    if (response.statusCode == 200) {
      final cityData = response.data[0];
      setState(() {
        _cityCoordinates = cityData;
      });
    } else {
      print('Failed to fetch city data');
    }
  }

  Future<void> _fetchWeatherData(double lat, double lon) async {
    final dio = Dio();
    final response = await dio.get(
      'https://api.openweathermap.org/data/2.5/weather',
      queryParameters: {
        'lat': lat,
        'lon': lon,
        'appid': dotenv.env['METEO_API_KEY'],
      },
    );
    if (response.statusCode == 200) {
      setState(() {
        _weatherData = response.data;
      });
    } else {
      print('Failed to fetch weather data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather App'),
      ),
      body: Column(
        children: [
          TextField(
            controller: _cityController,
            decoration: const InputDecoration(
              hintText: 'Enter city name',
              contentPadding: EdgeInsets.all(16.0),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final cityName = _cityController.text;
              await _fetchCityData(cityName);
              if (_cityCoordinates != null) {
                final lat = _cityCoordinates!['latitude'];
                final lon = _cityCoordinates!['longitude'];
                await _fetchWeatherData(lat, lon);
              }
            },
            child: const Text('Search'),
          ),
          if (_weatherData != null && _cityCoordinates != null) ...[
            Text(
              'Latitude: ${_cityCoordinates!['latitude']}',
            ),
            Text(
              'Longitude: ${_cityCoordinates!['longitude']}',
            ),
            Text(
              'Country: ${_cityCoordinates!['country']}',
            ),
            Text(
              'Temperature: ${((_weatherData!['main']['temp'] - 273.15) * 10).toInt() / 10} °C',
            ),
            Text(
              'Weather Description: ${_weatherData!['weather'][0]['description']}',
            ),
            Flexible(
              child:  FlutterMap(
      options: MapOptions(
        center: LatLng(_cityCoordinates!['latitude'], _cityCoordinates!['longitude']),
        zoom: 4,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app',
        ),
        MarkerLayer(
          markers: [
            Marker(
              width: 400.0,
              height: 200.0,
              point: LatLng(_cityCoordinates!['latitude'], _cityCoordinates!['longitude']),
              child: const Icon(Icons.map)
            )
          ],
        )
      ],
    )
  
            ),
          ],
        ],
      ),
    );
  }
}
