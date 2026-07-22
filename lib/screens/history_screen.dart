import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'welcome_screen.dart';

class HistoryScreen extends StatefulWidget {
  final String location;

  const HistoryScreen({super.key, required this.location});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String selectedLocation = "All";
  List<String> locations = ["All"];

  @override
  void initState() {
    super.initState();
    loadLocations();
  }

  /// LOAD LOCATIONS FROM FIRESTORE
  void loadLocations() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("restaurant_logs")
        .get();

    final locs = snapshot.docs
        .map(
          (doc) => (doc.data() as Map<String, dynamic>)["location"] as String?,
        )
        .where((loc) => loc != null)
        .cast<String>()
        .toSet()
        .toList();

    setState(() {
      locations = ["All", ...locs];
    });
  }

  /// GET STREAM BASED ON FILTER
  Stream<QuerySnapshot> getEntries() {
    final base = FirebaseFirestore.instance.collection("restaurant_logs");

    if (selectedLocation == "All") {
      return base.snapshots();
    } else {
      return base.where("location", isEqualTo: selectedLocation).snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Food Entry History"),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => WelcomeScreen(location: widget.location),
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
          padding: const EdgeInsets.fromLTRB(20, 120, 20, 20),

          child: Column(
            children: [
              /// LOCATION FILTER
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(30),
                  ),

                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedLocation,
                      items: locations
                          .map(
                            (loc) =>
                                DropdownMenuItem(value: loc, child: Text(loc)),
                          )
                          .toList(),

                      onChanged: (value) {
                        setState(() {
                          selectedLocation = value!;
                        });
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// LIST OF ENTRIES
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: getEntries(),

                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("No entries yet"));
                    }

                    final docs = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: docs.length,

                      itemBuilder: (context, index) {
                        final data =
                            docs[index].data() as Map<String, dynamic>? ?? {};

                        final restaurant =
                            data["restaurantName"] ?? "Unknown Restaurant";
                        final dish = data["dishName"] ?? "Unknown Dish";
                        final cost = data["cost"] ?? 0;
                        final mood = data["mood"] ?? "-";
                        final energy = data["energyLevel"] ?? "-";
                        final satisfaction = data["satisfaction"] ?? "-";
                        final location = data["location"] ?? "-";

                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 10),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),

                          child: Padding(
                            padding: const EdgeInsets.all(16),

                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                Text(
                                  restaurant,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                Text("Dish: $dish"),
                                Text("Cost: ₹$cost"),
                                Text("Mood: $mood"),
                                Text("Energy: $energy / 5"),
                                Text("Satisfaction: $satisfaction / 5"),

                                const SizedBox(height: 6),

                                Text(
                                  "Location: $location",
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
