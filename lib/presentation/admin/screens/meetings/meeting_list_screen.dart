import 'package:flutter/material.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';
import 'package:kkpchatapp/l10n/generated/app_localizations.dart';
import 'package:kkpchatapp/logic/meeting/meet_management.dart';
import 'package:kkpchatapp/presentation/admin/screens/meetings/schedule_meet.dart';
import 'package:kkpchatapp/presentation/admin/widgets/meet_tile.dart';
import 'package:kkpchatapp/presentation/common_widgets/shimmer_list.dart';
import 'package:provider/provider.dart';

class MeetingsListScreen extends StatefulWidget {
  final String email;
  const MeetingsListScreen({super.key, required this.email});

  @override
  State<MeetingsListScreen> createState() => _MeetingsListScreenState();
}

class _MeetingsListScreenState extends State<MeetingsListScreen> {
  String? _userType;
  String? _roleName;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserRole();
  }

  Future<void> _loadCurrentUserRole() async {
    final loadedUserType = await LocalDbHelper.getUserType();
    final loadedRoleName = LocalDbHelper.getProfile()?.role;

    if (!mounted) return;
    setState(() {
      _userType = loadedUserType;
      _roleName = loadedRoleName;
    });
  }

  String? validateMeetingLink(String? value) {
    return MeetingManagement.validateMeetingUrl(value);
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final meetingManagement = Provider.of<MeetingManagement>(context);
    final upcomingMeetings = meetingManagement.getTodaysUpcomingMeetings();
    final upcomingIds = upcomingMeetings.map((meeting) => meeting.id).toSet();
    final remainingMeetings =
        meetingManagement.meetings.where((meeting) => !upcomingIds.contains(meeting.id)).toList()
          ..sort((a, b) {
            final aTime = DateTime.tryParse(a.startTime) ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = DateTime.tryParse(b.startTime) ?? DateTime.fromMillisecondsSinceEpoch(0);
            return aTime.compareTo(bTime);
          });
    final sortedMeetings = [...upcomingMeetings, ...remainingMeetings];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_outlined,
            )),
        title: Text(
          locale.upcomingMeetings,
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
                    itemCount: sortedMeetings.length,
                    itemBuilder: (context, index) {
                      final meeting = sortedMeetings[index];
                      final canManageMeeting = meetingManagement.canEditMeeting(
                        meeting: meeting,
                        currentUserEmail: widget.email,
                        userType: _userType,
                        roleName: _roleName,
                      );

                      return MeetingTile(
                        meeting: meeting,
                        showButtons: canManageMeeting,
                      );
                    },
                  ),
                ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
        child: FloatingActionButton.extended(
          backgroundColor: AppColors.bluePrimary,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ScheduleMeetingScreen(),
              ),
            );
          },
          icon: const Icon(
            Icons.add,
            color: Colors.white,
          ),
          label: Text(
            'Schedule',
            style: AppTextStyles.black12_400.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
