// lib/screens/chart.dart

import 'package:flutter/material.dart';
import 'package:digital_life_care_app/providers/chart_data_provider.dart';
import 'package:digital_life_care_app/screens/Analytics/bar_chart.dart';
import 'package:digital_life_care_app/screens/Analytics/pie_chart.dart';
import 'package:digital_life_care_app/screens/Analytics/horizontal_bar_chart.dart';
import 'package:digital_life_care_app/widgets/key_insight_card.dart'; // 1. IMPORT THE NEW WIDGET
import 'package:digital_life_care_app/widgets/top_actions.dart';
import 'package:digital_life_care_app/widgets/app_brand.dart';
import 'package:digital_life_care_app/widgets/ad_banner_widget.dart'; // 1. IMPORT THE NEW AD WIDGET

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:AppBar(
        backgroundColor: Colors.grey.shade100,
        leadingWidth: 56,
        leading: const Padding(
          padding: EdgeInsets.only(left: 12.0),
          child: AppBrand.compact(logoSize: 28),
        ),
        title: const Text('Analytics'),
        actions: const [TopActions()],
      )

      ,
      backgroundColor: const Color(0xFFF0F2F5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 2. REPLACE THE OLD BANNER WITH OUR NEW WIDGET
            const AdBannerWidget(),

            const SizedBox(height: 20),

            const KeyInsightCard(
              title: "KEY INSIGHT",
              statistic: "11%",
              description: "Prevalence among 2nd and 3rd-year students.",
              icon: Icons.school,
              iconColor: Colors.orange,
            ),
            const SizedBox(height: 20),

            CustomPieChart(
              title: "Common Symptoms Reported",
              data: ChartDataProvider.symptomsPieData,
            ),
            const SizedBox(height: 20),

            CustomBarChart(
              title: "Behavioral Risk Factors",
              yAxisLabel: "Percentage (%)",
              data: ChartDataProvider.behavioralBarData,
            ),
            const SizedBox(height: 20),

            CustomHorizontalBarChart(
              title: "STI Prevalence Among Students",
              data: ChartDataProvider.stiPrevalenceData,
            ),
          ],
        ),
      ),
    );
  }

// 3. THE _buildAdBanner METHOD IS NO LONGER NEEDED AND HAS BEEN REMOVED
}
