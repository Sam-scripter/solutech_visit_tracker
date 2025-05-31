import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// [connectivityProvider] is a Riverpod stream provider that monitors
/// the device's internet connectivity status in real time.
///
/// It emits a [ConnectivityResult] whenever the network state changes.
///
/// This is useful for:
/// - Enabling/disabling features based on connectivity
/// - Triggering sync operations when a connection is restored
/// - Displaying UI indicators when the app goes offline
///
/// Note: `.map((list) => list.first)` is used in case multiple results
/// are returned from the stream, ensuring we only care about the primary status.
final connectivityProvider = StreamProvider<ConnectivityResult>(
      (ref) => Connectivity()
      .onConnectivityChanged
      .map((list) => list.isNotEmpty ? list.first : ConnectivityResult.none),
  name: 'connectivityProvider',
);

