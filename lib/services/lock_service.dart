import 'package:device_apps/device_apps.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'dart:async';
import 'dart:ui';
import '../db/db_helper.dart';
import '../models/task.dart';

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  Timer.periodic(const Duration(seconds: 3), (timer) async {
    final settings = await DBHelper.instance.getSettings();
    if (settings == null || !settings.lockActiveStatus) return;

    final targetPackage = settings.targetAppPackage;

    // Check yesterday's task completion autonomously
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final tasks = await DBHelper.instance.getTasks();
    final yesterdayTasks = tasks.where((t) {
      final tDate = DateTime.parse(t.date);
      return tDate.year == yesterday.year && tDate.month == yesterday.month && tDate.day == yesterday.day;
    }).toList();

    bool shouldLock = false;
    if (yesterdayTasks.isNotEmpty) {
      int completedYesterday = yesterdayTasks.where((t) => t.isCompleted).length;
      if (completedYesterday < yesterdayTasks.length) {
        shouldLock = true;
      }
    }

    if (!shouldLock) return;

    bool isGranted = await UsageStats.checkUsagePermission() ?? false;
    if (!isGranted) return;

    DateTime endDate = DateTime.now();
    DateTime startDate = endDate.subtract(const Duration(seconds: 10));

    List<EventUsageInfo> events = await UsageStats.queryEvents(startDate, endDate);

    if (events.isNotEmpty) {
      // Find the latest move to foreground event to determine current app
      EventUsageInfo? latestEvent;
      for (var e in events) {
        if (e.eventType == "1") { // MOVE_TO_FOREGROUND
          if (latestEvent == null || int.parse(e.timeStamp!) > int.parse(latestEvent.timeStamp!)) {
            latestEvent = e;
          }
        }
      }

      if (latestEvent != null) {
        if (latestEvent.packageName == targetPackage) {
          if (!(await FlutterOverlayWindow.isActive())) {
            await FlutterOverlayWindow.showOverlay(
              enableDrag: false,
              flag: OverlayFlag.defaultFlag,
              alignment: OverlayAlignment.center,
              visibility: NotificationVisibility.visibilitySecret,
              positionGravity: PositionGravity.auto,
              height: WindowSize.matchParent,
              width: WindowSize.matchParent,
            );
          }
        } else {
          // User left target app, close overlay
          if (await FlutterOverlayWindow.isActive()) {
            await FlutterOverlayWindow.closeOverlay();
          }
        }
      }
    }
  });
}


class LockService {
  static final LockService instance = LockService._init();
  Timer? _timer;

  LockService._init();

  Future<List<Application>> fetchInstalledApps() async {
    List<Application> apps = await DeviceApps.getInstalledApplications(
        includeAppIcons: true,
        includeSystemApps: false,
        onlyAppsWithLaunchIntent: true);
    return apps;
  }

  Future<void> checkTargetAppUsage(String targetPackageName) async {
    DateTime endDate = DateTime.now();
    DateTime startDate = endDate.subtract(Duration(minutes: 5));

    List<UsageInfo> usageStats = await UsageStats.queryUsageStats(startDate, endDate);

    // Sort logic to find the app in foreground right now
    // Actually we will simplify and just check if flutter overlay window is needed.

    // In a real android usage_stats, we'd find the latest foreground app.
    // For this prototype, we'll assume we can trigger overlay if we want to block the app.

    // Check permission
    bool isGranted = await UsageStats.checkUsagePermission() ?? false;
    if (!isGranted) {
      await UsageStats.grantUsagePermission();
    }
  }

  Future<void> triggerLockOverlay() async {
    bool isGranted = await FlutterOverlayWindow.isPermissionGranted();
    if (!isGranted) {
      await FlutterOverlayWindow.requestPermission();
    }

    if (await FlutterOverlayWindow.isActive()) {
      return;
    }

    await FlutterOverlayWindow.showOverlay(
      enableDrag: false,
      flag: OverlayFlag.defaultFlag,
      alignment: OverlayAlignment.center,
      visibility: NotificationVisibility.visibilitySecret,
      positionGravity: PositionGravity.auto,
      height: WindowSize.matchParent,
      width: WindowSize.matchParent,
    );
  }

  Future<void> closeOverlay() async {
    await FlutterOverlayWindow.closeOverlay();
  }

  Future<void> initializeBackgroundService() async {
    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
      ),
    );
  }

  Future<void> startMonitoring(String targetPackageName, bool shouldLock) async {
    final service = FlutterBackgroundService();

    if (shouldLock) {
      if (!(await service.isRunning())) {
        await service.startService();
      }
      service.invoke("setTarget", {"targetPackage": targetPackageName});
    } else {
      if (await service.isRunning()) {
        service.invoke("stopService");
      }
    }
  }

  Future<void> stopMonitoring() async {
    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      service.invoke("stopService");
    }
  }
}
