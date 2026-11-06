import '../imports/import_manger.dart';

mixin StateMixinHelper<T> on StateMixin<T> {
  void setLoading() => change(null, status: RxStatus.loading());

  void setSuccess([T? data]) => change(data, status: RxStatus.success());

  void setEmpty([T? data]) => change(data, status: RxStatus.empty());

  void setError([String? message]) =>
      change(null, status: RxStatus.error(message ?? "Error Occurred"));
}
