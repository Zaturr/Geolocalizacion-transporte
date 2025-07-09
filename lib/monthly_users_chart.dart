// lib/monthly_users_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math'; // For generating random data

class MonthlyUsersChart extends StatelessWidget {
  const MonthlyUsersChart({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final List<int> dailyUserCounts = List.generate(
      30,
          (index) => Random().nextInt(46) + 5, // Random number between 5 and 50
    );

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < dailyUserCounts.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i, // X-axis value (day index)
          barRods: [
            BarChartRodData(
              toY: dailyUserCounts[i].toDouble(), // Y-axis value (user count)
              color: colorScheme.primary, // Bar color
              width: 8,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
          showingTooltipIndicators: [],
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nuevos Usuarios (Último Mes)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() % 5 == 0) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 4,
                              child: Text(
                                (value.toInt() + 1).toString(),
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          );
                        },
                        interval: 10,
                        reservedSize: 30,
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colorScheme.onSurface.withOpacity(0.1),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      // FIX: Replaced tooltipBgColor with getTooltipColor
                      getTooltipColor: (BarChartGroupData group) {
                        return colorScheme.inverseSurface; // Return your desired background color
                      },
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          'Día ${group.x + 1}\n',
                          TextStyle(color: colorScheme.onInverseSurface, fontWeight: FontWeight.bold),
                          children: <TextSpan>[
                            TextSpan(
                              text: '${rod.toY.toInt()} usuarios',
                              style: TextStyle(
                                color: colorScheme.onInverseSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
                      // Handle touch events if needed
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}