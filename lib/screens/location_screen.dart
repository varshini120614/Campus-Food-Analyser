import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'welcome_screen.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final TextEditingController controller = TextEditingController();

  Future<List<String>> getLocations() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("restaurant_logs")
        .get();

    List<String> locations = [];

    for (var doc in snapshot.docs) {
      if (doc.data().containsKey("location")) {
        locations.add(doc["location"]);
      }
    }

    return locations.toSet().toList();
  }

  void goNext() {
    String location = controller.text.trim();

    if (location.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter a location")));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WelcomeScreen(location: location),
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
          child: Padding(
            padding: const EdgeInsets.all(30),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                const Text(
                  "Select Campus Location",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3F2E56),
                  ),
                ),

                const SizedBox(height: 30),

                FutureBuilder<List<String>>(
                  future: getLocations(),

                  builder: (context, snapshot) {
                    return Autocomplete<String>(
                      optionsBuilder: (textEditingValue) {
                        if (!snapshot.hasData) {
                          return const Iterable<String>.empty();
                        }

                        return snapshot.data!.where(
                          (option) => option.toLowerCase().contains(
                            textEditingValue.text.toLowerCase(),
                          ),
                        );
                      },

                      onSelected: (selection) {
                        controller.text = selection;
                      },

                      fieldViewBuilder:
                          (
                            context,
                            textController,
                            focusNode,
                            onEditingComplete,
                          ) {
                            controller.text = textController.text;

                            textController.addListener(() {
                              controller.text = textController.text;
                            });

                            return TextField(
                              controller: textController,
                              focusNode: focusNode,
                              decoration: const InputDecoration(
                                labelText: "Enter Location (MIT Manipal etc)",
                                border: OutlineInputBorder(),
                              ),
                            );
                          },
                    );
                  },
                ),

                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: goNext,
                  child: const Text("Continue"),
                ),
              ],
            ),
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: goNext,
        child: const Icon(Icons.arrow_forward),
      ),
    );
  }
}
