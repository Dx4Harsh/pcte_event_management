import 'dart:async';
import 'dart:developer';
import 'dart:math';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:pcte_event_management/Api_Calls/Registration_api_calls.dart';
import 'package:pcte_event_management/Api_Calls/event_api_calls.dart';
import 'package:pcte_event_management/Providers/pass_provider.dart';
import 'package:pcte_event_management/ui/EventDetails.dart';
import 'package:pcte_event_management/ui/create_result.dart';
import 'package:pcte_event_management/ui/event_result.dart';
import 'package:pcte_event_management/ui/student_reg.dart';
import 'package:pcte_event_management/ui/update_result.dart';
import 'package:pcte_event_management/widgets/drawer_builder.dart';
import 'package:provider/provider.dart';
import '../LocalStorage/Secure_Store.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> filteredEvents = [];
  List<Map<String, dynamic>> verticalEvents = [];
  bool isEmpty = false;
  int _currentCarouselIndex = 0;
  final _searchController = TextEditingController();
  final SecureStorage secureStorage = SecureStorage();
  final PageController _pageController = PageController(viewportFraction: 0.9);
  Timer? _timer;

  // Map of event types to icons
  final Map<String, IconData> eventTypeIcons = {'default': Icons.event};

  // Featured event data for the carousel

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> getAllEvents() async {
    final eventApi = EventApiCalls();
    List<Map<String, dynamic>> allEvents = await eventApi.getAllEvents();
    return allEvents;
  }

  Future<void> _fetchEvents() async {
    verticalEvents = await getAllEvents();
    setState(() {
      filteredEvents = List.from(verticalEvents);
      isLoading = false;
      isEmpty = verticalEvents.isEmpty;
    });
  }

  void _filterEvents(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredEvents = List.from(verticalEvents);
      });
      return;
    }

    setState(() {
      filteredEvents = verticalEvents.where((event) {
        final name = event['name'].toString().toLowerCase();
        return name.contains(query.toLowerCase());
      }).toList();
    });
  }

  IconData getEventIcon(String eventType) {
    return eventTypeIcons[eventType.toLowerCase()] ??
        eventTypeIcons['default']!;
  }

  Color getEventColor(String eventType) {
    final Map<String, Color> eventColors = {'default': const Color(0xFF9E2A2F)};

    return eventColors[eventType.toLowerCase()] ?? eventColors['default']!;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PassProvider>(
      builder: (context, searchProvider, child) {
        return PopScope(
          canPop: !searchProvider.isSearching,
          onPopInvokedWithResult: (didPop, obj) {
            if (searchProvider.isSearching && !didPop) {
              searchProvider.searchState();
            }
          },
          child: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                scrolledUnderElevation: 0,
                backgroundColor: const Color(0xFF9E2A2F),
                elevation: 0,
                centerTitle: false,
                title: Row(
                  children: [
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: searchProvider.isSearching
                            ? MediaQuery.of(context).size.width * 0.6
                            : 180,
                        height: 40,
                        alignment: Alignment.centerLeft,
                        child: searchProvider.isSearching
                            ? TextField(
                                controller: _searchController,
                                onChanged: (query) => _filterEvents(query),
                                autofocus: true,
                                decoration: const InputDecoration(
                                  hintText: "Search events...",
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(color: Colors.white60),
                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                    color: Colors.white70,
                                  ),
                                ),
                                style: const TextStyle(color: Colors.white),
                                cursorColor: Colors.white,
                              )
                            : const Text(
                                "Koshish Events",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                leading: Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu_rounded, color: Colors.white),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      searchProvider.isSearching
                          ? Icons.close_rounded
                          : Icons.search_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      searchProvider.searchState();
                      if (!searchProvider.isSearching)
                        _searchController.clear();
                      setState(() {
                        filteredEvents = List.from(verticalEvents);
                      });
                    },
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.1,
                  )
                ],
              ),
              drawer: const CustomDrawer(),
              body: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF9E2A2F),
                      ),
                    )
                  : isEmpty
                      ? EmptyStateWidget(onRefresh: () {
                          setState(() {
                            isLoading = true;
                          });
                          _fetchEvents();
                        })
                      : FutureBuilder(
                          future: secureStorage.getData('user_type'),
                          builder: (context, snapshot) {
                            final userType = snapshot.data;
                            return RefreshIndicator(
                              color: const Color(0xFF9E2A2F),
                              onRefresh: () async {
                                setState(() {
                                  isLoading = true;
                                });
                                await _fetchEvents();
                              },
                              child: CustomScrollView(
                                physics: const BouncingScrollPhysics(
                                  parent: AlwaysScrollableScrollPhysics(),
                                ),
                                slivers: [
                                  // Events Section Header
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            "All Events",
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (userType == 'Admin')
                                            TextButton.icon(
                                              onPressed: () {
                                                final registrationApi =
                                                    RegistrationApiCalls();
                                                registrationApi
                                                    .getAllRegistrations();
                                              },
                                              icon: const Icon(Icons
                                                  .admin_panel_settings_rounded),
                                              label: const Text('Admin'),
                                              style: TextButton.styleFrom(
                                                foregroundColor:
                                                    const Color(0xFF9E2A2F),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Events Grid List
                                  SliverPadding(
                                    padding: const EdgeInsets.all(16),
                                    sliver: SliverGrid(
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        childAspectRatio: 0.75,
                                        crossAxisSpacing: 16,
                                        mainAxisSpacing: 16,
                                      ),
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) {
                                          final event = filteredEvents[index];
                                          return EventCard(
                                            eventName: event['name'],
                                            eventType: event['type'],
                                            eventId: event['_id'],
                                            minStudents: event['minStudents'],
                                            maxStudents: event['maxStudents'],
                                            userType: userType ?? '',
                                            icon: getEventIcon(event['type']),
                                            color: getEventColor(event['type']),
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      EventDetailsPage(
                                                    points: event['points'],
                                                    rules: event['rules'],
                                                    eventId: event['_id'],
                                                    eventName: event['name'],
                                                    description:
                                                        event['description'],
                                                    maxStudents:
                                                        event['maxStudents'],
                                                    minStudents:
                                                        event['minStudents'],
                                                    location: event['location'],
                                                    convener: event['convenor']
                                                        ['name'],
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                        childCount: filteredEvents.length,
                                      ),
                                    ),
                                  ),
                              
                              
                              
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ),
        );
      },
    );
  }
}




// Empty State Widget
class EmptyStateWidget extends StatelessWidget {
  final VoidCallback onRefresh;

  const EmptyStateWidget({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_busy,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Events Available',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Stay tuned for upcoming events',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9E2A2F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  final String eventName;
  final String eventType;
  final String eventId;
  final String userType;
  final int minStudents;
  final int maxStudents;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const EventCard({
    super.key,
    required this.eventName,
    required this.eventType,
    required this.eventId,
    required this.userType,
    required this.minStudents,
    required this.maxStudents,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Icon Header
                Container(
                  height: 120, // Reduced height slightly
                  width: double.infinity,
                  color: color.withOpacity(0.2),
                  child: Stack(
                    children: [
                      // Patterned background
                      Positioned.fill(
                        child: CustomPaint(
                          painter: CirclePatternPainter(
                              color: color.withOpacity(0.1)),
                        ),
                      ),
                      // Icon
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            icon,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      // Event Type Badge
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            eventType,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // Menu button
                      Positioned(
                        top: 3,
                        right: 4,
                        child: Material(
                          color: Colors.transparent,
                          child: PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert_outlined,
                              color: color,
                            ),
                            itemBuilder: (BuildContext context) =>
                                <PopupMenuEntry<String>>[
                              PopupMenuItem<String>(
                                value: 'Results',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => EventResultScreen(
                                            eventId: eventId)),
                                  );
                                },
                                child: Row(
                                  children: [
                                    Icon(Icons.emoji_events, size: 18),
                                    SizedBox(width: 8),
                                    Text('Results'),
                                  ],
                                ),
                              ),
                              if (userType == 'Convenor' || userType == 'Admin')
                                PopupMenuItem<String>(
                                  value: 'Update Result',
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                UpdateResult(id: eventId)));
                                  },
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.change_history_outlined,
                                          size: 18),
                                      SizedBox(width: 8),
                                      Padding(
                                        padding: EdgeInsets.only(top: 2),
                                        child: Text('Update Result'),
                                      ),
                                    ],
                                  ),
                                ),
                              if (userType == 'Convenor' || userType == 'Admin')
                                PopupMenuItem<String>(
                                  value: 'Add Result',
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                CreateResult(id: eventId)));
                                  },
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.add_chart, size: 18),
                                      SizedBox(width: 8),
                                      Padding(
                                        padding: EdgeInsets.only(top: 2),
                                        child: Text('Add Result'),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                  
                  
                  
                    ],
                  ),
                ),

                // Event Details - Flexible content section
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Event name with limited lines - removed fixed height
                        Flexible(
                          child: Text(
                            eventName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Members count
                        Row(
                          children: [
                            const Icon(
                              Icons.people,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$minStudents-$maxStudents members',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),

                        // Removed Spacer and any other non-essential elements
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Circle Pattern Painter for Event Card Background
class CirclePatternPainter extends CustomPainter {
  final Color color;

  CirclePatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.8),
      size.width * 0.15,
      paint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.8),
      size.width * 0.12,
      paint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.1),
      size.width * 0.08,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
