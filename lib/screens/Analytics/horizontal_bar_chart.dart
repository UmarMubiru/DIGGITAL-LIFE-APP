// lib/screens/horizontal_bar_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
// Import for pi constant
import 'package:digital_life_care_app/providers/chart_data_provider.dart';

class CustomHorizontalBarChart extends StatelessWidget {
  final String title;
  final List<SingleBarDataModel> data;

  const CustomHorizontalBarChart({
    super.key,
    required this.title,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final sortedData = List<SingleBarDataModel>.from(data)
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            // Height is now controlled by the width of the rotated box
            height: sortedData.length * 50.0,
            child: RotatedBox(
              // THIS IS THE FIX: Rotate the entire chart
              quarterTurns: 1,
              child: BarChart(
                BarChartData(
                  // NO 'layout' parameter
                  barGroups: _buildBarGroups(sortedData),
                  titlesData: _buildTitlesData(sortedData),
                  barTouchData: _buildBarTouchData(sortedData),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(List<SingleBarDataModel> sortedData) {
    return List.generate(sortedData.length, (index) {
      final item = sortedData[index];
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: item.value,
            color: item.color,
            width: 18,
            borderRadius: const BorderRadius.all(Radius.circular(4)),
          ),
        ],
      );
    });
  }

  FlTitlesData _buildTitlesData(List<SingleBarDataModel> sortedData) {
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      // Bottom titles are now the LABELS (because of rotation)
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 100,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < sortedData.length) {
              // Rotate the label back to be readable
              return RotatedBox(
                quarterTurns: -1,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    sortedData[index].label,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              );
            }
            return const Text('');
          },
        ),
      ),
      // Left titles are now the VALUES (because of rotation)
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          getTitlesWidget: (value, meta) {
            // Rotate the value label back
            return RotatedBox(
              quarterTurns: -1,
              child: Text('${value.toInt()}%', style: const TextStyle(fontSize: 10)),
            );
          },
        ),
      ),
    );
  }

  BarTouchData _buildBarTouchData(List<SingleBarDataModel> sortedData) {
    return BarTouchData(
      touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (group) => Colors.grey.shade800,
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          return BarTooltipItem(
            '${sortedData[group.x].label}\n',
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            children: [
              TextSpan(
                text: '${rod.toY}%',
                style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.w500),
              ),
            ],
          );
        },
      ),
    );
  }
}
