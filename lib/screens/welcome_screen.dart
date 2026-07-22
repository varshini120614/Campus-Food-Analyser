import 'dart:ui';
import 'package:flutter/material.dart';

import 'entry_screen.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'budget_screen.dart';
import 'location_screen.dart';

class WelcomeScreen extends StatelessWidget {
  final String location;

  const WelcomeScreen({super.key, required this.location});

  Widget buildButton(BuildContext context, String text, Widget page) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          minimumSize: const Size(260, 55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: () async {
          await Future.delayed(const Duration(milliseconds: 50));

          Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
        },
        child: Text(text),
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              const Text(
                "Campus Food Analyzer",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3F2E56),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "📍 $location",
                style: const TextStyle(fontSize: 22, color: Color(0xFF3F2E56)),
              ),

              const SizedBox(height: 40),

              buildButton(
                context,
                "Enter Food Entry",
                EntryScreen(location: location),
              ),

              buildButton(
                context,
                "Dashboard",
                DashboardScreen(location: location),
              ),

              buildButton(
                context,
                "Entry History",
                HistoryScreen(location: location),
              ),

              buildButton(
                context,
                "Budget Food Finder",
                BudgetScreen(location: location),
              ),

              buildButton(context, "Select Location", const LocationScreen()),
            ],
          ),
        ),
      ),
    );
  }
}
