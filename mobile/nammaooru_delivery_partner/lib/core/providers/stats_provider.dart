import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../constants/api_endpoints.dart';
import '../models/stats_model.dart';

class StatsProvider with ChangeNotifier {
  Stats? _stats;
  Leaderboard? _leaderboard;
  bool _isLoading = false;
  String? _error;

  // Getters
  Stats? get stats => _stats;
  Leaderboard? get leaderboard => _leaderboard;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load stats data
  Future<void> loadStats() async {
    _setLoading(true);
    
    try {
      // For demo, create mock stats data
      _stats = _createMockStats();
      _error = null;
    } catch (e) {
      _error = 'Failed to load stats data';
      if (kDebugMode) {
        print('Load Stats Error: $e');
      }
    }
    
    _setLoading(false);
  }

  // Load leaderboard data
  Future<void> loadLeaderboard() async {
    try {
      // For demo, create mock leaderboard data
      _leaderboard = _createMockLeaderboard();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load leaderboard data';
      if (kDebugMode) {
        print('Load Leaderboard Error: $e');
      }
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Mock data generation
  Stats _createMockStats() {
    return Stats(
      currentUser: const DeliveryPartnerStats(
        id: 'DP001',
        name: 'Rajesh Kumar',
        profileImageUrl: 'https://ui-avatars.com/api/?name=Rajesh+Kumar&background=4CAF50&color=fff',
        totalDeliveries: 456,
        totalEarnings: 45280.0,
        averageRating: 4.7,
        rank: 15,
        completionRate: 96,
        averageDeliveryTime: Duration(minutes: 18),
        onTimeDeliveries: 432,
      ),
      dailyStats: _createMockDailyStats(),
      weeklyStats: _createMockWeeklyStats(),
      monthlyStats: _createMockMonthlyStats(),
      achievements: _createMockAchievements(),
      performance: const PerformanceMetrics(
        efficiency: 92.5,
        customerSatisfaction: 4.7,
        streakDays: 12,
        averageDeliveryDistance: 3.2,
        totalHours: 320,
        fuelEfficiency: 45.8,
        peakHourDeliveries: 156,
        averageWaitTime: 4.5,
      ),
    );
  }

  List<DailyStats> _createMockDailyStats() {
    final today = DateTime.now();
    return List.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      return DailyStats(
        date: date,
        deliveries: 6 + (index % 4),
        earnings: 480.0 + (index * 50),
        onlineTime: Duration(hours: 6 + (index % 3), minutes: 30),
        averageRating: 4.5 + (index % 3) * 0.1,
      );
    });
  }

  List<WeeklyStats> _createMockWeeklyStats() {
    final today = DateTime.now();
    return List.generate(4, (index) {
      final weekStart = today.subtract(Duration(days: (3 - index) * 7));
      final weekEnd = weekStart.add(const Duration(days: 6));
      return WeeklyStats(
        weekStart: weekStart,
        weekEnd: weekEnd,
        totalDeliveries: 35 + (index * 5),
        totalEarnings: 2800.0 + (index * 200),
        totalOnlineTime: Duration(hours: 42 + (index * 2)),
        averageRating: 4.5 + (index * 0.05),
      );
    });
  }

  List<MonthlyStats> _createMockMonthlyStats() {
    final today = DateTime.now();
    return List.generate(3, (index) {
      final month = today.month - index;
      final year = month <= 0 ? today.year - 1 : today.year;
      final adjustedMonth = month <= 0 ? 12 + month : month;
      
      return MonthlyStats(
        month: adjustedMonth,
        year: year,
        totalDeliveries: 120 + (index * 10),
        totalEarnings: 9600.0 + (index * 800),
        totalOnlineTime: Duration(hours: 168 + (index * 20)),
        averageRating: 4.6 + (index * 0.05),
      );
    });
  }

  List<Achievement> _createMockAchievements() {
    return [
      Achievement(
        id: 'ACH001',
        title: 'Century Maker',
        description: 'Complete 100 deliveries',
        iconUrl: '🚚',
        unlockedDate: DateTime.now().subtract(const Duration(days: 30)),
        type: AchievementType.delivery,
        progress: 456,
        target: 100,
        isUnlocked: true,
      ),
      Achievement(
        id: 'ACH002',
        title: 'Five Star Hero',
        description: 'Maintain 4.5+ rating for 30 days',
        iconUrl: '⭐',
        unlockedDate: DateTime.now().subtract(const Duration(days: 15)),
        type: AchievementType.rating,
        progress: 30,
        target: 30,
        isUnlocked: true,
      ),
      Achievement(
        id: 'ACH003',
        title: 'Speed Demon',
        description: 'Complete 50 deliveries in peak hours',
        iconUrl: '⚡',
        unlockedDate: DateTime.now().subtract(const Duration(days: 45)),
        type: AchievementType.time,
        progress: 156,
        target: 50,
        isUnlocked: true,
      ),
      Achievement(
        id: 'ACH004',
        title: 'Streak Master',
        description: 'Work 15 consecutive days',
        iconUrl: '🔥',
        unlockedDate: DateTime.now(),
        type: AchievementType.streak,
        progress: 12,
        target: 15,
        isUnlocked: false,
      ),
      Achievement(
        id: 'ACH005',
        title: 'Big Earner',
        description: 'Earn ₹50,000 in total',
        iconUrl: '💰',
        unlockedDate: DateTime.now(),
        type: AchievementType.earnings,
        progress: 45280,
        target: 50000,
        isUnlocked: false,
      ),
      Achievement(
        id: 'ACH006',
        title: 'Distance Champion',
        description: 'Cover 1000km in deliveries',
        iconUrl: '🏁',
        unlockedDate: DateTime.now(),
        type: AchievementType.distance,
        progress: 850,
        target: 1000,
        isUnlocked: false,
      ),
    ];
  }

  Leaderboard _createMockLeaderboard() {
    return Leaderboard(
      topPerformers: [
        const DeliveryPartnerStats(
          id: 'DP002',
          name: 'Arjun Singh',
          profileImageUrl: 'https://ui-avatars.com/api/?name=Arjun+Singh&background=4CAF50&color=fff',
          totalDeliveries: 623,
          totalEarnings: 58400.0,
          averageRating: 4.9,
          rank: 1,
          completionRate: 98,
          averageDeliveryTime: Duration(minutes: 15),
          onTimeDeliveries: 610,
        ),
        const DeliveryPartnerStats(
          id: 'DP003',
          name: 'Vikash Patel',
          profileImageUrl: 'https://ui-avatars.com/api/?name=Vikash+Patel&background=4CAF50&color=fff',
          totalDeliveries: 587,
          totalEarnings: 54200.0,
          averageRating: 4.8,
          rank: 2,
          completionRate: 97,
          averageDeliveryTime: Duration(minutes: 16),
          onTimeDeliveries: 570,
        ),
        const DeliveryPartnerStats(
          id: 'DP004',
          name: 'Suresh Kumar',
          profileImageUrl: 'https://ui-avatars.com/api/?name=Suresh+Kumar&background=4CAF50&color=fff',
          totalDeliveries: 543,
          totalEarnings: 51800.0,
          averageRating: 4.8,
          rank: 3,
          completionRate: 96,
          averageDeliveryTime: Duration(minutes: 17),
          onTimeDeliveries: 521,
        ),
        const DeliveryPartnerStats(
          id: 'DP005',
          name: 'Ramesh Sharma',
          profileImageUrl: 'https://ui-avatars.com/api/?name=Ramesh+Sharma&background=4CAF50&color=fff',
          totalDeliveries: 512,
          totalEarnings: 49600.0,
          averageRating: 4.7,
          rank: 4,
          completionRate: 95,
          averageDeliveryTime: Duration(minutes: 17),
          onTimeDeliveries: 486,
        ),
        const DeliveryPartnerStats(
          id: 'DP006',
          name: 'Amit Gupta',
          profileImageUrl: 'https://ui-avatars.com/api/?name=Amit+Gupta&background=4CAF50&color=fff',
          totalDeliveries: 489,
          totalEarnings: 47200.0,
          averageRating: 4.7,
          rank: 5,
          completionRate: 94,
          averageDeliveryTime: Duration(minutes: 18),
          onTimeDeliveries: 460,
        ),
      ],
      currentUserRank: 15,
      totalParticipants: 150,
    );
  }
}