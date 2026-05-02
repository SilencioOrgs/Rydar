import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rydar_app/features/ride_tracking/ride_tracking_screen.dart';
import 'package:rydar_app/shared/widgets/map_route_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    dotenv.testLoad(fileInput: 'MAPBOX_ACCESS_TOKEN=PASTE_MAPBOX_TOKEN_HERE');
  });

  Future<void> pumpRideTrackingScreen(
    WidgetTester tester, {
    Size size = const Size(390, 844),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: RideTrackingScreen()));
    await tester.pumpAndSettle();
  }

  Future<void> openRouteTools(WidgetTester tester) async {
    await tester.tap(find.text('Pin finish line on the map'));
    await tester.pumpAndSettle();
  }

  group('RideTrackingScreen route tools', () {
    testWidgets('shows isolated search, pin, and vehicle sections', (
      tester,
    ) async {
      await pumpRideTrackingScreen(tester);

      await openRouteTools(tester);

      expect(find.text('Set finish line'), findsOneWidget);
      expect(find.text('Search finish'), findsOneWidget);
      expect(find.text('Pin finish'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Vehicle'),
        240,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Vehicle'), findsOneWidget);
      expect(find.text('Car'), findsOneWidget);
      expect(find.text('Motorcycle'), findsOneWidget);
      expect(find.text('Bicycle'), findsOneWidget);
      expect(find.text('Walking'), findsOneWidget);
    });

    testWidgets('validates short finish search queries', (tester) async {
      await pumpRideTrackingScreen(tester);
      await openRouteTools(tester);

      await tester.enterText(find.byType(TextField), 'a');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(
        find.text('Type at least 2 characters to search.'),
        findsOneWidget,
      );
    });

    testWidgets('route tools remain usable on narrow screens', (tester) async {
      await pumpRideTrackingScreen(tester, size: const Size(320, 640));

      await openRouteTools(tester);

      expect(find.text('Search finish'), findsOneWidget);
      expect(find.text('Pin finish'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('play button opens start choices', (tester) async {
      await pumpRideTrackingScreen(tester);

      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Start car ride'), findsOneWidget);
      expect(find.text('Exit bubble'), findsOneWidget);
      expect(find.text('Start now'), findsOneWidget);
      expect(find.text('OFFLINE BUBBLE'), findsOneWidget);
      expect(find.text('OFFLINE NOW'), findsOneWidget);
    });

    testWidgets('sports mode replaces map with digital speed view', (
      tester,
    ) async {
      await pumpRideTrackingScreen(tester);

      expect(find.byType(MapRouteView), findsOneWidget);

      await tester.tap(find.text('SPORTS'));
      await tester.pumpAndSettle();

      expect(find.byType(MapRouteView), findsNothing);
      expect(find.text('KM/H  MAX 200'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
