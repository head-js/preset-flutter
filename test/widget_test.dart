import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preset/main.dart';
import 'package:preset/router.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    final container = ProviderContainer();
    final router = createRouter(container);

    await tester.pumpWidget(MyApp(router: router));

    expect(find.text('Login'), findsOneWidget);
  });
}