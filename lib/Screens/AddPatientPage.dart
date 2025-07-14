import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddPatientPage extends StatefulWidget {
  const AddPatientPage({super.key});

  @override
  State<AddPatientPage> createState() => _AddPatientPageState();
}

class _AddPatientPageState extends State<AddPatientPage> {
  List<Map<String, dynamic>> patientIds = [];
  TextEditingController _idController = TextEditingController();
  TextEditingController _searchController = TextEditingController(); // Search controller
  final CollectionReference patientsCollection =
      FirebaseFirestore.instance.collection("AddPatient");

  List<Map<String, dynamic>> _filteredPatientIds = []; // Filtered list for search
  int _currentPage = 0;
  final int _itemsPerPage = 10; // Items per page for pagination

  @override
  void initState() {
    super.initState();
    fetchPatientIds();
    _searchController.addListener(_filterPatientIds); // Listen for search input changes
  }

  @override
  void dispose() {
    _idController.dispose();
    _searchController.dispose(); // Dispose search controller
    super.dispose();
  }

  // 🔹 Save the ID to Firestore
  Future<void> savePatientId() async {
    String patientId = _idController.text.trim();
    if (patientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a patient ID.')),
      );
      return;
    }

    // Check if ID already exists
    final existingDocs = await patientsCollection.where('id', isEqualTo: patientId).get();
    if (existingDocs.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient ID already exists.')),
      );
      return;
    }

    try {
      await patientsCollection.add({
        'id': patientId,
        'timestamp': FieldValue.serverTimestamp(), // Add server timestamp for sorting
      });
      _idController.clear();
      fetchPatientIds(); // Refresh the list
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient ID added successfully!')),
      );
    } catch (e) {
      print("Error saving patient ID: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add patient ID. Please try again.')),
      );
    }
  }

  // 🔹 Fetch all IDs from Firestore and sort them
  Future<void> fetchPatientIds() async {
    try {
      // Fetch all documents from Firestore
      QuerySnapshot snapshot = await patientsCollection.get();

      setState(() {
        // Map documents to a list of maps, safely handling missing fields
        patientIds = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>?; // Cast to nullable map
          return {
            "id": data?['id']?.toString() ?? 'N/A', // Null-safe access for 'id'
            "timestamp": data?.containsKey('timestamp') == true ? data!['timestamp'] : null,
          };
        }).toList();

        // Sort the main `patientIds` list by timestamp (oldest first)
        patientIds.sort((a, b) {
          final Timestamp? timestampA = a["timestamp"] as Timestamp?;
          final Timestamp? timestampB = b["timestamp"] as Timestamp?;

          // Prefer sorting by timestamp (oldest first)
          if (timestampA != null && timestampB != null) {
            return timestampA.compareTo(timestampB);
          }
          // If only one has a timestamp, the one with the timestamp comes first
          else if (timestampA != null) {
            return -1; // 'a' comes before 'b'
          } else if (timestampB != null) {
            return 1; // 'b' comes before 'a'
          }
          // If neither has a timestamp, sort by ID (alphabetically)
          else {
            return (a["id"] as String).compareTo(b["id"] as String);
          }
        });

        // Initialize the filtered list with the now-sorted patientIds
        _filteredPatientIds = patientIds;
        // Reset current page to 0 after fetching and sorting
        _currentPage = 0;
      });
    } catch (e) {
      print("Error fetching patient IDs: $e");
    }
  }

  // 🔹 Filter patient IDs based on search query
  void _filterPatientIds() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      // Filter from the *already sorted* `patientIds` list
      _filteredPatientIds = patientIds.where((patient) {
        final String patientId = patient["id"]?.toLowerCase() ?? '';
        return patientId.contains(query);
      }).toList();
      _currentPage = 0; // Reset to first page on filter
    });
  }

  // 🔹 Function to show confirmation dialog and then delete
  Future<void> _confirmAndDelete(String id) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete patient ID: $id?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // User tapped "Cancel"
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // User tapped "Delete"
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      // Only proceed with deletion if confirm is true
      _performDelete(id);
    }
  }

  // 🔹 Actual deletion logic
  Future<void> _performDelete(String id) async {
    try {
      QuerySnapshot snapshot =
          await patientsCollection.where('id', isEqualTo: id).get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      fetchPatientIds(); // Refresh data after deletion
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient ID deleted successfully!')),
      );
    } catch (e) {
      print("Error deleting patient ID: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete patient ID. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // Pagination calculations
    final int _totalPages = (_filteredPatientIds.length / _itemsPerPage).ceil();
    final int _startIndex = _currentPage * _itemsPerPage;
    final int _endIndex = (_startIndex + _itemsPerPage).clamp(0, _filteredPatientIds.length);
    final List<Map<String, dynamic>> _currentPatientIds =
        _filteredPatientIds.sublist(_startIndex, _endIndex);

    return Scaffold(
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          width: screenWidth * 0.8,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Enter Patient ID",
                        style: TextStyle(
                            fontSize: screenWidth * 0.015,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: screenHeight * 0.01),
                    TextField(
                      controller: _idController,
                      decoration: InputDecoration(
                        hintText: "Enter Patient ID...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    ElevatedButton(
                      onPressed: savePatientId,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: Text("Add Patient",
                          style: TextStyle(fontSize: screenWidth * 0.015)),
                    ),
                  ],
                ),
              ),
              VerticalDivider(
                width: screenWidth * 0.05,
                thickness: 1,
                color: Colors.grey,
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column( // Use Column to include search and pagination
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: "Search Patient IDs...",
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Expanded( // Allow DataTable to take available space
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: DataTable(
                            columnSpacing: screenWidth * 0.08,
                            headingRowColor:
                                MaterialStateProperty.all(Colors.blueGrey[100]),
                            border: TableBorder.all(color: Colors.grey),
                            columns: [
                              DataColumn(
                                  label: Text("ID",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: screenWidth * 0.01))),
                              DataColumn(
                                  label: Text("Delete",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: screenWidth * 0.01))),
                            ],
                            rows: List.generate(_currentPatientIds.length, (index) {
                              final patient = _currentPatientIds[index];
                              return DataRow(
                                color: MaterialStateProperty.all(
                                    index.isEven ? Colors.grey[200] : Colors.white),
                                cells: [
                                  DataCell(Text(patient["id"],
                                      style: TextStyle(fontSize: screenWidth * 0.01))),
                                  DataCell(IconButton(
                                    icon: Icon(Icons.delete,
                                        color: Colors.red, size: screenWidth * 0.02),
                                    onPressed: () => _confirmAndDelete(patient["id"]), // Call the new confirmation function
                                  )),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      // Pagination controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: _currentPage > 0
                                ? () {
                                    setState(() {
                                      _currentPage--;
                                    });
                                  }
                                : null, // Disable button if this is the first page
                          ),
                          Text('Page ${_currentPage + 1} of $_totalPages'), // Display current page number
                          IconButton(
                            icon: const Icon(Icons.arrow_forward),
                            onPressed: _currentPage < _totalPages - 1
                                ? () {
                                    setState(() {
                                      _currentPage++;
                                    });
                                  }
                                : null, // Disable button if this is the last page
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}