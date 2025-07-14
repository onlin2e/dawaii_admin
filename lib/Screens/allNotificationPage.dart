import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Allnotificationpage extends StatefulWidget {
  const Allnotificationpage({Key? key}) : super(key: key);

  @override
  _AllnotificationpageState createState() => _AllnotificationpageState();

}

class _AllnotificationpageState extends State<Allnotificationpage> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;
  String _searchQueryWeekly = '';
  String _searchQueryOther = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Function to delete a single notification
  Future<void> _deleteNotification(String docId) async {
    try {
      await _firestore.collection('SentNotifications').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification deleted successfully')),
      );
    } catch (e) {
      print("Error deleting notification: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error deleting notification')),
      );
    }
  }

  // Function to delete all notifications for a given category
  Future<void> _deleteAllNotifications(List<String> categories) async {
    // Show confirmation dialog
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete all notifications in this section? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete All'),
            ),
          ],
        );
      },
    );


    if (confirm == true) {
      try {
        final collectionRef = _firestore.collection('SentNotifications');
        for (String category in categories) {
          final querySnapshot = await collectionRef.where('category', isEqualTo: category).get();
          for (QueryDocumentSnapshot doc in querySnapshot.docs) {
            await doc.reference.delete();
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications deleted successfully')),
        );

      } catch (e) {
        print("Error deleting all notifications: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error deleting all notifications')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Notifications'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Weekly Performance'),
            Tab(text: 'Other'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Weekly Performance Notifications Tab
          _buildNotificationTab(
            categories: ['poor', 'excellent', 'moderate'],
            searchQuery: _searchQueryWeekly,
            onSearchChanged: (query) {
              setState(() {
                _searchQueryWeekly = query;
              });
            },
            onDeleteAll: () => _deleteAllNotifications(['poor', 'excellent', 'other']),
          ),
          // Other Notifications Tab
          _buildNotificationTab(
            categories: ['other'],
            searchQuery: _searchQueryOther,
            onSearchChanged: (query) {
              setState(() {
                _searchQueryOther = query;

              });
            },
            onDeleteAll: () => _deleteAllNotifications(['other']),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTab({
    required List<String> categories,
    required String searchQuery,
    required ValueChanged<String> onSearchChanged,
    required VoidCallback onDeleteAll,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Search Bar
          TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              labelText: 'Search notifications',
              hintText: 'Search by category or message',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Delete All Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: onDeleteAll,
              icon: const Icon(Icons.delete_forever),
              label: const Text('Delete All'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder(
              stream: _firestore
                  .collection('SentNotifications')
                  .where('category', whereIn: categories)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error fetching data'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No notifications to display.'));
                }

                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final category = doc['category']?.toString().toLowerCase() ?? '';
                  final message = doc['message']?.toString().toLowerCase() ?? '';
                  final patientId = doc['patientId']?.toString().toLowerCase() ?? '';
                  final query = searchQuery.toLowerCase();
                  return category.contains(query) ||
                      message.contains(query) ||
                      patientId.contains(query);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text('No matching notifications found.'));
                }

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var notification = filteredDocs[index];
                    var sentAt = (notification['sentAt'] as Timestamp).toDate();
                    var formattedDate = DateFormat('dd MMMM yyyy, hh:mm a', 'en_US').format(sentAt);

                    return Card(
                      elevation: 5,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Category: ${notification['category']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Message: ${notification['message']}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Patient ID: ${notification['patientId']}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Sent At: $formattedDate',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteNotification(notification.id),
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
    );
  }
}