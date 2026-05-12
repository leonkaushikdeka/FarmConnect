import 'package:flutter_test/flutter_test.dart';
import 'package:farmconnect/main.dart';

void main() {
  testWidgets('App loads and shows auth screen tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const FarmConnectApp());
    await tester.pump();

    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Farmer'), findsOneWidget);
  });
}
