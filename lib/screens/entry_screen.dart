import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'welcome_screen.dart';

class EntryScreen extends StatefulWidget {
  final String location;

  const EntryScreen({super.key, required this.location});

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  final restaurantController = TextEditingController();
  final dishController = TextEditingController();
  final costController = TextEditingController();

  String mood = "Happy";
  double energy = 3;
  double satisfaction = 3;

  List<String> restaurantList = [];

  @override
  void initState() {
    super.initState();
    loadRestaurants();
  }

  void loadRestaurants() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("restaurant_logs")
        .where("location", isEqualTo: widget.location)
        .get();

    List<String> restaurants = snapshot.docs
        .map((doc) => doc["restaurantName"] as String?)
        .where((name) => name != null)
        .cast<String>()
        .toSet()
        .toList();

    setState(() {
      restaurantList = restaurants;
    });
  }

  void saveEntry() async {
    if (restaurantController.text.isEmpty ||
        dishController.text.isEmpty ||
        costController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    await FirebaseFirestore.instance.collection("restaurant_logs").add({
      "location": widget.location,
      "restaurantName": restaurantController.text,
      "dishName": dishController.text,
      "cost": int.tryParse(costController.text) ?? 0,
      "mood": mood,
      "energyLevel": energy.toInt(),
      "satisfaction": satisfaction.toInt(),
      "createdAt": Timestamp.now(),
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Entry saved")));

    restaurantController.clear();
    dishController.clear();
    costController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Food Entry (${widget.location})"),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      WelcomeScreen(location: widget.location),
                ),
              );
            },
          ),
        ],
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF8EC5FC), Color(0xFFE0C3FC), Color(0xFFFBC2EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: Padding(
          padding: const EdgeInsets.all(20),

          child: ListView(
            children: [
              /// RESTAURANT AUTOCOMPLETE
              Autocomplete<String>(
                optionsBuilder: (textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return restaurantList;
                  }

                  return restaurantList.where(
                    (option) => option.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    ),
                  );
                },

                onSelected: (selection) {
                  restaurantController.text = selection;
                },

                fieldViewBuilder:
                    (context, textController, focusNode, onEditingComplete) {
                      textController.text = restaurantController.text;

                      return TextField(
                        controller: textController,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: "Restaurant",
                          hintText: "Start typing restaurant name",
                        ),
                        onChanged: (value) {
                          restaurantController.text = value;
                        },
                      );
                    },
              ),

              const SizedBox(height: 20),

              TextField(
                controller: dishController,
                decoration: const InputDecoration(labelText: "Dish"),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: costController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Cost"),
              ),

              const SizedBox(height: 20),

              DropdownButtonFormField(
                value: mood,
                items: const [
                  DropdownMenuItem(value: "Happy", child: Text("Happy")),
                  DropdownMenuItem(value: "Neutral", child: Text("Neutral")),
                  DropdownMenuItem(value: "Tired", child: Text("Tired")),
                  DropdownMenuItem(value: "Stressed", child: Text("Stressed")),
                  DropdownMenuItem(
                    value: "Energetic",
                    child: Text("Energetic"),
                  ),
                ],
                onChanged: (v) => setState(() => mood = v!),
                decoration: const InputDecoration(labelText: "Mood"),
              ),

              const SizedBox(height: 30),

              const Text("Energy Level"),

              Slider(
                value: energy,
                min: 1,
                max: 5,
                divisions: 4,
                label: energy.toString(),
                onChanged: (v) {
                  setState(() {
                    energy = v;
                  });
                },
              ),

              const SizedBox(height: 10),

              const Text("Satisfaction"),

              Slider(
                value: satisfaction,
                min: 1,
                max: 5,
                divisions: 4,
                label: satisfaction.toString(),
                onChanged: (v) {
                  setState(() {
                    satisfaction = v;
                  });
                },
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: saveEntry,
                child: const Text("Save Entry"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
