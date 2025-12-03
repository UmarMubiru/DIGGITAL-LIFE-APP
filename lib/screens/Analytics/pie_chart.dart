// lib/screens/pie_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:digital_life_care_app/providers/chart_data_provider.dart'; // Import the data provider
import 'package:digital_life_care_app/widgets/chart_legend.dart';   // Import the legend widget

class CustomPieChart extends StatefulWidget {
  final String title;
  final List<PieChartDataModel> data;

  const CustomPieChart({
    super.key,
    required this.title,
    required this.data,
  });

  @override
  State<CustomPieChart> createState() => _CustomPieChartState();
}

class _CustomPieChartState extends State<CustomPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- CHART TITLE ---
          Text(
            widget.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // --- CHART & LEGEND ---
          LayoutBuilder(
            builder: (context, constraints) {
              bool isSmallScreen = constraints.maxWidth < 350;

              if (isSmallScreen) {
                // For small screens, stack chart and legend
                return Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: _buildChart(),
                    ),
                    const SizedBox(height: 24),
                    _buildLegend(),
                  ],
                );
              } else {
                // For larger screens, show side-by-side
                return Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 200,
                        child: _buildChart(),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 1,
                      child: _buildLegend(),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // Builds the PieChart widget
  Widget _buildChart() {
    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (event, pieTouchResponse) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  pieTouchResponse == null ||
                  pieTouchResponse.touchedSection == null) {
                touchedIndex = -1;
                return;
              }
              touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
            });
          },
        ),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2, // Add a little space between sections
        centerSpaceRadius: 40,
        sections: _buildChartSections(),
      ),
    );
  }

  // Builds the list of sections from the data model
  List<PieChartSectionData> _buildChartSections() {
    return List.generate(widget.data.length, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 20.0 : 14.0;
      final radius = isTouched ? 60.0 : 50.0;
      final dataItem = widget.data[i];

      return PieChartSectionData(
        color: dataItem.color,
        value: dataItem.value,
        title: dataItem.title,
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
        ),
      );
    });
  }

  // Builds the legend using the reusable ChartLegend widget
  Widget _buildLegend() {
    return ChartLegend(
      items: widget.data.map((item) {
        return LegendItem(color: item.color, text: item.legend);
      }).toList(),
    );
  }
}
