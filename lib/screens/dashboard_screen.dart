import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

import 'welcome_screen.dart';

class DashboardScreen extends StatelessWidget {
  final String location;

  const DashboardScreen({super.key, required this.location});

  Future<List<Map<String, dynamic>>> fetchData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("restaurant_logs")
        .where("location", isEqualTo: location)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Map<String, dynamic> analyzeData(List<Map<String, dynamic>> data) {
    Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var entry in data) {
      String restaurant = entry["restaurantName"] ?? "Unknown";

      grouped.putIfAbsent(restaurant, () => []);
      grouped[restaurant]!.add(entry);
    }

    Map<String, dynamic> restaurantStats = {};

    String bestSatRestaurant = "";
    double bestSat = 0;

    String bestEnergyRestaurant = "";
    double bestEnergy = 0;

    String bestValueRestaurant = "";
    double bestValue = 0;

    grouped.forEach((restaurant, entries) {
      double totalSat = 0;
      double totalEnergy = 0;
      double totalCost = 0;

      Map<String, int> moods = {};

      for (var e in entries) {
        totalSat += (e["satisfaction"] as num).toDouble();
        totalEnergy += (e["energyLevel"] as num).toDouble();
        totalCost += (e["cost"] as num).toDouble();

        String mood = e["mood"] ?? "Unknown";
        moods[mood] = (moods[mood] ?? 0) + 1;
      }

      double avgSat = totalSat / entries.length;
      double avgEnergy = totalEnergy / entries.length;
      double avgCost = totalCost / entries.length;

      double energyReturn = avgEnergy / avgCost;

      String frequentMood = moods.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      restaurantStats[restaurant] = {
        "avgSat": avgSat,
        "avgEnergy": avgEnergy,
        "avgCost": avgCost,
        "energyReturn": energyReturn,
        "mood": frequentMood,
        "moodMap": moods,
      };

      if (avgSat > bestSat) {
        bestSat = avgSat;
        bestSatRestaurant = restaurant;
      }

      if (avgEnergy > bestEnergy) {
        bestEnergy = avgEnergy;
        bestEnergyRestaurant = restaurant;
      }

      double valueScore = avgSat / avgCost;

      if (valueScore > bestValue) {
        bestValue = valueScore;
        bestValueRestaurant = restaurant;
      }
    });

    return {
      "stats": restaurantStats,
      "bestSat": bestSatRestaurant,
      "bestEnergy": bestEnergyRestaurant,
      "bestValue": bestValueRestaurant,
    };
  }

  Widget victoryTile(String title, String restaurant, IconData icon) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.4)),
            ),
            child: Column(
              children: [
                Icon(icon, size: 34, color: const Color(0xFF3F2E56)),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(restaurant, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }

  final List<Color> chartColors = const [
    Color(0xFFB9A9FF),
    Color(0xFFF5A9C6),
    Color(0xFF8EC5FC),
    Color(0xFFE684AE),
    Color(0xFF7F7FD5),
  ];

  List<PieChartSectionData> buildMoodChart(Map<String, int> moodMap) {
    int total = moodMap.values.fold(0, (a, b) => a + b);

    int i = 0;

    return moodMap.entries.map((entry) {
      final percentage = (entry.value / total) * 100;

      return PieChartSectionData(
        color: chartColors[i++ % chartColors.length],
        value: percentage,
        title: "${percentage.toStringAsFixed(0)}%",
        radius: 70,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget buildLegend(Map<String, int> moodMap) {
    int i = 0;

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: moodMap.keys.map((mood) {
        final color = chartColors[i++ % chartColors.length];

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 14, height: 14, color: color),
            const SizedBox(width: 6),
            Text(mood),
          ],
        );
      }).toList(),
    );
  }

  Widget restaurantCard(String name, Map<String, dynamic> stats) {
    Map<String, int> moodMap = Map<String, int>.from(stats["moodMap"]);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3F2E56),
                ),
              ),
              const SizedBox(height: 10),

              Text(
                "Average Satisfaction: ${stats["avgSat"].toStringAsFixed(2)}",
              ),
              Text("Average Energy: ${stats["avgEnergy"].toStringAsFixed(2)}"),
              Text("Most Frequent Mood: ${stats["mood"]}"),

              const SizedBox(height: 18),

              const Text(
                "Mood Distribution",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              Center(
                child: SizedBox(
                  height: 220,
                  width: 220,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 60,
                      sections: buildMoodChart(moodMap),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              buildLegend(moodMap),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF8EC5FC), Color(0xFFE0C3FC), Color(0xFFFBC2EB)],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder(
            future: fetchData(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = snapshot.data!;
              final analysis = analyzeData(data);

              Map<String, dynamic> stats = analysis["stats"];

              return Padding(
                padding: const EdgeInsets.all(20),
                child: ListView(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Dashboard\n📍 $location",
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3F2E56),
                          ),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.home),
                          label: const Text("Home Page"),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    WelcomeScreen(location: location),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      "Victory Stand",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        victoryTile(
                          "Highest Satisfaction",
                          analysis["bestSat"],
                          Icons.emoji_events,
                        ),
                        victoryTile(
                          "Highest Energy",
                          analysis["bestEnergy"],
                          Icons.flash_on,
                        ),
                        victoryTile(
                          "Best Value",
                          analysis["bestValue"],
                          Icons.money,
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      "Restaurant Performance",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    ...stats.entries.map((e) {
                      return restaurantCard(e.key, e.value);
                    }).toList(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
