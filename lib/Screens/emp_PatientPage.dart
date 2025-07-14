import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:med_ad_admin/Screens/emp_ddmedtopatientPage.dart';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:typed_data'; // Import Uint8List

class EmpPatientpage extends StatefulWidget {
  const EmpPatientpage({super.key});

  @override
  State<EmpPatientpage> createState() => _EmpPatientpageState();
}

class _EmpPatientpageState extends State<EmpPatientpage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> patients = [];
  int _currentPage = 0;
  final int _itemsPerPage = 10; // Max 10 items per page
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredPatients = [];

  @override
  void initState() {
    super.initState();
    fetchPatients();
    _searchController.addListener(_filterPatients); // Add listener for search
  }

  @override
  void dispose() {
    _searchController.dispose(); // Dispose controller when widget is removed
    super.dispose();
  }

  Future<void> _downloadExcel() async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Sheet1'];

    // Add column headers
    sheet.appendRow(["ID", "Name", "Phone"]);

    // Add patients data
    for (var patient in patients) {
      sheet.appendRow([patient["id"], patient["name"], patient["phone"]]);
    }

    var bytes = excel.save();
    final String fileName = 'patients.xlsx';
    final MimeType mimeType = MimeType.microsoftExcel;

    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: Uint8List.fromList(bytes!), // Convert List<int> to Uint8List
      mimeType: mimeType, // Pass MimeType directly
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('File saved as: $fileName')),
    );
  }

  Future<void> fetchPatients() async {
    try {
      // Fetch all documents first
      QuerySnapshot snapshot =
          await _firestore.collection('ActivePatient').get();

      setState(() {
        patients = snapshot.docs.map((doc) {
          return {
            "id": doc["patientId"],
            "name": doc["patientName"],
            "phone": doc["patientPhone"],
            // Safely add timestamp field (handling null case)
            "timestamp": (doc.data() as Map<String, dynamic>?)?.containsKey('timestamp') == true
                         ? doc["timestamp"]
                         : null, // If not present, set to null
          };
        }).toList();

        // **Sort locally (oldest to newest)**
        patients.sort((a, b) {
          // If both items have a timestamp, sort them
          if (a["timestamp"] != null && b["timestamp"] != null) {
            return (a["timestamp"] as Timestamp).compareTo(b["timestamp"] as Timestamp);
          }
          // If one or both don't have a timestamp, don't change relative order
          return 0;
        });

        _filteredPatients = patients; // Initialize the filtered list
      });
    } catch (e) {
      print("Error fetching patients: $e");
    }
  }

  void _filterPatients() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPatients = patients.where((patient) {
        // Ensure fields are not null before calling toLowerCase
        final String patientId = patient["id"]?.toLowerCase() ?? '';
        final String patientName = patient["name"]?.toLowerCase() ?? '';
        final String patientPhone = patient["phone"]?.toLowerCase() ?? '';

        return patientName.contains(query) ||
               patientId.contains(query) ||
               patientPhone.contains(query);
      }).toList();
      _currentPage = 0; // Reset to the first page on filter
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // Pagination calculations
    final int _totalPages = (_filteredPatients.length / _itemsPerPage).ceil();
    final int _startIndex = _currentPage * _itemsPerPage;
    final int _endIndex = (_startIndex + _itemsPerPage).clamp(0, _filteredPatients.length);
    final List<Map<String, dynamic>> _currentPatients =
        _filteredPatients.sublist(_startIndex, _endIndex);

    return Center(
      child: Container(
        padding: EdgeInsets.all(20),
        width: screenWidth * 0.8,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _searchController, // Link search controller
                decoration: InputDecoration(
                  hintText: "Search Patients...", // Search hint text
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              SizedBox(height: screenHeight * 0.02),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: screenWidth * 0.08,
                  dataRowColor: MaterialStateProperty.resolveWith<Color?>(
                      (Set<MaterialState> states) {
                    return states.contains(MaterialState.selected)
                        ? Colors.grey[300]
                        : null;
                  }),
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
                        label: Text("Name",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: screenWidth * 0.01))),
                    DataColumn(
                        label: Text("Phone",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: screenWidth * 0.01))),
                    DataColumn(
                        label: Text("View Profile",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: screenWidth * 0.01))),
                  ],
                  rows: _currentPatients.map((patient) {
                    return DataRow(
                      color: MaterialStateProperty.all(
                          _currentPatients.indexOf(patient).isEven
                              ? Colors.grey[200]
                              : Colors.white),
                      cells: [
                        DataCell(Text(patient["id"],
                            style: TextStyle(fontSize: screenWidth * 0.01))),
                        DataCell(Text(patient["name"],
                            style: TextStyle(fontSize: screenWidth * 0.01))),
                        DataCell(Text(patient["phone"],
                            style: TextStyle(fontSize: screenWidth * 0.01))),
                        DataCell(ElevatedButton(
                            onPressed: () async {
                              // Improved fetching of patient data for profile view
                              DocumentSnapshot patientDoc;
                              try {
                                patientDoc = await _firestore
                                    .collection('ActivePatient')
                                    .doc(patient["id"]) // Assuming patient["id"] is the document ID
                                    .get();
                              } catch (e) {
                                // If patient["id"] is not the document ID, try searching by field
                                QuerySnapshot querySnapshot = await _firestore
                                    .collection('ActivePatient')
                                    .where('patientId', isEqualTo: patient["id"])
                                    .limit(1)
                                    .get();
                                if (querySnapshot.docs.isNotEmpty) {
                                  patientDoc = querySnapshot.docs.first;
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Patient not found.')),
                                  );
                                  return;
                                }
                              }

                              if (patientDoc.exists) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AempDdmedtopatientpage(
                                      patientId: patientDoc["patientId"],
                                      patientName: patientDoc["patientName"],
                                      patientPhone: patientDoc["patientPhone"],
                                      // Add other data here if needed
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Patient data not found for profile view.')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: screenHeight * 0.03,
                                  vertical: screenHeight * 0.01),
                            ),
                            child: Text("View",
                                style: TextStyle(
                                    fontSize: screenWidth * 0.01)))),
                      ],
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 20),
              // Pagination controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back),
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
                    icon: Icon(Icons.arrow_forward),
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
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _downloadExcel,
                icon: Icon(Icons.download),
                label: Text("Download as Excel"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}