// lib/screens/bar_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:digital_life_care_app/providers/chart_data_provider.dart'; // Import the data provider
import 'package:digital_life_care_app/widgets/chart_legend.dart';   // Import the legend widget

class CustomBarChart extends StatelessWidget {
  final String title;
  final String yAxisLabel;
  final List<BarChartGroupModel> data;

  const CustomBarChart({
    super.key,
    required this.title,
    required this.yAxisLabel,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    // Extract all unique legend items from the data
    final legendItems = _extractLegendItems();

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
          // --- CHART TITLE ---
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // --- RESPONSIVE CHART AREA ---
          LayoutBuilder(
            builder: (context, constraints) {
              // Use a wider breakpoint for this chart's layout
              bool useHorizontalLayout = constraints.maxWidth > 450;

              if (useHorizontalLayout) {
                return _buildHorizontalLayout();
              } else {
                return _buildVerticalLayout();
              }
            },
          ),

          const SizedBox(height: 24),

          // --- LEGEND ---
          ChartLegend(items: legendItems),
        ],
      ),
    );
  }

  // --- LAYOUT FOR WIDER SCREENS ---
  Widget _buildHorizontalLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Y-axis label
        RotatedBox(
          quarterTurns: 3,
          child: Text(
            yAxisLabel,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 250, // Fixed height for the chart itself
            child: _buildChartWidget(),
          ),
        ),
      ],
    );
  }

  // --- LAYOUT FOR NARROWER SCREENS ---
  Widget _buildVerticalLayout() {
    return Column(
      children: [
        // Y-axis label
        Text(
          yAxisLabel,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 250, // Fixed height for the chart itself
          child: _buildChartWidget(),
        ),
      ],
    );
  }

  // --- THE CORE BAR CHART WIDGET ---
  Widget _buildChartWidget() {
    return BarChart(
      BarChartData(
        barGroups: _createChartGroups(),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide default Y-axis labels
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                // Find the group name for the given x-value
                final group = data.firstWhere((g) => g.x == value.toInt(), orElse: () => data.first);
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(group.groupName, style: const TextStyle(fontSize: 12)),
                );
              },
              reservedSize: 30,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.blueGrey, // Corrected parameter
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // --- DATA MAPPING HELPERS ---

  // Creates BarChartGroupData from our data model
  List<BarChartGroupData> _createChartGroups() {
    return data.map((group) {
      return BarChartGroupData(
        x: group.x,
        barsSpace: 6,
        barRods: group.rods.map((rod) {
          return BarChartRodData(
            toY: rod.toY,
            color: rod.color,
            width: 15,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          );
        }).toList(),
      );
    }).toList();
  }

  // Extracts a unique list of LegendItems from the data
  List<LegendItem> _extractLegendItems() {
    final allRods = data.expand((group) => group.rods).toList();
    final uniqueLegends = <String, Color>{};
    for (var rod in allRods) {
      uniqueLegends[rod.legend] = rod.color;
    }
    return uniqueLegends.entries.map((entry) {
      return LegendItem(color: entry.value, text: entry.key);
    }).toList();
  }
}
