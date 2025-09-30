import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/logic/meeting/meet_management.dart';
import 'package:kkpchatapp/presentation/admin/screens/meetings/schedule_meet.dart';
import 'package:kkpchatapp/presentation/admin/widgets/meet_tile.dart';
import 'package:kkpchatapp/presentation/common_widgets/shimmer_list.dart';
import 'package:provider/provider.dart';

class MeetingsListScreen extends StatelessWidget {
  const MeetingsListScreen({super.key});

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
                      return MeetingTile(meeting: meeting);
                    },
                  ),
                ),
      floatingActionButton: SizedBox(
        height: Utils().height(context) * 0.09,
        width: Utils().width(context) * 0.24,
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ScheduleMeetingScreen(),
              ),
            );
          },
          backgroundColor: AppColors.bluePrimary,
          child: Text(
            "Schedule ",
            style: AppTextStyles.white8_600.copyWith(fontSize: 13),
          ),
        ),
      ),
    );
  }
}
