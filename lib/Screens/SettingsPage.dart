import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String adminUsername = "";
  String adminPassword = "";
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    QuerySnapshot snapshot = await _firestore.collection("AdminAuth").limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      var doc = snapshot.docs.first;
      setState(() {
        adminUsername = doc["username"];
        adminPassword = doc["password"];
      });
    }
  }

  Future<void> _updateAdminData(String field, String newValue) async {
    QuerySnapshot snapshot = await _firestore.collection("AdminAuth").limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      var doc = snapshot.docs.first;
      await _firestore.collection("AdminAuth").doc(doc.id).update({
        field: newValue,
      });

      setState(() {
        if (field == "username") {
          adminUsername = newValue;
        } else if (field == "password") {
          adminPassword = newValue;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$field updated successfully!"), backgroundColor: Colors.green),
      );
    }
  }

  void _updateUsername() {
    TextEditingController _controller = TextEditingController(text: adminUsername);
    _showUpdateDialog("Update Admin Username", _controller, () {
      _updateAdminData("username", _controller.text);
    });
  }

  void _updatePassword() {
    TextEditingController _controller = TextEditingController(text: adminPassword);
    _showUpdateDialog("Update Admin Password", _controller, () {
      _updateAdminData("password", _controller.text);
    });
  }

  void _showUpdateDialog(String title, TextEditingController controller, VoidCallback onUpdate) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(border: OutlineInputBorder()),
          obscureText: title.contains("Password"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onUpdate();
                Navigator.pop(context);
              }
            },
            child: Text("Update"),
          ),
        ],
      ),
    );
  }

  // --- قسم إدارة الصيدلانيين ---

  Future<void> _addPharmacist(String username, String password) async {
    if (username.trim().isNotEmpty && password.trim().isNotEmpty) {
      try {
        await _firestore.collection("emp").add({
          "userName": username,
          "password": password,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Pharmacist added successfully!"), backgroundColor: Colors.green),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error adding pharmacist: $e"), backgroundColor: Colors.red),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Username and password cannot be empty."), backgroundColor: Colors.orange),
      );
    }
  }

  void _showAddPharmacistDialog() {
    TextEditingController _usernameController = TextEditingController();
    TextEditingController _passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add New Pharmacist"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: "Username", border: OutlineInputBorder()),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: "Password", border: OutlineInputBorder()),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              _addPharmacist(_usernameController.text, _passwordController.text);
              Navigator.pop(context);
            },
            child: Text("Add"),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePharmacistCredentials(String docId, String newUsername, String newPassword) async {
    try {
      await _firestore.collection("emp").doc(docId).update({
        "userName": newUsername,
        "password": newPassword,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Pharmacist credentials updated successfully!"), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating pharmacist: $e"), backgroundColor: Colors.red),
      );
    }
  }

  void _showEditPharmacistDialog(Map<String, dynamic> pharmacistData, String docId) {
    TextEditingController _usernameController = TextEditingController(text: pharmacistData["userName"]);
    TextEditingController _passwordController = TextEditingController(text: pharmacistData["password"]);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Pharmacist"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: "Username", border: OutlineInputBorder()),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: "Password", border: OutlineInputBorder()),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              _updatePharmacistCredentials(docId, _usernameController.text, _passwordController.text);
              Navigator.pop(context);
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePharmacist(String docId) async {
    try {
      await _firestore.collection("emp").doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Pharmacist deleted successfully!"), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting pharmacist: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildPharmacistListItem(Map<String, dynamic> data, String docId) {
    return Container(
      padding: EdgeInsets.all(15),
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueGrey),
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: [Colors.blueGrey[50]!, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Username: ${data['userName']}", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("Password: ${data['password']}", style: TextStyle(color: Colors.grey[600])),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.edit, color: Colors.blue),
                onPressed: () => _showEditPharmacistDialog(data, docId),
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deletePharmacist(docId),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Admin Account", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey[800])),
              SizedBox(height: 15),
              _buildSettingItem("Admin Username: $adminUsername", _updateUsername),
              SizedBox(height: 10),
              _buildSettingItem("Admin Password: $adminPassword", _updatePassword),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Pharmacist Management", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey[800])),
                  ElevatedButton.icon(
                    onPressed: _showAddPharmacistDialog,
                    icon: Icon(Icons.add),
                    label: Text("Add Pharmacist"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection("emp").snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text("Something went wrong");
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }

                  if (snapshot.data!.docs.isEmpty) {
                    return Text("No pharmacists added yet.");
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var doc = snapshot.data!.docs[index];
                      var data = doc.data() as Map<String, dynamic>;
                      return _buildPharmacistListItem(data, doc.id);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem(String text, VoidCallback onPressed) {
    return Container(
      padding: EdgeInsets.all(15),
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!),
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          colors: [Colors.grey[200]!, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text, style: TextStyle(fontSize: 16)),
          IconButton(
            icon: Icon(Icons.edit, color: Colors.blue),
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}