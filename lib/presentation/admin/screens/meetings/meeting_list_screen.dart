import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/logic/meeting/meet_management.dart';
import 'package:kkpchatapp/presentation/admin/screens/meetings/schedule_meet.dart';
import 'package:kkpchatapp/presentation/admin/widgets/meet_tile.dart';
import 'package:kkpchatapp/presentation/common_widgets/shimmer_list.dart';
import 'package:provider/provider.dart';

class MeetingsListScreen extends StatelessWidget {
  final String email;
  const MeetingsListScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    final meetingManagement = Provider.of<MeetingManagement>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Upcoming Meetings",
          style: AppTextStyles.black16_700,
        ),
      ),
      body: meetingManagement.isLoading
          ? const ShimmerList(
              itemCount: 10,
            )
          : meetingManagement.error != null
              ? Center(child: Text(meetingManagement.error!))
              : RefreshIndicator(
                  onRefresh: () => meetingManagement.fetchAllMeetings(),
                  child: ListView.builder(
                    itemCount: meetingManagement.meetings.length,
                    itemBuilder: (context, index) {
                      final meeting = meetingManagement.meetings[index];
                      return MeetingTile(
                        meeting: meeting,
                        showButtons: meeting.scheduledPerson.email == email,
                      );
                    },
                  ),
                ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          color: Colors.white, // Background color
          borderRadius: BorderRadius.circular(12),
          // optional rounded corners
        ),
        child: GestureDetector(
          // height: Utils().height(context) * 0.09,
          // width: Utils().width(context) * 0.24,
          // child: FloatingActionButton(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ScheduleMeetingScreen(),
              ),
            );
          },

          child: Image.asset(
            'assets/icons/schedule.png',
            fit: BoxFit.contain,
            height: Utils().height(context) * 0.09,
            // width: Utils().width(context) * 0.24,
          ),
          // backgroundColor: AppColors.bluePrimary,
          // child: Text(
          //   "Schedule ",
          //   style: AppTextStyles.white8_600.copyWith(fontSize: 13),
          // ),
          // ),
        ),
      ),
    );
  }
}
