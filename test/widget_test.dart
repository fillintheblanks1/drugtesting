import 'package:flutter_test/flutter_test.dart';
import 'package:drugtesting/main.dart';

void main() {
  testWidgets('Field Drug Test UI elements render smoke test', (WidgetTester tester) async {
    // Build the app and render the initial frame
    await tester.pumpWidget(const FieldDrugTestApp());

    // Verify app title in the AppBar
    expect(find.text('Digital Companion for Field Drug Testing'), findsOneWidget);

    // Verify security status badge
    expect(find.text('SHA-256 Ledger Active'), findsOneWidget);

    // Verify bottom navigation tabs exist
    expect(find.text('Field Test Scanner'), findsOneWidget);
    expect(find.text('Searchable Audit Log'), findsOneWidget);
  });
}