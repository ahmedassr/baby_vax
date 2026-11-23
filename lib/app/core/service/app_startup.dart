/// Start-up work still running after the first frame.
///
/// `main` sets [ready] to the deferred services' future; the splash waits
/// for it before routing. Tests leave it completed.
class AppStartup {
  const AppStartup._();

  static Future<void> ready = Future<void>.value();
}
