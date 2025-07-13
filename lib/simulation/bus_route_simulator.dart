// lib/simulation/bus_route_simulator.dart
// ignore_for_file: avoid_print

import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// A class that simulates the movement of a bus along a predefined route.
///
/// It takes a list of geographical points (LatLng) representing the route
/// and provides a mechanism to advance the bus's position over time,
/// notifying a listener of the new position.
class BusRouteSimulator {
  /// The list of LatLng points that define the bus's route.
  final List<LatLng> _routePoints;

  /// A callback function that is invoked with the bus's new position
  /// each time it moves.
  final Function(LatLng newPosition) _onPositionUpdate;

  Timer? _timer; // The timer responsible for triggering position updates.
  int _currentIndex = 0; // The current index of the bus in the _routePoints list.
  bool _isSimulating = false; // Flag to indicate if the simulation is active.

  /// Creates a [BusRouteSimulator] instance.
  ///
  /// [routePoints]: A list of `LatLng` objects representing the sequence
  ///   of points the bus will travel through.
  /// [onPositionUpdate]: A callback function that will be called with the
  ///   current `LatLng` position of the simulated bus as it moves.
  BusRouteSimulator(this._routePoints, this._onPositionUpdate);

  /// Returns `true` if the bus simulation is currently active, `false` otherwise.
  bool get isSimulating => _isSimulating;

  /// Returns the current simulated position of the bus.
  ///
  /// Returns `null` if `_routePoints` is empty.
  LatLng? get currentSimulatedPosition =>
      _routePoints.isNotEmpty ? _routePoints[_currentIndex] : null;

  /// Returns the index of the current bus stop (or point) the bus is at in the route.
  int get currentBusStopIndex => _currentIndex;

  /// Starts the bus route simulation.
  ///
  /// The simulation will move the bus to the next point in `_routePoints`
  /// at regular intervals defined by the timer's duration.
  ///
  /// If `_routePoints` is empty or the simulation is already running,
  /// this method does nothing.
  void startSimulation() {
    if (_routePoints.isEmpty) {
      print("BusRouteSimulator: No route points to simulate.");
      return;
    }
    if (_isSimulating) {
      print("BusRouteSimulator: Simulation is already running.");
      return; // Prevent starting multiple timers
    }

    _isSimulating = true;
    _currentIndex = 0; // Always start from the beginning of the route
    _onPositionUpdate(_routePoints[_currentIndex]); // Trigger initial position update

    // Start a periodic timer. Adjust the `Duration` to control simulation speed.
    // For a real-world scenario, this might involve calculating time between points.
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _moveBusToNextStop();
    });
  }

  /// Stops the bus route simulation.
  ///
  /// Cancels the active timer and sets the simulation flag to `false`.
  void stopSimulation() {
    _timer?.cancel(); // Cancel the timer if it's active
    _isSimulating = false;
    print("BusRouteSimulator: Simulation stopped.");
  }

  /// Moves the simulated bus to the next point in the route.
  ///
  /// This method updates `_currentIndex` to the next point in the `_routePoints`
  /// list, cycling back to the start if the end of the route is reached.
  /// It then calls the `_onPositionUpdate` callback with the new position.
  void _moveBusToNextStop() {
    if (_routePoints.isEmpty) {
      print("BusRouteSimulator: No route points to move to.");
      stopSimulation(); // Stop simulation if route points become empty
      return;
    }

    // Advance the index, wrapping around to the beginning if the end is reached
    _currentIndex = (_currentIndex + 1) % _routePoints.length;
    final LatLng newPosition = _routePoints[_currentIndex];

    // Notify the listener of the new position
    _onPositionUpdate(newPosition);
    print("BusRouteSimulator: Moved to stop index $_currentIndex at $newPosition");
  }

  /// Cleans up resources used by the simulator.
  ///
  /// This should be called when the simulator is no longer needed (e.g., in `dispose` of the widget).
  void dispose() {
    _timer?.cancel();
    print("BusRouteSimulator: Disposed.");
  }
}