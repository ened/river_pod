import 'package:mockito/mockito.dart';
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';

import '../../utils.dart';

void main() {
  group('Provider.autoDispose', () {
    test('does not notify listeners when called ref.state= with == new value',
        () async {
      final container = createContainer();
      final listener = Listener<int>();
      late AutoDisposeProviderRef<int> ref;
      final provider = AutoDisposeProvider<int>((r) {
        ref = r;
        return 0;
      });

      container.listen(provider, listener, fireImmediately: true);

      verifyOnly(listener, listener(0));

      ref.state = 0;
      await container.pump();

      verifyNoMoreInteractions(listener);
    });

    group('scoping an override overrides all the associated subproviders', () {
      test('when passing the provider itself', () {
        final provider = Provider.autoDispose((ref) => 0);
        final root = createContainer();
        final container = createContainer(parent: root, overrides: [provider]);

        expect(container.read(provider), 0);
        expect(container.getAllProviderElements(), [
          isA<ProviderElementBase>().having((e) => e.origin, 'origin', provider)
        ]);
        expect(root.getAllProviderElements(), isEmpty);
      });

      test('when using provider.overrideWithValue', () {
        final provider = Provider.autoDispose((ref) => 0);
        final root = createContainer();
        final container = createContainer(parent: root, overrides: [
          provider.overrideWithValue(42),
        ]);

        expect(container.read(provider), 42);
        expect(container.getAllProviderElements(), [
          isA<ProviderElementBase>().having((e) => e.origin, 'origin', provider)
        ]);
        expect(root.getAllProviderElements(), isEmpty);
      });

      test('when using provider.overrideWithProvider', () {
        final provider = Provider.autoDispose((ref) => 0);
        final root = createContainer();
        final container = createContainer(parent: root, overrides: [
          provider.overrideWithProvider(Provider.autoDispose((ref) => 42)),
        ]);

        expect(container.read(provider), 42);
        expect(container.getAllProviderElements(), [
          isA<ProviderElementBase>().having((e) => e.origin, 'origin', provider)
        ]);
        expect(root.getAllProviderElements(), isEmpty);
      });
    });
  });

  test('Provider.autoDispose can be overriden by auto-dispose providers', () {
    final provider = Provider.autoDispose((_) => 42);
    final AutoDisposeProviderBase<int> override =
        Provider.autoDispose((_) => 21);
    final container = createContainer(overrides: [
      provider.overrideWithProvider(override),
    ]);

    final sub = container.listen(provider, (_) {});

    expect(sub.read(), 21);
  });
}
