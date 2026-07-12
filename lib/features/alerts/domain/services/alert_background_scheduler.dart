/// Domain-layer contract over the background task scheduler — keeps
/// Workmanager itself out of anything that isn't `data/`. §6.3/§20.5:
/// background execution is best-effort and its exact timing is
/// OS-controlled; this interface only promises that a periodic check gets
/// *registered*.
abstract class AlertBackgroundScheduler {
  /// Platform setup — must be called once before [registerPeriodicTask].
  Future<void> initialize();

  /// Registers the periodic alert-check task at [frequency], replacing any
  /// previously-registered one. Calling this again with a new [frequency]
  /// (e.g. after the user changes the Settings alert-frequency selector) is
  /// how rescheduling happens — there is no separate "cancel" step the
  /// caller needs to take first.
  Future<void> registerPeriodicTask(Duration frequency);
}
