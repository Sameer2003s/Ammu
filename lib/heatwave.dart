import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'package:http/http.dart' as http; // Import the http package
import 'dart:convert'; // Import for json decoding

// The main widget is now stateful to manage user input and data changes.
class Heatwave extends StatefulWidget {
  const Heatwave({super.key});

  @override
  State<Heatwave> createState() => _HeatwaveState();
}

class _HeatwaveState extends State<Heatwave> {
  // Controller for the location search text field.
  final TextEditingController _locationController = TextEditingController();
  
  // State variables to hold the current heat data.
  double _currentHeatValue = 150.0;
  String _locationName = 'Tiruchirappalli'; // Default location
  String _statusText = 'NOT GOOD';
  Color _statusColor = Colors.orange;
  bool _isLoading = false; // To show a loading indicator

  // --- IMPORTANT: PASTE YOUR API KEY HERE ---
  final String _apiKey = 'c1acd4ccc8724d5bba8d9d98a38e51c4';

  @override
  void initState() {
    super.initState();
    // Fetch data for the default location on startup
    _fetchHeatDataForLocation(_locationName);
  }

  @override
  void dispose() {
    // Dispose the controller when the widget is removed from the widget tree.
    _locationController.dispose();
    super.dispose();
  }
  
  // --- NEW FUNCTION to map temperature to our 0-250 scale ---
  double _mapTemperatureToValue(double tempCelsius) {
    // This function converts a Celsius temperature to the 0-250 gauge value.
    // You can adjust these thresholds to better match your desired heat index logic.
    if (tempCelsius < 20) return (tempCelsius / 20) * 50; // 0-20°C -> 0-50
    if (tempCelsius < 27) return 50 + ((tempCelsius - 20) / 7) * 50; // 20-27°C -> 50-100
    if (tempCelsius < 32) return 100 + ((tempCelsius - 27) / 5) * 50; // 27-32°C -> 100-150
    if (tempCelsius < 40) return 150 + ((tempCelsius - 32) / 8) * 50; // 32-40°C -> 150-200
    return 200 + math.min(((tempCelsius - 40) / 10) * 50, 50); // >40°C -> 200-250
  }

  // --- UPDATED FUNCTION to fetch real data ---
  Future<void> _fetchHeatDataForLocation(String location) async {
    if (location.isEmpty) return;

    setState(() {
      _isLoading = true; // Show loading indicator
    });

    final url =
        'https://api.openweathermap.org/data/2.5/weather?q=$location&appid=$_apiKey&units=metric';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final feelsLikeTemp = data['main']['feels_like'];
        final fetchedLocationName = data['name'];
        
        final newHeatValue = _mapTemperatureToValue(feelsLikeTemp.toDouble());

        setState(() {
          _currentHeatValue = newHeatValue;
          _locationName = fetchedLocationName;
          _locationController.text = _locationName;

          // Update status text based on the new value
          if (newHeatValue < 50) {
            _statusText = 'LOW';
            _statusColor = const Color(0xFF006400);
          } else if (newHeatValue < 100) {
            _statusText = 'MODERATE';
            _statusColor = const Color(0xFF74B04C);
          } else if (newHeatValue < 150) {
            _statusText = 'HIGH';
            _statusColor = const Color(0xFFFDE49C);
          } else if (newHeatValue < 200) {
            _statusText = 'VERY HIGH';
            _statusColor = const Color(0xFFE59A45);
          } else {
            _statusText = 'EXTREME';
            _statusColor = const Color(0xFFB5542E);
          }
        });
      } else {
        // Handle location not found or other API errors
        if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not find location: $location')),
          );
        }
      }
    } catch (e) {
      // Handle network errors
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to connect to the weather service.')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Heatwaves Indicator',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0B3D91),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          LocationSearchCard(
            controller: _locationController,
            onSearch: _fetchHeatDataForLocation,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 20),
          _isLoading
              ? const Center(heightFactor: 10, child: CircularProgressIndicator())
              : HeatRatioGauge(
                  value: _currentHeatValue,
                  location: _locationName,
                  statusText: _statusText,
                  statusColor: _statusColor,
                ),
          const SizedBox(height: 20),
          const NextHoursChart(),
          const SizedBox(height: 20),
          const WeatherForecast(),
        ],
      ),
    );
  }
}

// --- THIS WIDGET IS UPDATED to show loading state ---
class LocationSearchCard extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSearch;
  final bool isLoading;

  const LocationSearchCard({
    super.key,
    required this.controller,
    required this.onSearch,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: controller,
        onSubmitted: (value) => onSearch(value),
        decoration: InputDecoration(
          hintText: 'Enter a location',
          prefixIcon: IconButton(
            icon: isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3,)) : const Icon(Icons.search),
            onPressed: isLoading ? null : () {
              FocusScope.of(context).unfocus(); 
              onSearch(controller.text);
            },
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        ),
      ),
    );
  }
}

// --- THIS WIDGET IS UNCHANGED ---
class HeatRatioGauge extends StatelessWidget {
  final double value;
  final String location;
  final String statusText;
  final Color statusColor;

  const HeatRatioGauge({
    super.key,
    required this.value,
    required this.location,
    required this.statusText,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(80, 10, 80, 80),
        child: SizedBox(
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                painter: GaugePainter(value: value),
                size: Size.infinite,
              ),
              Positioned(
                bottom: 50,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(value.toInt().toString(),
                        style: const TextStyle(
                            fontSize: 50, fontWeight: FontWeight.bold)),
                    Text(statusText,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: statusColor)),
                    const SizedBox(height: 4),
                    Text(location,
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// This custom painter remains unchanged.
class GaugePainter extends CustomPainter {
  final double value;
  final double maxValue = 250;

  GaugePainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 1.5);
    final radius = size.width / 1.5;
    const startAngle = 135 * (math.pi / 180);
    const sweepAngle = 270 * (math.pi / 180);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gapRadians = 1 * (math.pi / 180);

    // Green segment
    {
      final paint = Paint()
        ..color = const Color(0xFF006400)
        ..strokeWidth = 18
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt;
      final sectionStart =
          startAngle + (0.0 / maxValue) * sweepAngle + gapRadians / 2;
      final sectionSweep = ((49.0 - 0.0) / maxValue) * sweepAngle - gapRadians;
      canvas.drawArc(rect, sectionStart, sectionSweep, false, paint);
      final capX = center.dx + radius * math.cos(sectionStart);
      final capY = center.dy + radius * math.sin(sectionStart);
      canvas.drawCircle(Offset(capX, capY), 9, Paint()..color = const Color(0xFF006400));
    }

    // Light Green segment
    {
      final paint = Paint()
        ..color = const Color(0xFF74B04C)
        ..strokeWidth = 18
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt;
      final sectionStart =
          startAngle + (51.0 / maxValue) * sweepAngle + gapRadians / 2;
      final sectionSweep = ((99.0 - 51.0) / maxValue) * sweepAngle - gapRadians;
      canvas.drawArc(rect, sectionStart, sectionSweep, false, paint);
    }

    // Yellow segment
    {
      final paint = Paint()
        ..color = const Color(0xFFFDE49C)
        ..strokeWidth = 18
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt;
      final sectionStart =
          startAngle + (101.0 / maxValue) * sweepAngle + gapRadians / 2;
      final sectionSweep =
          ((149.0 - 101.0) / maxValue) * sweepAngle - gapRadians;
      canvas.drawArc(rect, sectionStart, sectionSweep, false, paint);
    }

    // Orange segment
    {
      final paint = Paint()
        ..color = const Color(0xFFE59A45)
        ..strokeWidth = 18
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt;
      final sectionStart =
          startAngle + (151.0 / maxValue) * sweepAngle + gapRadians / 2;
      final sectionSweep =
          ((199.0 - 151.0) / maxValue) * sweepAngle - gapRadians;
      canvas.drawArc(rect, sectionStart, sectionSweep, false, paint);
    }

    // Brown segment
    {
      final paint = Paint()
        ..color = const Color(0xFFB5542E)
        ..strokeWidth = 18
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt;
      final sectionStart =
          startAngle + (201.0 / maxValue) * sweepAngle + gapRadians / 2;
      final sectionSweep =
          ((250.0 - 201.0) / maxValue) * sweepAngle - gapRadians;
      canvas.drawArc(rect, sectionStart, sectionSweep, false, paint);
      final endAngle = sectionStart + sectionSweep;
      final capX = center.dx + radius * math.cos(endAngle);
      final capY = center.dy + radius * math.sin(endAngle);
      canvas.drawCircle(Offset(capX, capY), 9, Paint()..color = const Color(0xFFB5542E));
    }

    // Pointer
    final pointerAngle =
        startAngle + ((value.clamp(0, maxValue) / maxValue) * sweepAngle);
    final pointerPaint = Paint()..color = const Color(0xFF63A646);
    final pointerX = center.dx + radius * math.cos(pointerAngle);
    final pointerY = center.dy + radius * math.sin(pointerAngle);
    canvas.drawCircle(
      Offset(pointerX, pointerY),
      12,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    canvas.drawCircle(Offset(pointerX, pointerY), 10, pointerPaint);

    _drawLabels(canvas, size, center);
  }

  void _drawLabels(Canvas canvas, Size size, Offset center) {
    final labels = {
      'Low': 135.0, '50': 189.0, '100': 240.0, '150': 300.0, '200': 350.0, 'High': 45.0,
    };
    labels.forEach((text, angle) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 20,
            fontWeight: ['Low', 'High'].contains(text) ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final angleRad = angle * (math.pi / 180);
      final labelRadius = (size.width / 1.4) + 20;
      final x = center.dx + labelRadius * math.cos(angleRad) - textPainter.width / 2;
      final y = center.dy + labelRadius * math.sin(angleRad) - textPainter.height / 2;
      textPainter.paint(canvas, Offset(x, y));
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// --- The rest of the file remains unchanged ---
class NextHoursChart extends StatelessWidget {
  const NextHoursChart({super.key});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Next hours', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Updated 4 min ago', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],),
            const SizedBox(height: 20),
            SizedBox( height: 120, child: BarChart(BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 150,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 10)), reservedSize: 20)),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: _getBarGroups(),
                ),),),
          ],),
      ),
    );
  }

  List<BarChartGroupData> _getBarGroups() {
    final List<double> hourlyData = [ 60, 80, 90, 95, 130, 90, 70, 65, 75, 80, 85, 90, 95, 100 ];
    final List<Color> colors = [ Colors.green, Colors.amber, Colors.orange, Colors.red ];
    return List.generate(hourlyData.length, (index) {
      final value = hourlyData[index];
      Color barColor;
      if (value < 70) {
        barColor = colors[0];
      } else if (value < 100) barColor = colors[1];
      else if (value < 120) barColor = colors[2];
      else barColor = colors[3];
      return BarChartGroupData(x: index, barRods: [ BarChartRodData(toY: value, color: barColor, width: 12, borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),), ],);
    });
  }
}

class WeatherForecast extends StatelessWidget {
  const WeatherForecast({super.key});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding( padding: const EdgeInsets.all(16.0), child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Weather', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('This week', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],),
            const SizedBox(height: 10),
            Row( mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _buildWeatherDay('Today', Icons.cloud_outlined, '32°'),
                _buildWeatherDay('Mon', Icons.cloud_queue, '31°'),
                _buildWeatherDay('Tue', Icons.bolt, '32°'),
                _buildWeatherDay('Wed', Icons.grain, '33°'),
                _buildWeatherDay('Thu', Icons.cloud_circle_outlined, '31°'),
                _buildWeatherDay('Fri', Icons.wb_sunny, '34°', color: Colors.red),
                _buildWeatherDay('Sat', Icons.cloudy_snowing, '32°'),
              ],),
          ],),),
    );
  }

  Widget _buildWeatherDay(String day, IconData icon, String temp, {Color color = Colors.black}) {
    return Column( children: [
        Text(day, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Icon(icon, color: Colors.blueGrey, size: 28),
        const SizedBox(height: 8),
        Text(temp, style: TextStyle(color: color)),
      ],);
  }
}
