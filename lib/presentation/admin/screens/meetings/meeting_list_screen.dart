import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/logic/meeting/meet_management.dart';
import 'package:kkpchatapp/presentation/admin/screens/meetings/schedule_meet.dart';
import 'package:kkpchatapp/presentation/admin/widgets/meet_tile.dart';
import 'package:kkpchatapp/presentation/common_widgets/shimmer_list.dart';
import 'package:provider/provider.dart';

import '../../../../data/local_storage/local_db_helper.dart';

class MeetingsListScreen extends StatefulWidget {
  const MeetingsListScreen({
    super.key,
  });

  @override
  State<MeetingsListScreen> createState() => _MeetingsListScreenState();
}

class _MeetingsListScreenState extends State<MeetingsListScreen> {
  bool showButtons = false;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = await LocalDbHelper.getUserType();
    late String rolename;
    if (role == "1") {
      rolename = "admin";
    } else if (role == "2") {
      rolename = "agent";
    } else if (role == "3") {
      rolename = "agent Head";
    }
    if (rolename == "admin" || rolename == "agent Head") {
      setState(() {
        showButtons = true;
      });
    }
  }

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
                        showButtons: showButtons,
                      );
                    },
                  ),
                ),
      floatingActionButton: showButtons
          ? SizedBox(
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
            )
          : null,
    );
  }
}
