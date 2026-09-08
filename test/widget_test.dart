import 'package:avantika_lok_tourism_app/app/app.dart';
import 'package:avantika_lok_tourism_app/app/config/environment_config.dart';
import 'package:avantika_lok_tourism_app/app/di/injection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows Avantika Lok splash screen', (tester) async {
    await configureDependencies(EnvironmentConfig.userDevelopment);

    await tester.pumpWidget(
      const AvantikaLokApp(config: EnvironmentConfig.userDevelopment),
    );

    expect(find.text('Avantika Lok'), findsOneWidget);
    expect(find.text('A Holy March'), findsOneWidget);
  });
}
