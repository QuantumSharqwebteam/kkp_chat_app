import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kkpchatapp/logic/meeting/meet_management.dart';
import 'package:kkpchatapp/presentation/admin/screens/meetings/meeting_list_screen.dart';
import 'package:kkpchatapp/presentation/common_widgets/shimmer_list.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

class LoadingMeetingManagement extends Mock implements MeetingManagement {
  @override
  bool get isLoading => true;
}

const errorMsg = 'Test Error Message';

class ErrorMeetingManagement extends Mock implements MeetingManagement {
  @override
  bool get isLoading => false;
  @override
  String? get error => errorMsg;
}

void main() {
  final loading = LoadingMeetingManagement();
  final error = ErrorMeetingManagement();

  group('Meeting List Screen Tests', () {
    testWidgets(
        'Given Meeting management screen '
        'When Provider is loading '
        'Then shimmer is expected', (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: MultiProvider(
        providers: [
          ChangeNotifierProvider<MeetingManagement>(create: (_) => loading),
        ],
        child: MeetingsListScreen(
          email: 'hemanthba191@gmail.com',
        ),
      )));
      expect(find.byType(ShimmerList), findsOneWidget);
    });
    testWidgets(
        'Given Meeting management screen  '
        'When Provider has error '
        'Then error msg expected', (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: MultiProvider(
        providers: [
          ChangeNotifierProvider<MeetingManagement>(create: (_) => error),
        ],
        child: MeetingsListScreen(
          email: 'hemanthba191@gmail.com',
        ),
      )));
      expect(find.text(errorMsg), findsOneWidget);
    });
  });
}
