import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/core/utils/utils.dart';
import 'package:kkpchatapp/presentation/common_widgets/custom_search_field.dart';

class ArchiveSettingsPage extends StatefulWidget {
  const ArchiveSettingsPage({super.key});

  @override
  State<ArchiveSettingsPage> createState() => _ArchiveSettingsPageState();
}

class _ArchiveSettingsPageState extends State<ArchiveSettingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  // Calendar controller
  late Map<DateTime, List<dynamic>> _events;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _events = {}; // Initialize events
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    // Return a list of dummy events for the day
    return _events[day] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        title: Text(
          'Archive',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: Size(double.infinity, 50),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: Utils().width(context) * 0.6,
              child: TabBar(
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.label,
                indicatorColor: AppColors.grey525252,
                indicatorWeight: 2,
                controller: _tabController,
                tabs: [
                  Tab(
                    icon: Image.asset(
                      'assets/icons/archive_icon.png',
                      height: 30,
                    ),
                  ),
                  Tab(
                    icon: Image.asset(
                      'assets/icons/calendar_icon.png',
                      height: 30,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Column(
            children: [
              Container(
                width: Utils().width(context),
                color: AppColors.background,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: CustomSearchBar(
                  width: Utils().width(context),
                  enable: true,
                  controller: _searchController,
                  hintText: 'Search...',
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Slidable(
                      startActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        extentRatio: 0.3, // 30% width for archive action
                        children: [
                          SlidableAction(
                            onPressed: (context) =>
                                _archiveItem(index, context),
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            icon: Icons.archive,
                            label: 'Archive',
                          ),
                        ],
                      ),
                      endActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        extentRatio: 0.3, // 30% width for delete action
                        children: [
                          SlidableAction(
                            onPressed: (context) => _removeItem(index, context),
                            backgroundColor: AppColors.redF11515,
                            foregroundColor: Colors.white,
                            icon: Icons.delete,
                            label: 'Delete',
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: AssetImage(item['imageUrl']!),
                        ),
                        title: Text(item['name']!),
                        subtitle: Text(item['message']!),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          // Calendar
          Center(
            child: SizedBox(
              width: Utils().width(context) * 0.9,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: TableCalendar(
                      firstDay: DateTime.utc(2023, 1, 1),
                      lastDay: DateTime.utc(2025, 12, 31),
                      focusedDay: _focusedDay,
                      calendarFormat: _calendarFormat,
                      selectedDayPredicate: (day) {
                        return isSameDay(_selectedDay, day);
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      onFormatChanged: (format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                      },
                      eventLoader: _getEventsForDay,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  final List<Map<String, String>> items = [
    {
      'name': 'Michel John',
      'message': "I'll check for a moment...",
      'imageUrl': 'assets/images/profile_avataar.png'
    },
    {
      'name': 'Jenny D.Suza',
      'message': "I'll check for a moment...",
      'imageUrl': 'assets/images/profile_avataar.png'
    },
    {
      'name': 'Ramesh Jain',
      'message': "I'll check for a moment...",
      'imageUrl': 'assets/images/profile_avataar.png'
    },
    {
      'name': 'Kevin Den',
      'message': "I'll check for a moment...",
      'imageUrl': 'assets/images/profile_avataar.png'
    },
  ];

  void _removeItem(int index, context) {
    setState(() {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(items[index]['name'].toString())));
      items.removeAt(index);
    });
  }

  void _archiveItem(int index, context) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(items[index]['name'].toString())));
  }
}
