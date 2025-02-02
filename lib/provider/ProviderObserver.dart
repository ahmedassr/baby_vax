import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyProviderObserver extends ProviderObserver {
  @override
  void didUpdateProvider(ProviderBase provider, Object? previousValue, Object? newValue, ProviderContainer container) {
    super.didUpdateProvider(provider, previousValue, newValue, container);
    print('Provider: ${provider.name ?? provider.runtimeType}');
    print('Previous Value: $previousValue');
    print('New Value: $newValue');
  }

  @override
  void didAddProvider(ProviderBase provider, Object? value, ProviderContainer container) {
    super.didAddProvider(provider, value, container);
    print('Provider Added: ${provider.name ?? provider.runtimeType}');
    print('Initial Value: $value');
  }

  @override
  void didDisposeProvider(ProviderBase provider, ProviderContainer container) {
    super.didDisposeProvider(provider, container);
    print('Provider Disposed: ${provider.name ?? provider.runtimeType}');
  }
}
