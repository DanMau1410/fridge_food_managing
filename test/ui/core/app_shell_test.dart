import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_food_managing/l10n/app_localizations.dart';
import 'package:fridge_food_managing/main.dart';
import 'package:fridge_food_managing/ui/auth/widgets/account_screen.dart';
import 'package:fridge_food_managing/ui/core/app_shell.dart';

import '../auth/harness.dart';

const _narrow = Size(600, 800);
const _wide = Size(1000, 800);
const _foodKey = ValueKey('food');
const _groceriesKey = ValueKey('groceries');

/// Sets the test surface to [size] logical pixels and the device language to
/// [locale], both reset after the test.
void _setDevice(
  WidgetTester tester, {
  Size size = _narrow,
  Locale locale = const Locale('en'),
}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
}

/// The shell with stateful probes in the Food and Groceries slots.
Widget _probeApp() => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: const AppShell(
    food: _Probe(key: _foodKey),
    groceries: _Probe(key: _groceriesKey),
  ),
);

State _foodState(WidgetTester tester) =>
    tester.state(find.byKey(_foodKey, skipOffstage: false));

/// Goes to Groceries and back to Food through the nav icons (in the bar or the
/// rail), checking each switch landed.
Future<void> _roundTrip(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
  await tester.pumpAndSettle();
  expect(find.byKey(_groceriesKey), findsOneWidget);
  expect(find.byKey(_foodKey), findsNothing);

  await tester.tap(find.byIcon(Icons.kitchen_outlined));
  await tester.pumpAndSettle();
  expect(find.byKey(_foodKey), findsOneWidget);
}

void main() {
  group('AC-AF-1: nav labels follow the device language', () {
    const cases = {
      'en': ['Food', 'Groceries', 'Recipes'],
      'es': ['Alimentos', 'Compras', 'Recetas'],
      'fr': ['Food', 'Groceries', 'Recipes'],
    };
    for (final MapEntry(key: language, value: labels) in cases.entries) {
      testWidgets(language, (tester) async {
        _setDevice(tester, locale: Locale(language));
        await tester.pumpWidget(const FridgeApp(home: AppShell()));
        await tester.pumpAndSettle();

        for (final label in labels) {
          expect(
            find.descendant(
              of: find.byType(NavigationBar),
              matching: find.text(label),
            ),
            findsOneWidget,
          );
        }
      });
    }
  });

  group('AC-AF-2: layout follows the window width', () {
    testWidgets('narrow shows a bottom bar', (tester) async {
      _setDevice(tester, size: _narrow);
      await tester.pumpWidget(const FridgeApp(home: AppShell()));

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('wide shows a side rail', (tester) async {
      _setDevice(tester, size: _wide);
      await tester.pumpWidget(const FridgeApp(home: AppShell()));

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    for (final (width, rail) in [(839.0, false), (840.0, true)]) {
      testWidgets('${width.toInt()} px is the ${rail ? 'rail' : 'bar'}', (
        tester,
      ) async {
        _setDevice(tester, size: Size(width, 800));
        await tester.pumpWidget(const FridgeApp(home: AppShell()));

        expect(
          find.byType(NavigationRail),
          rail ? findsOneWidget : findsNothing,
        );
        expect(
          find.byType(NavigationBar),
          rail ? findsNothing : findsOneWidget,
        );
      });
    }
  });

  group('AC-AF-2: tab state survives', () {
    for (final (name, size) in [('bar', _narrow), ('rail', _wide)]) {
      testWidgets('switching tabs in the $name layout', (tester) async {
        _setDevice(tester, size: size);
        await tester.pumpWidget(_probeApp());
        final before = _foodState(tester);

        await _roundTrip(tester);

        expect(identical(_foodState(tester), before), isTrue);
      });
    }

    testWidgets('resizing from narrow to wide and back', (tester) async {
      _setDevice(tester, size: _narrow);
      await tester.pumpWidget(_probeApp());
      final before = _foodState(tester);

      tester.view.physicalSize = _wide;
      await tester.pumpAndSettle();
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(identical(_foodState(tester), before), isTrue);

      tester.view.physicalSize = _narrow;
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(identical(_foodState(tester), before), isTrue);
    });
  });

  testWidgets('account button opens the account screen and back returns', (
    tester,
  ) async {
    _setDevice(tester);
    final auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'u1'),
    );
    await tester.pumpWidget(testApp(auth, const AppShell()));

    await tester.tap(find.byTooltip('Household & account'));
    await tester.pumpAndSettle();
    expect(find.byType(AccountScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(AccountScreen), findsNothing);
  });
}

class _Probe extends StatefulWidget {
  const _Probe({super.key});

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
