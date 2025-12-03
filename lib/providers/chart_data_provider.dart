// lib/data/chart_data_provider.dart

import 'package:flutter/material.dart';

// --- Data Model for Pie Chart ---
class PieChartDataModel {
  final double value;
  final String title;
  final Color color;
  final String legend;

  PieChartDataModel({
    required this.value,
    required this.title,
    required this.color,
    required this.legend,
  });
}

// --- Data Model for Bar Chart ---
class BarChartGroupModel {
  final int x;
  final String groupName;
  final List<BarChartRodModel> rods;

  BarChartGroupModel({
    required this.x,
    required this.groupName,
    required this.rods,
  });
}

class BarChartRodModel {
  final double toY;
  final Color color;
  final String legend;

  BarChartRodModel({
    required this.toY,
    required this.color,
    required this.legend,
  });
}

class SingleBarDataModel {
  final String label;
  final double value;
  final Color color;

  SingleBarDataModel({
    required this.label,
    required this.value,
    this.color = Colors.blue, // Default color if not specified
  });
}



// --- Data Provider Class ---
class ChartDataProvider {

  // --- Data for Pie Chart (Symptoms) ---
  static List<PieChartDataModel> get symptomsPieData {
    return [
      PieChartDataModel(value: 28, title: '28%', color: Colors.blue, legend: 'Itching genital'),
      PieChartDataModel(value: 13, title: '13%', color: Colors.yellow, legend: 'Abnormal discharge'),
      PieChartDataModel(value: 9, title: '9%', color: Colors.purple, legend: 'Lower abdominal pain'),
      PieChartDataModel(value: 8, title: '8%', color: Colors.green, legend: 'Pain passing urine'),
    ];
  }

  // --- Data for Bar Chart (Behavioral) ---
  static List<BarChartGroupModel> get behavioralBarData {
    return [
      BarChartGroupModel(
        x: 0,
        groupName: "Partner Type",
        rods: [
          BarChartRodModel(toY: 18.1, color: Colors.blue, legend: "Regular partner"),
          BarChartRodModel(toY: 10.7, color: Colors.red, legend: "Non-regular partner"),
        ],
      ),
      BarChartGroupModel(
        x: 1,
        groupName: "Protection",
        rods: [
          BarChartRodModel(toY: 8.1, color: Colors.green, legend: "Protected"),
          BarChartRodModel(toY: 15.8, color: Colors.orange, legend: "Unprotected"),
        ],
      ),
      BarChartGroupModel(
        x: 2,
        groupName: "Partner Count",
        rods: [
          BarChartRodModel(toY: 9.8, color: Colors.purple, legend: "Single partner"),
          BarChartRodModel(toY: 11.4, color: Colors.pink, legend: "Multiple partners"),
        ],
      ),
    ];
  }
  // --- Data for Horizontal Bar Chart (STI Prevalence) ---
  static List<SingleBarDataModel> get stiPrevalenceData {
    return [
      SingleBarDataModel(label: 'HIV', value: 41.0, color: const Color(0xFFE53935)), // Red
      SingleBarDataModel(label: 'Trichomonas', value: 7.4, color: const Color(0xFF1E88E5)), // Blue
      SingleBarDataModel(label: 'Chlamydia', value: 2.6, color: const Color(0xFFFDD835)), // Yellow
      SingleBarDataModel(label: 'Syphilis', value: 2.6, color: const Color(0xFF8E24AA)), // Purple
      SingleBarDataModel(label: 'Gonorrhea', value: 1.3, color: const Color(0xFF43A047)), // Green
    ];
  }


}
