// This is a simple mock implementation of the fl_chart package
// to avoid errors in the analytics_screen.dart file

// Import material for Color and other types
import 'package:flutter/material.dart';

class FlSpot {
  final double x;
  final double y;

  FlSpot(this.x, this.y);
}

class FlLine {
  final Color? color;
  final double strokeWidth;

  FlLine({this.color, this.strokeWidth = 1.0});
}

class FlGridData {
  final bool show;
  final bool drawVerticalLine;
  final double horizontalInterval;
  final Function(double)? getDrawingHorizontalLine;

  FlGridData({
    this.show = true,
    this.drawVerticalLine = true,
    this.horizontalInterval = 1.0,
    this.getDrawingHorizontalLine,
  });
}

class SideTitles {
  final bool showTitles;
  final double reservedSize;
  final double interval;
  final Function(double, TitleMeta)? getTitlesWidget;

  SideTitles({
    this.showTitles = true,
    this.reservedSize = 0.0,
    this.interval = 1.0,
    this.getTitlesWidget,
  });
}

class TitleMeta {
  final double min;
  final double max;
  final double appliedInterval;
  final bool sideTitles;

  TitleMeta({
    this.min = 0.0,
    this.max = 0.0,
    this.appliedInterval = 0.0,
    this.sideTitles = true,
  });
}

class AxisTitles {
  final SideTitles sideTitles;

  AxisTitles({required this.sideTitles});
}

class FlTitlesData {
  final bool show;
  final AxisTitles rightTitles;
  final AxisTitles topTitles;
  final AxisTitles bottomTitles;
  final AxisTitles leftTitles;

  FlTitlesData({
    this.show = true,
    required this.rightTitles,
    required this.topTitles,
    required this.bottomTitles,
    required this.leftTitles,
  });
}

class FlBorderData {
  final bool show;

  FlBorderData({this.show = true});
}

class FlDotData {
  final bool show;

  FlDotData({this.show = true});
}

class BarAreaData {
  final bool show;
  final Color? color;

  BarAreaData({this.show = true, this.color});
}

class LineChartBarData {
  final List<FlSpot?> spots;
  final bool isCurved;
  final Color? color;
  final double barWidth;
  final bool isStrokeCapRound;
  final FlDotData dotData;
  final BarAreaData belowBarData;

  LineChartBarData({
    required this.spots,
    this.isCurved = false,
    this.color,
    this.barWidth = 2.0,
    this.isStrokeCapRound = false,
    required this.dotData,
    required this.belowBarData,
  });
}

class LineChartData {
  final FlGridData gridData;
  final FlTitlesData titlesData;
  final FlBorderData borderData;
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;
  final List<LineChartBarData> lineBarsData;

  LineChartData({
    required this.gridData,
    required this.titlesData,
    required this.borderData,
    this.minX = 0.0,
    this.maxX = 0.0,
    this.minY = 0.0,
    this.maxY = 0.0,
    required this.lineBarsData,
  });
}

class LineChart extends StatelessWidget {
  final LineChartData data;

  const LineChart(this.data, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(child: Center(child: Text('Chart Placeholder')));
  }
}
