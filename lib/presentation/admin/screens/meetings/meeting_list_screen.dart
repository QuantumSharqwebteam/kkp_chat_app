import 'package:flutter/material.dart';
import 'package:kkpchatapp/logic/meeting/meet_management.dart';
import 'package:kkpchatapp/presentation/admin/screens/meetings/schedule_meet.dart';
import 'package:kkpchatapp/presentation/admin/widgets/meet_tile.dart';
import 'package:provider/provider.dart';

class MeetingsListScreen extends StatefulWidget {
  const MeetingsListScreen({super.key});

  @override
  State<MeetingsListScreen> createState() => _MeetingsListScreenState();
}

class _MeetingsListScreenState extends State<MeetingsListScreen> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final meetingManagement = Provider.of<MeetingManagement>(context, listen: false);
      meetingManagement.fetchAllMeetings();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final meetingManagement = Provider.of<MeetingManagement>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Upcoming Meetings"),
        backgroundColor: Colors.blue,
      ),
      body: meetingManagement.isLoading
          ? const Center(child: CircularProgressIndicator())
          : meetingManagement.error != null
              ? Center(child: Text(meetingManagement.error!))
              : RefreshIndicator(
                  onRefresh: () => meetingManagement.fetchAllMeetings(),
                  child: ListView.builder(
                    itemCount: meetingManagement.meetings.length,
                    itemBuilder: (context, index) {
                      final meeting = meetingManagement.meetings[index];
                      return MeetingTile(meeting: meeting);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ScheduleMeetingScreen(),
            ),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
