import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:page/pages/diary_form_page.dart';
import 'package:page/theme/theme_data.dart';
import 'package:page/theme/theme_provider.dart';

class MoodTrendPage extends StatefulWidget {
  final List<Map<String, dynamic>> entries;

  const MoodTrendPage({super.key, required this.entries});

  @override
  State<MoodTrendPage> createState() => _MoodTrendPageState();
}

class _MoodTrendPageState extends State<MoodTrendPage> {
  List<Map<String, dynamic>> _entries = [];
  bool _isLoading = false;
  String _dateRange = 'All Time'; // Options: '7 Days', '30 Days', 'All Time'
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _entries = widget.entries;
    _fetchEntries();
  }

  Future<void> _fetchEntries() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('info')
          .select('*')
          .order('created_at', ascending: false);

      var entries = List<Map<String, dynamic>>.from(response);

      if (_dateRange == '7 Days') {
        entries =
            entries.where((entry) {
              try {
                final createdAt = DateTime.parse(entry['created_at']);
                return createdAt.isAfter(
                  DateTime.now().subtract(const Duration(days: 7)),
                );
              } catch (e) {
                debugPrint('Date parse error in entry: $entry, error: $e');
                return false;
              }
            }).toList();
      } else if (_dateRange == '30 Days') {
        entries =
            entries.where((entry) {
              try {
                final createdAt = DateTime.parse(entry['created_at']);
                return createdAt.isAfter(
                  DateTime.now().subtract(const Duration(days: 30)),
                );
              } catch (e) {
                debugPrint('Date parse error in entry: $entry, error: $e');
                return false;
              }
            }).toList();
      }

      setState(() {
        _entries = entries;
        debugPrint('Fetched entries: $_entries');
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.error,
            content: Text('Error loading entries: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  double _getMoodValue(String? mood) {
    switch (mood?.toLowerCase()) {
      case 'happy':
        return 4.0;
      case 'excited':
        return 3.0;
      case 'neutral':
        return 2.0;
      case 'tired':
        return 1.0;
      case 'sad':
        return 0.0;
      default:
        return -1.0; // Ignore invalid moods
    }
  }

  @override
  Widget build(BuildContext context) {
    final moodPoints =
        _entries.isNotEmpty
            ? _entries
                .asMap()
                .entries
                .where((entry) {
                  final mood = entry.value['mood'];
                  return mood != null && _getMoodValue(mood) >= 0;
                })
                .map((entry) {
                  final index = entry.key.toDouble();
                  final moodValue = _getMoodValue(entry.value['mood']);
                  return FlSpot(index, moodValue);
                })
                .toList()
            : <FlSpot>[];

    final moodAnalysis = MoodAnalysis(
      entries: _entries,
      getMoodValue: _getMoodValue,
    );

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Theme(
          data: themeProvider.themeData,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Mood Trends'),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              actions: [
                DropdownButton<String>(
                  value: _dateRange,
                  items:
                      ['7 Days', '30 Days', 'All Time']
                          .map(
                            (range) => DropdownMenuItem(
                              value: range,
                              child: Text(range),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _dateRange = value!;
                      _fetchEntries();
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _fetchEntries,
                  tooltip: 'Refresh Entries',
                ),
              ],
            ),
            body:
                _isLoading
                    ? Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    )
                    : SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: AnimationLimiter(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child:
                              moodPoints.isEmpty
                                  ? AnimationConfiguration.staggeredList(
                                    position: 0,
                                    duration: const Duration(milliseconds: 375),
                                    child: SlideAnimation(
                                      verticalOffset: 50.0,
                                      child: FadeInAnimation(
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.mood_bad,
                                                size: 50,
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.onSurface,
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'No mood entries yet.',
                                                style:
                                                    Theme.of(
                                                      context,
                                                    ).textTheme.titleLarge,
                                              ),
                                              const SizedBox(height: 16),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  await Navigator.of(
                                                    context,
                                                  ).push(
                                                    MaterialPageRoute(
                                                      builder:
                                                          (context) =>
                                                              const DiaryFormPage(),
                                                    ),
                                                  );
                                                  _fetchEntries();
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Theme.of(
                                                        context,
                                                      ).colorScheme.secondary,
                                                  foregroundColor:
                                                      Theme.of(
                                                        context,
                                                      ).colorScheme.onSecondary,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                ),
                                                child: const Text(
                                                  'Add Diary Entry',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  : Column(
                                    children: AnimationConfiguration.toStaggeredList(
                                      duration: const Duration(
                                        milliseconds: 375,
                                      ),
                                      childAnimationBuilder:
                                          (widget) => SlideAnimation(
                                            verticalOffset: 50.0,
                                            child: FadeInAnimation(
                                              child: widget,
                                            ),
                                          ),
                                      children: [
                                        Expanded(
                                          child: SizedBox(
                                            height: 300,
                                            child: LayoutBuilder(
                                              builder: (context, constraints) {
                                                return LineChart(
                                                  LineChartData(
                                                    gridData: FlGridData(
                                                      show: true,
                                                      drawVerticalLine: true,
                                                      horizontalInterval: 1,
                                                      getDrawingHorizontalLine:
                                                          (value) => FlLine(
                                                            color: Theme.of(
                                                                  context,
                                                                )
                                                                .colorScheme
                                                                .onSurface
                                                                .withOpacity(
                                                                  0.2,
                                                                ),
                                                            strokeWidth: 1,
                                                          ),
                                                      getDrawingVerticalLine:
                                                          (value) => FlLine(
                                                            color: Theme.of(
                                                                  context,
                                                                )
                                                                .colorScheme
                                                                .onSurface
                                                                .withOpacity(
                                                                  0.2,
                                                                ),
                                                            strokeWidth: 1,
                                                          ),
                                                    ),
                                                    titlesData: FlTitlesData(
                                                      leftTitles: AxisTitles(
                                                        sideTitles: SideTitles(
                                                          showTitles: true,
                                                          reservedSize: 60,
                                                          getTitlesWidget: (
                                                            value,
                                                            meta,
                                                          ) {
                                                            final textStyle = Theme.of(
                                                                  context,
                                                                )
                                                                .textTheme
                                                                .bodyMedium
                                                                ?.copyWith(
                                                                  color:
                                                                      Theme.of(
                                                                        context,
                                                                      ).colorScheme.onSurface,
                                                                  fontSize: 12,
                                                                );
                                                            switch (value
                                                                .toInt()) {
                                                              case 0:
                                                                return Text(
                                                                  'Sad',
                                                                  style:
                                                                      textStyle,
                                                                );
                                                              case 1:
                                                                return Text(
                                                                  'Tired',
                                                                  style:
                                                                      textStyle,
                                                                );
                                                              case 2:
                                                                return Text(
                                                                  'Neutral',
                                                                  style:
                                                                      textStyle,
                                                                );
                                                              case 3:
                                                                return Text(
                                                                  'Excited',
                                                                  style:
                                                                      textStyle,
                                                                );
                                                              case 4:
                                                                return Text(
                                                                  'Happy',
                                                                  style:
                                                                      textStyle,
                                                                );
                                                              default:
                                                                return const Text(
                                                                  '',
                                                                );
                                                            }
                                                          },
                                                        ),
                                                      ),
                                                      bottomTitles: AxisTitles(
                                                        sideTitles: SideTitles(
                                                          showTitles: true,
                                                          reservedSize: 30,
                                                          getTitlesWidget: (
                                                            value,
                                                            meta,
                                                          ) {
                                                            final index =
                                                                value.toInt();
                                                            if (index >= 0 &&
                                                                index <
                                                                    _entries
                                                                        .length) {
                                                              try {
                                                                final date =
                                                                    DateTime.parse(
                                                                      _entries[index]['created_at'],
                                                                    );
                                                                return Text(
                                                                  DateFormat(
                                                                    'd/M',
                                                                  ).format(
                                                                    date,
                                                                  ),
                                                                  style: Theme.of(
                                                                        context,
                                                                      )
                                                                      .textTheme
                                                                      .bodySmall
                                                                      ?.copyWith(
                                                                        color:
                                                                            Theme.of(
                                                                              context,
                                                                            ).colorScheme.onSurface,
                                                                        fontSize:
                                                                            10,
                                                                      ),
                                                                );
                                                              } catch (e) {
                                                                debugPrint(
                                                                  'Date parse error: $e',
                                                                );
                                                                return const Text(
                                                                  '',
                                                                );
                                                              }
                                                            }
                                                            return const Text(
                                                              '',
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                      topTitles:
                                                          const AxisTitles(
                                                            sideTitles:
                                                                SideTitles(
                                                                  showTitles:
                                                                      false,
                                                                ),
                                                          ),
                                                      rightTitles:
                                                          const AxisTitles(
                                                            sideTitles:
                                                                SideTitles(
                                                                  showTitles:
                                                                      false,
                                                                ),
                                                          ),
                                                    ),
                                                    borderData: FlBorderData(
                                                      show: true,
                                                      border: Border.all(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurface
                                                            .withOpacity(0.5),
                                                      ),
                                                    ),
                                                    lineBarsData: [
                                                      LineChartBarData(
                                                        spots: moodPoints,
                                                        isCurved: true,
                                                        color:
                                                            Theme.of(context)
                                                                .colorScheme
                                                                .secondary,
                                                        barWidth: 4,
                                                        dotData: FlDotData(
                                                          show: true,
                                                          getDotPainter:
                                                              (
                                                                spot,
                                                                percent,
                                                                barData,
                                                                index,
                                                              ) => FlDotCirclePainter(
                                                                radius: 6,
                                                                color:
                                                                    Theme.of(
                                                                          context,
                                                                        )
                                                                        .colorScheme
                                                                        .secondary,
                                                                strokeWidth: 2,
                                                                strokeColor:
                                                                    Theme.of(
                                                                          context,
                                                                        )
                                                                        .colorScheme
                                                                        .onSecondary,
                                                              ),
                                                        ),
                                                        belowBarData: BarAreaData(
                                                          show: true,
                                                          gradient: LinearGradient(
                                                            colors: [
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .secondary
                                                                  .withOpacity(
                                                                    0.3,
                                                                  ),
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .secondary
                                                                  .withOpacity(
                                                                    0.0,
                                                                  ),
                                                            ],
                                                            begin:
                                                                Alignment
                                                                    .topCenter,
                                                            end:
                                                                Alignment
                                                                    .bottomCenter,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                    lineTouchData: LineTouchData(
                                                      enabled: true,
                                                      touchTooltipData: LineTouchTooltipData(
                                                        getTooltipItems: (
                                                          touchedSpots,
                                                        ) {
                                                          return touchedSpots.map((
                                                            spot,
                                                          ) {
                                                            final index =
                                                                spot.x.toInt();
                                                            if (index >= 0 &&
                                                                index <
                                                                    _entries
                                                                        .length) {
                                                              final entry =
                                                                  _entries[index];
                                                              final date =
                                                                  DateTime.parse(
                                                                    entry['created_at'],
                                                                  );
                                                              return LineTooltipItem(
                                                                '${StringExtension(entry['mood'].toString()).capitalize()}\n${DateFormat('d MMMM yyyy').format(date)}',
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .textTheme
                                                                    .bodyMedium!
                                                                    .copyWith(
                                                                      color:
                                                                          Theme.of(
                                                                            context,
                                                                          ).colorScheme.onSurface,
                                                                    ),
                                                              );
                                                            }
                                                            return null;
                                                          }).toList();
                                                        },
                                                      ),
                                                    ),
                                                    minY: -0.5,
                                                    maxY: 4.5,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Container(
                                          padding: const EdgeInsets.all(8.0),
                                          decoration: BoxDecoration(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 20,
                                                height: 4,
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.secondary,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Mood Trend',
                                                style:
                                                    Theme.of(
                                                      context,
                                                    ).textTheme.bodyMedium,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        AnimationConfiguration.staggeredList(
                                          position: 1,
                                          duration: const Duration(
                                            milliseconds: 375,
                                          ),
                                          child: SlideAnimation(
                                            verticalOffset: 50.0,
                                            child: FadeInAnimation(
                                              child: MoodAnalysisCard(
                                                analysis: moodAnalysis,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                        ),
                      ),
                    ),
          ),
        );
      },
    );
  }
}

class MoodAnalysis {
  final List<Map<String, dynamic>> entries;
  final double Function(String?) getMoodValue;

  MoodAnalysis({required this.entries, required this.getMoodValue});

  Map<String, int> get moodCounts {
    final counts = <String, int>{
      'happy': 0,
      'excited': 0,
      'neutral': 0,
      'tired': 0,
      'sad': 0,
    };
    for (var entry in entries) {
      final mood = entry['mood']?.toString().toLowerCase();
      if (mood != null && counts.containsKey(mood)) {
        counts[mood] = counts[mood]! + 1;
      }
    }
    return counts;
  }

  double get averageMood {
    if (entries.isEmpty) return 0.0;
    final validMoods =
        entries
            .where(
              (entry) =>
                  entry['mood'] != null && getMoodValue(entry['mood']) >= 0,
            )
            .map((entry) => getMoodValue(entry['mood']))
            .toList();
    if (validMoods.isEmpty) return 0.0;
    return validMoods.reduce((a, b) => a + b) / validMoods.length;
  }

  String get dominantMood {
    final counts = moodCounts;
    if (counts.values.every((count) => count == 0)) return 'None';
    return StringExtension(
      counts.entries.reduce((a, b) => a.value > b.value ? a : b).key,
    ).capitalize();
  }

  String get moodTrend {
    if (entries.length < 2) return 'Insufficient data';
    final recentMoods =
        entries
            .take(3)
            .where(
              (entry) =>
                  entry['mood'] != null && getMoodValue(entry['mood']) >= 0,
            )
            .map((entry) => getMoodValue(entry['mood']))
            .toList();
    final olderMoods =
        entries
            .skip(3)
            .where(
              (entry) =>
                  entry['mood'] != null && getMoodValue(entry['mood']) >= 0,
            )
            .map((entry) => getMoodValue(entry['mood']))
            .toList();
    if (recentMoods.isEmpty || olderMoods.isEmpty) return 'Insufficient data';
    final recentAvg = recentMoods.reduce((a, b) => a + b) / recentMoods.length;
    final olderAvg = olderMoods.reduce((a, b) => a + b) / olderMoods.length;
    if (recentAvg > olderAvg) return 'Improving';
    if (recentAvg < olderAvg) return 'Declining';
    return 'Stable';
  }

  List<String> get recommendations {
    final recs = <String>[];
    final dominantMoodLower = dominantMood.toLowerCase();
    final trend = moodTrend.toLowerCase();
    final avgMood = averageMood;

    if (dominantMoodLower == 'sad' || avgMood < 1.5) {
      recs.add(
        'Consider journaling your thoughts to process emotions. Writing can help clarify feelings and reduce stress.',
      );
      recs.add(
        'Try a mindfulness exercise, like deep breathing or meditation, to calm your mind.',
      );
      recs.add(
        'If sadness persists, consider reaching out to a trusted friend or a mental health professional.',
      );
    }
    if (dominantMoodLower == 'tired' || avgMood < 2.0) {
      recs.add(
        'Prioritize rest by setting a consistent sleep schedule. Aim for 7-8 hours of quality sleep.',
      );
      recs.add(
        'Take short breaks during the day to recharge, such as a 10-minute walk or stretching.',
      );
      recs.add('Stay hydrated and eat balanced meals to boost energy levels.');
    }
    if (dominantMoodLower == 'neutral') {
      recs.add(
        'Engage in a creative activity, like drawing or cooking, to spark joy and inspiration.',
      );
      recs.add(
        'Set a small, achievable goal for the day to create a sense of accomplishment.',
      );
    }
    if (dominantMoodLower == 'excited' ||
        dominantMoodLower == 'happy' ||
        avgMood >= 3.0) {
      recs.add(
        'Practice gratitude by noting three things you’re thankful for today to maintain positive emotions.',
      );
      recs.add(
        'Share your positive energy with others through social activities or kind gestures.',
      );
      recs.add(
        'Capture this moment by adding a diary entry to reflect on what’s making you happy.',
      );
    }
    if (trend == 'declining') {
      recs.add(
        'Reflect on recent changes or stressors that might be affecting your mood. Consider discussing them with someone you trust.',
      );
      recs.add(
        'Incorporate a daily self-care routine, such as reading, listening to music, or taking a warm bath.',
      );
    }
    if (trend == 'improving') {
      recs.add(
        'Keep up the positive habits that are contributing to your improved mood, like regular exercise or social connections.',
      );
      recs.add(
        'Celebrate your progress by treating yourself to something small, like a favorite snack or activity.',
      );
    }

    return recs.isEmpty
        ? ['Keep tracking your moods to gain more insights.']
        : recs;
  }
}

class MoodAnalysisCard extends StatelessWidget {
  final MoodAnalysis analysis;

  const MoodAnalysisCard({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mood Analysis',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dominant Mood: ${analysis.dominantMood}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Average Mood Score: ${analysis.averageMood.toStringAsFixed(1)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Mood Trend: ${analysis.moodTrend}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Recommendations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            ...analysis.recommendations.map(
              (rec) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rec,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
