import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'welcome_screen.dart';

class BudgetScreen extends StatefulWidget {
  final String location;

  const BudgetScreen({super.key, required this.location});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final budgetController = TextEditingController();
  int? budget;

  Stream<QuerySnapshot> getFoodEntries() {
    return FirebaseFirestore.instance
        .collection("restaurant_logs")
        .where("location", isEqualTo: widget.location)
        .snapshots();
  }

  Map<String, List<Map<String, dynamic>>> groupByDish(
    List<QueryDocumentSnapshot> docs,
  ) {
    Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};

      final dish = data["dishName"] ?? "Unknown Dish";
      final restaurant = data["restaurantName"] ?? "Unknown Restaurant";
      final cost = data["cost"] ?? 0;

      if (!grouped.containsKey(dish)) {
        grouped[dish] = [];
      }

      grouped[dish]!.add({"restaurant": restaurant, "cost": cost});
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Budget Food Finder (${widget.location})"),
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
              /// BUDGET SEARCH BAR
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(30),
                ),

                child: TextField(
                  controller: budgetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: "Enter your budget (₹)",
                    border: InputBorder.none,
                    icon: Icon(Icons.search),
                  ),

                  onChanged: (value) {
                    setState(() {
                      budget = int.tryParse(value);
                    });
                  },
                ),
              ),

              const SizedBox(height: 20),

              /// RESULTS AREA
              Expanded(
                child: budget == null
                    ? const Center(
                        child: Text(
                          "Enter a budget to see food options",
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : StreamBuilder<QuerySnapshot>(
                        stream: getFoodEntries(),

                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const Center(
                              child: Text("No food entries yet"),
                            );
                          }

                          final docs = snapshot.data!.docs;
                          final grouped = groupByDish(docs);

                          return ListView(
                            children: grouped.entries.map((entry) {
                              final dish = entry.key;
                              final options = entry.value;

                              final filtered = options
                                  .where((item) => item["cost"] <= budget)
                                  .toList();

                              if (filtered.isEmpty) {
                                return const SizedBox();
                              }

                              filtered.sort(
                                (a, b) => (a["cost"] as int).compareTo(
                                  b["cost"] as int,
                                ),
                              );

                              return Card(
                                elevation: 4,
                                margin: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),

                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),

                                child: Padding(
                                  padding: const EdgeInsets.all(16),

                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,

                                    children: [
                                      Text(
                                        dish,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      const SizedBox(height: 10),

                                      Column(
                                        children: filtered.map((item) {
                                          return ListTile(
                                            contentPadding: EdgeInsets.zero,

                                            leading: const Icon(
                                              Icons.restaurant,
                                            ),

                                            title: Text(item["restaurant"]),

                                            trailing: Text(
                                              "₹${item["cost"]}",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
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
