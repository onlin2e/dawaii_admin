import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class AempDdmedtopatientpage extends StatefulWidget {
    final String patientId;
  final String patientName;
  final String patientPhone;

  const AempDdmedtopatientpage({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
  });

  @override
  State<AempDdmedtopatientpage> createState() => _AempDdmedtopatientpageState();
}

class _AempDdmedtopatientpageState extends State<AempDdmedtopatientpage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final Uuid uuid = Uuid();
    DateTime _selectedMonth = DateTime.now();
    
  Future<void> addMedicine(Map<String, dynamic> medicineData) async {
    await _firestore
        .collection('ActivePatient')
        .doc(widget.patientId)
        .collection('PatientMedicine')
        .add(medicineData);
  }

  void showAddMedicineDialog() {
  TextEditingController dosageController = TextEditingController();
  TextEditingController conditionController = TextEditingController();
  TextEditingController pillsPerDoseController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  List<String> _medicineTimes = [];
  List<String> _nowTimes = [];
  String? selectedMedicineName;
  String? selectedMedicineImageUrl;

  Future<void> _pickStartTime(BuildContext context, StateSetter dialogSetState) async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      final now = DateTime.now();
      final dateTime = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      final utcDateTime = dateTime.toUtc();
      dialogSetState(() {
        _medicineTimes.add('${utcDateTime.hour.toString().padLeft(2, '0')}:${utcDateTime.minute.toString().padLeft(2, '0')}');
        _nowTimes.add('${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
      });
    }
  }

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Add Medicine"),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FutureBuilder<QuerySnapshot>(
                    future: _firestore.collection('medicines').get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      }
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Text('No medicines found.');
                      }
                      List<String> medicineNames = snapshot.data!.docs.map((doc) => doc['name'].toString()).toList();
                      return DropdownButtonFormField<String>(
                        value: selectedMedicineName,
                        items: medicineNames.map((name) {
                          return DropdownMenuItem<String>(
                            value: name,
                            child: Text(name),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          setState(() {
                            selectedMedicineName = value;
                            selectedMedicineImageUrl = snapshot.data!.docs
                                .firstWhere((doc) => doc['name'] == value)['imageUrl'];
                          });
                        },
                        decoration: InputDecoration(labelText: "Select Medicine"),
                      );
                    },
                  ),
                  TextField(controller: dosageController, decoration: InputDecoration(labelText: "Dosage")),
                  TextField(controller: conditionController, decoration: InputDecoration(labelText: "Medication Instructions")),
                  TextField(controller: pillsPerDoseController, decoration: InputDecoration(labelText: "Number of Pills Per Dose")),
                  SizedBox(height: 10),
                  ListTile(
                    title: Text(_startDate == null ? "Select Start Date" : DateFormat.yMMMd().format(_startDate!.toLocal())),
                    trailing: Icon(Icons.calendar_today),
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _startDate = picked.toUtc());
                      }
                    },
                  ),
                  ListTile(
                    title: Text(_endDate == null ? "Select End Date" : DateFormat.yMMMd().format(_endDate!.toLocal())),
                    trailing: Icon(Icons.calendar_today),
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _endDate = picked.toUtc());
                      }
                    },
                  ),
                  Text("Medicine Times (Local)"), // عرض الوقت المحلي هنا
                  ..._nowTimes.map((time) => ListTile(title: Text(time), trailing: Icon(Icons.check_circle, color: Colors.green))),
                  ElevatedButton(
                    onPressed: () => _pickStartTime(context, setState), // تمرير setState الخاص بالـ AlertDialog
                    child: Text("Add Time"),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (selectedMedicineName != null && dosageController.text.isNotEmpty &&
                  pillsPerDoseController.text.isNotEmpty && _startDate != null && _endDate != null) {
                Map<String, dynamic> newMedicine = {
                  "MedicineName": selectedMedicineName,
                  "MedicineDosage": dosageController.text,
                  "Medication Instructions": conditionController.text,
                  "NumberOfPillsPerDose": pillsPerDoseController.text,
                  "StartDate": _startDate,
                  "EndDate": _endDate,
                  "MedicineTime": _medicineTimes,
                  "nowTime": _nowTimes,
                  "MedicineImageUrl": selectedMedicineImageUrl,
                };
                addMedicine(newMedicine);
                Navigator.pop(context);
              }
            },
            child: Text("Save"),
          ),
        ],
      );
    },
  );
}

/// تعديل دواء موجود
void showEditMedicineDialog(DocumentSnapshot medicineDoc) {
  TextEditingController nameController = TextEditingController(text: medicineDoc['MedicineName']);
  TextEditingController dosageController = TextEditingController(text: medicineDoc['MedicineDosage']);
  TextEditingController conditionController = TextEditingController(text: medicineDoc['Medication Instructions']);
  TextEditingController pillsPerDoseController = TextEditingController(text: medicineDoc['NumberOfPillsPerDose']?.toString() ?? '');
  DateTime _startDate = (medicineDoc['StartDate'] as Timestamp).toDate().toUtc();
  DateTime _endDate = (medicineDoc['EndDate'] as Timestamp).toDate().toUtc();
  // استرداد الأوقات بتوقيت UTC وعرضها بالتوقيت المحلي
  List<String> _medicineTimesUtc = List<String>.from(medicineDoc['MedicineTime'] ?? []);
  List<String> _medicineTimesLocal = _medicineTimesUtc.map((utcTimeString) {
    final parts = utcTimeString.split(':');
    final utcTime = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day, int.parse(parts[0]), int.parse(parts[1]));
    return DateFormat('HH:mm').format(utcTime.toLocal());
  }).toList();

  Future<void> _editTime(BuildContext context, String oldTimeLocal, StateSetter dialogSetState) async {
    final partsLocal = oldTimeLocal.split(':');
    final initialTime = TimeOfDay(hour: int.parse(partsLocal[0]), minute: int.parse(partsLocal[1]));
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: initialTime);
    if (picked != null) {
      dialogSetState(() {
        final now = DateTime.now();
        final dateTime = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
        final newTimeUtcString = '${dateTime.toUtc().hour.toString().padLeft(2, '0')}:${dateTime.toUtc().minute.toString().padLeft(2, '0')}';
        final newTimeLocal = DateFormat('HH:mm').format(dateTime.toLocal());

        final localIndex = _medicineTimesLocal.indexOf(oldTimeLocal);
        if (localIndex != -1) {
          _medicineTimesLocal[localIndex] = newTimeLocal;
          // تحديث القائمة الأصلية بتوقيت UTC
          _medicineTimesUtc[localIndex] = newTimeUtcString;
        }

          // تحديث nowTime في Firestore
          List<dynamic> originalNowTimes = List<dynamic>.from(medicineDoc['nowTime'] ?? []);
          if (localIndex < originalNowTimes.length) {
            originalNowTimes[localIndex] = newTimeLocal; // استخدام الوقت المحلي هنا
            medicineDoc.reference.update({'nowTime': originalNowTimes}).then((_) {
              print("nowTime updated successfully in Firestore");
            }).catchError((error) {
              print("Error updating nowTime in Firestore: $error");
            });
          }
        
      });
    }
  }
Future<void> _deleteTime(BuildContext context, int indexToDelete, StateSetter dialogSetState) async {
    dialogSetState(() {
      if (indexToDelete >= 0 && indexToDelete < _medicineTimesLocal.length) {
        // حذف الوقت المحلي
        final deletedLocalTime = _medicineTimesLocal.removeAt(indexToDelete);
        // حذف الوقت الـ UTC المقابل
        if (indexToDelete < _medicineTimesUtc.length) {
          _medicineTimesUtc.removeAt(indexToDelete);
        }

        // حذف الوقت الحالي (بدون تحويل UTC) المقابل من Firestore
        List<dynamic> originalNowTimes = List<dynamic>.from(medicineDoc['nowTime'] ?? []);
        if (indexToDelete < originalNowTimes.length) {
          originalNowTimes.removeAt(indexToDelete);
          medicineDoc.reference.update({'nowTime': originalNowTimes}).then((_) {
            print("nowTime deleted successfully in Firestore");
          }).catchError((error) {
            print("Error deleting nowTime in Firestore: $error");
          });
        }

        // تحديث MedicineTime في Firestore
        medicineDoc.reference.update({'MedicineTime': _medicineTimesUtc}).then((_) {
          print("MedicineTime updated after deletion in Firestore");
        }).catchError((error) {
          print("Error updating MedicineTime after deletion in Firestore: $error");
        });
      } 
    });
  }

  Future<void> _addTime(BuildContext context, StateSetter dialogSetState) async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      dialogSetState(() {
        final now = DateTime.now();
        final dateTime = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
        final newTimeUtcString = '${dateTime.toUtc().hour.toString().padLeft(2, '0')}:${dateTime.toUtc().minute.toString().padLeft(2, '0')}';
        final newTimeLocal = DateFormat('HH:mm').format(dateTime.toLocal());
        _medicineTimesLocal.add(newTimeLocal);
        _medicineTimesUtc.add(newTimeUtcString);

        // إضافة الوقت الحالي (بدون تحويل UTC) إلى قائمة nowTime
        List<dynamic> originalNowTimes = List<dynamic>.from(medicineDoc['nowTime'] ?? []);
        originalNowTimes.add('${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
        medicineDoc.reference.update({'nowTime': originalNowTimes}).then((_) {
          print("nowTime added successfully in Firestore");
        }).catchError((error) {
          print("Error adding nowTime in Firestore: $error");
        });
      });
    }
  }
  

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Edit Medicine"),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: InputDecoration(labelText: "Medicine Name")),
                  TextField(controller: dosageController, decoration: InputDecoration(labelText: "Dosage")),
                  TextField(controller: conditionController, decoration: InputDecoration(labelText: "Medication Instructions")),
                  TextField(controller: pillsPerDoseController, decoration: InputDecoration(labelText: "Number of Pills Per Dose")),
                  SizedBox(height: 10),
                  ListTile(
                    title: Text(DateFormat.yMMMd().format(_startDate.toLocal())),
                    trailing: Icon(Icons.calendar_today),
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate.toLocal(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _startDate = picked.toUtc());
                      }
                    },
                  ),
                  ListTile(
                    title: Text(DateFormat.yMMMd().format(_endDate.toLocal())),
                    trailing: Icon(Icons.calendar_today),
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _endDate.toLocal(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _endDate = picked.toUtc());
                      }
                    },
                  ),
                 Text("Medicine Times (Local)"),
                  ..._medicineTimesLocal.asMap().entries.map((entry) {
                    int index = entry.key;
                    String time = entry.value;
                    return ListTile(
                      title: Text(time),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => _editTime(context, time, setState),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => _deleteTime(context, index, setState),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  ElevatedButton(
                    onPressed: () => _addTime(context, setState),
                    child: Text("Add Time"),
                  ),
                 
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await _firestore
                  .collection('ActivePatient')
                  .doc(widget.patientId)
                  .collection('PatientMedicine')
                  .doc(medicineDoc.id)
                  .update({
                "MedicineName": nameController.text,
                "MedicineDosage": dosageController.text,
                "Medication Instructions": conditionController.text,
                "NumberOfPillsPerDose": pillsPerDoseController.text,
                "StartDate": _startDate,
                "EndDate": _endDate,
                "MedicineTime": _medicineTimesUtc, // حفظ قائمة UTC المعدلة
              }).then((_) {
                print("Medicine details updated successfully in Firestore");
                Navigator.pop(context);
              }).catchError((error) {
                print("Error updating medicine details in Firestore: $error");
              });
            },
            child: Text("Update"),
          ),
        ],
      );
    },
  );
}


  // // تم تعديل هذه الدالة لإضافة جدول الدواء فقط
  // Future<void> scheduleMedicineReminders(String patientId, Map<String, dynamic> medicineData) async {
  //   // لا نقوم الآن بإرسال تذكيرات فورية من هنا
  //   print("Medicine scheduled for patient: $patientId, Medicine: ${medicineData['MedicineName']}");
  // }


/// حذف دواء
void deleteMedicine(String medicineId) {
showDialog(
context: context,
builder: (context) {
return AlertDialog(
title: Text("Delete Medicine"),
content: Text("Are you sure you want to delete this medicine?"),
actions: [
TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
ElevatedButton(
onPressed: () async {
await _firestore
    .collection('ActivePatient')
    .doc(widget.patientId)
    .collection('PatientMedicine')
    .doc(medicineId)
    .delete();
Navigator.pop(context);
},
child: Text("Delete"),
),
],
);
},
);
}

  @override
  Widget build(BuildContext context) {
    DateTime firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    DateTime lastDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    return Scaffold(
      appBar: AppBar(title: Text("Patient Profile")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SingleChildScrollView( // سكرول داون واحد للصفحة الرئيسية
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(widget.patientName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text("Phone: ${widget.patientPhone}", style: TextStyle(fontSize: 16)),
                  ],
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: showAddMedicineDialog,
                  child: Text("Add Medicine"),
                ),
                SizedBox(height: 20),
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('ActivePatient').doc(widget.patientId).collection('PatientMedicine').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                    var medicines = snapshot.data!.docs;
                    return medicines.isEmpty
                        ? Center(child: Text("No medicines added yet."))
                        : SingleChildScrollView( // سكرول داون أفقي لجدول الأدوية
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: MaterialStateColor.resolveWith((states) => Colors.grey[200]!),
                              dataRowColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
                                if (states.contains(MaterialState.selected)) return Colors.grey[300];
                                return null;
                              }),
                              dividerThickness: 1,
                              columns: [
                                DataColumn(label: Text("Image")),
                                DataColumn(label: Text("Medicine")),
                                DataColumn(label: Text("Dosage")),
                                DataColumn(label: Text("Instructions")),
                                DataColumn(label: Text("Times")),
                                DataColumn(label: Text("Actions")),
                              ],
                              rows: medicines.map((doc) {
                                var medicine = doc.data() as Map<String, dynamic>;
                                return DataRow(cells: [
                                  DataCell(medicine["MedicineImageUrl"] != null
                                      ? Image.network(medicine["MedicineImageUrl"], width: 50, height: 50)
                                      : SizedBox()),
                                  DataCell(Text(medicine["MedicineName"] ?? "")),
                                  DataCell(Text(medicine["MedicineDosage"] ?? "")),
                                  DataCell(Text(medicine["Medication Instructions"] ?? "")),
                                  DataCell(
                                    Text(
                                      (medicine["MedicineTime"] as List<dynamic>)
                                              .map((utcTimeString) {
                                            final parts = (utcTimeString as String).split(':');
                                            final utcTime = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day, int.parse(parts[0]), int.parse(parts[1]));
                                            final localTime = utcTime.toLocal();
                                            return DateFormat('HH:mm').format(localTime);
                                          })
                                              .join(", ") ??
                                          "",
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () => showEditMedicineDialog(doc),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => deleteMedicine(doc.id),
                                        ),
                                      ],
                                    ),
                                  ),
                                ]);
                              }).toList(),
                            ),
                          );
                  },
                ),
               

              ]
            ),
      ),
        ),
      ),
    );
  }
}