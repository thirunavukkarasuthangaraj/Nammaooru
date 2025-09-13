class Stats {
  final DeliveryPartnerStats currentUser;
  final List<DailyStats> dailyStats;
  final List<WeeklyStats> weeklyStats;
  final List<MonthlyStats> monthlyStats;
  final List<Achievement> achievements;
  final PerformanceMetrics performance;

  const Stats({
    required this.currentUser,
    required this.dailyStats,
    required this.weeklyStats,
    required this.monthlyStats,
    required this.achievements,
    required this.performance,
  });

  factory Stats.fromJson(Map<String, dynamic> json) {
    return Stats(
      currentUser: DeliveryPartnerStats.fromJson(json['currentUser'] ?? {}),
      dailyStats: (json['dailyStats'] as List<dynamic>? ?? [])
          .map((stats) => DailyStats.fromJson(stats))
          .toList(),
      weeklyStats: (json['weeklyStats'] as List<dynamic>? ?? [])
          .map((stats) => WeeklyStats.fromJson(stats))
          .toList(),
      monthlyStats: (json['monthlyStats'] as List<dynamic>? ?? [])
          .map((stats) => MonthlyStats.fromJson(stats))
          .toList(),
      achievements: (json['achievements'] as List<dynamic>? ?? [])
          .map((achievement) => Achievement.fromJson(achievement))
          .toList(),
      performance: PerformanceMetrics.fromJson(json['performance'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentUser': currentUser.toJson(),
      'dailyStats': dailyStats.map((stats) => stats.toJson()).toList(),
      'weeklyStats': weeklyStats.map((stats) => stats.toJson()).toList(),
      'monthlyStats': monthlyStats.map((stats) => stats.toJson()).toList(),
      'achievements': achievements.map((achievement) => achievement.toJson()).toList(),
      'performance': performance.toJson(),
    };
  }
}

class DeliveryPartnerStats {
  final String id;
  final String name;
  final String? profileImageUrl;
  final int totalDeliveries;
  final double totalEarnings;
  final double averageRating;
  final int rank;
  final int completionRate;
  final Duration averageDeliveryTime;
  final int onTimeDeliveries;

  const DeliveryPartnerStats({
    required this.id,
    required this.name,
    this.profileImageUrl,
    required this.totalDeliveries,
    required this.totalEarnings,
    required this.averageRating,
    required this.rank,
    required this.completionRate,
    required this.averageDeliveryTime,
    required this.onTimeDeliveries,
  });

  factory DeliveryPartnerStats.fromJson(Map<String, dynamic> json) {
    return DeliveryPartnerStats(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      profileImageUrl: json['profileImageUrl'],
      totalDeliveries: json['totalDeliveries'] ?? 0,
      totalEarnings: (json['totalEarnings'] ?? 0.0).toDouble(),
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      rank: json['rank'] ?? 0,
      completionRate: json['completionRate'] ?? 0,
      averageDeliveryTime: Duration(minutes: json['averageDeliveryTimeMinutes'] ?? 0),
      onTimeDeliveries: json['onTimeDeliveries'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'profileImageUrl': profileImageUrl,
      'totalDeliveries': totalDeliveries,
      'totalEarnings': totalEarnings,
      'averageRating': averageRating,
      'rank': rank,
      'completionRate': completionRate,
      'averageDeliveryTimeMinutes': averageDeliveryTime.inMinutes,
      'onTimeDeliveries': onTimeDeliveries,
    };
  }

  String get formattedRating {
    return '⭐${averageRating.toStringAsFixed(1)}';
  }

  String get formattedAverageDeliveryTime {
    final hours = averageDeliveryTime.inHours;
    final minutes = averageDeliveryTime.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

class DailyStats {
  final DateTime date;
  final int deliveries;
  final double earnings;
  final Duration onlineTime;
  final double averageRating;

  const DailyStats({
    required this.date,
    required this.deliveries,
    required this.earnings,
    required this.onlineTime,
    required this.averageRating,
  });

  factory DailyStats.fromJson(Map<String, dynamic> json) {
    return DailyStats(
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      deliveries: json['deliveries'] ?? 0,
      earnings: (json['earnings'] ?? 0.0).toDouble(),
      onlineTime: Duration(minutes: json['onlineTimeMinutes'] ?? 0),
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'deliveries': deliveries,
      'earnings': earnings,
      'onlineTimeMinutes': onlineTime.inMinutes,
      'averageRating': averageRating,
    };
  }
}

class WeeklyStats {
  final DateTime weekStart;
  final DateTime weekEnd;
  final int totalDeliveries;
  final double totalEarnings;
  final Duration totalOnlineTime;
  final double averageRating;

  const WeeklyStats({
    required this.weekStart,
    required this.weekEnd,
    required this.totalDeliveries,
    required this.totalEarnings,
    required this.totalOnlineTime,
    required this.averageRating,
  });

  factory WeeklyStats.fromJson(Map<String, dynamic> json) {
    return WeeklyStats(
      weekStart: DateTime.parse(json['weekStart'] ?? DateTime.now().toIso8601String()),
      weekEnd: DateTime.parse(json['weekEnd'] ?? DateTime.now().toIso8601String()),
      totalDeliveries: json['totalDeliveries'] ?? 0,
      totalEarnings: (json['totalEarnings'] ?? 0.0).toDouble(),
      totalOnlineTime: Duration(minutes: json['totalOnlineTimeMinutes'] ?? 0),
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weekStart': weekStart.toIso8601String(),
      'weekEnd': weekEnd.toIso8601String(),
      'totalDeliveries': totalDeliveries,
      'totalEarnings': totalEarnings,
      'totalOnlineTimeMinutes': totalOnlineTime.inMinutes,
      'averageRating': averageRating,
    };
  }
}

class MonthlyStats {
  final int month;
  final int year;
  final int totalDeliveries;
  final double totalEarnings;
  final Duration totalOnlineTime;
  final double averageRating;

  const MonthlyStats({
    required this.month,
    required this.year,
    required this.totalDeliveries,
    required this.totalEarnings,
    required this.totalOnlineTime,
    required this.averageRating,
  });

  factory MonthlyStats.fromJson(Map<String, dynamic> json) {
    return MonthlyStats(
      month: json['month'] ?? 0,
      year: json['year'] ?? 0,
      totalDeliveries: json['totalDeliveries'] ?? 0,
      totalEarnings: (json['totalEarnings'] ?? 0.0).toDouble(),
      totalOnlineTime: Duration(minutes: json['totalOnlineTimeMinutes'] ?? 0),
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'year': year,
      'totalDeliveries': totalDeliveries,
      'totalEarnings': totalEarnings,
      'totalOnlineTimeMinutes': totalOnlineTime.inMinutes,
      'averageRating': averageRating,
    };
  }

  String get monthName {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconUrl;
  final DateTime unlockedDate;
  final AchievementType type;
  final int progress;
  final int target;
  final bool isUnlocked;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconUrl,
    required this.unlockedDate,
    required this.type,
    required this.progress,
    required this.target,
    required this.isUnlocked,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      iconUrl: json['iconUrl'] ?? '',
      unlockedDate: DateTime.parse(json['unlockedDate'] ?? DateTime.now().toIso8601String()),
      type: AchievementType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => AchievementType.delivery,
      ),
      progress: json['progress'] ?? 0,
      target: json['target'] ?? 0,
      isUnlocked: json['isUnlocked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconUrl': iconUrl,
      'unlockedDate': unlockedDate.toIso8601String(),
      'type': type.toString().split('.').last,
      'progress': progress,
      'target': target,
      'isUnlocked': isUnlocked,
    };
  }

  double get progressPercentage {
    if (target == 0) return 0.0;
    return (progress / target).clamp(0.0, 1.0);
  }
}

class PerformanceMetrics {
  final double efficiency;
  final double customerSatisfaction;
  final int streakDays;
  final double averageDeliveryDistance;
  final int totalHours;
  final double fuelEfficiency;
  final int peakHourDeliveries;
  final double averageWaitTime;

  const PerformanceMetrics({
    required this.efficiency,
    required this.customerSatisfaction,
    required this.streakDays,
    required this.averageDeliveryDistance,
    required this.totalHours,
    required this.fuelEfficiency,
    required this.peakHourDeliveries,
    required this.averageWaitTime,
  });

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) {
    return PerformanceMetrics(
      efficiency: (json['efficiency'] ?? 0.0).toDouble(),
      customerSatisfaction: (json['customerSatisfaction'] ?? 0.0).toDouble(),
      streakDays: json['streakDays'] ?? 0,
      averageDeliveryDistance: (json['averageDeliveryDistance'] ?? 0.0).toDouble(),
      totalHours: json['totalHours'] ?? 0,
      fuelEfficiency: (json['fuelEfficiency'] ?? 0.0).toDouble(),
      peakHourDeliveries: json['peakHourDeliveries'] ?? 0,
      averageWaitTime: (json['averageWaitTime'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'efficiency': efficiency,
      'customerSatisfaction': customerSatisfaction,
      'streakDays': streakDays,
      'averageDeliveryDistance': averageDeliveryDistance,
      'totalHours': totalHours,
      'fuelEfficiency': fuelEfficiency,
      'peakHourDeliveries': peakHourDeliveries,
      'averageWaitTime': averageWaitTime,
    };
  }
}

class Leaderboard {
  final List<DeliveryPartnerStats> topPerformers;
  final int currentUserRank;
  final int totalParticipants;

  const Leaderboard({
    required this.topPerformers,
    required this.currentUserRank,
    required this.totalParticipants,
  });

  factory Leaderboard.fromJson(Map<String, dynamic> json) {
    return Leaderboard(
      topPerformers: (json['topPerformers'] as List<dynamic>? ?? [])
          .map((performer) => DeliveryPartnerStats.fromJson(performer))
          .toList(),
      currentUserRank: json['currentUserRank'] ?? 0,
      totalParticipants: json['totalParticipants'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topPerformers': topPerformers.map((performer) => performer.toJson()).toList(),
      'currentUserRank': currentUserRank,
      'totalParticipants': totalParticipants,
    };
  }
}

enum AchievementType {
  delivery,
  earnings,
  rating,
  streak,
  distance,
  time,
  special,
}

extension AchievementTypeExtension on AchievementType {
  String get displayName {
    switch (this) {
      case AchievementType.delivery:
        return 'Delivery Milestone';
      case AchievementType.earnings:
        return 'Earnings Achievement';
      case AchievementType.rating:
        return 'Rating Excellence';
      case AchievementType.streak:
        return 'Streak Master';
      case AchievementType.distance:
        return 'Distance Champion';
      case AchievementType.time:
        return 'Time Efficiency';
      case AchievementType.special:
        return 'Special Achievement';
    }
  }

  String get emoji {
    switch (this) {
      case AchievementType.delivery:
        return '🚚';
      case AchievementType.earnings:
        return '💰';
      case AchievementType.rating:
        return '⭐';
      case AchievementType.streak:
        return '🔥';
      case AchievementType.distance:
        return '📏';
      case AchievementType.time:
        return '⏱️';
      case AchievementType.special:
        return '🏆';
    }
  }
}