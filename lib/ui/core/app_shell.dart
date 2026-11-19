import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Window width from which the shell shows a side rail instead of a bottom bar.
const railBreakpoint = 840.0;

/// The home screen: Food, Groceries and Recipes, with a bottom bar on narrow
/// windows and a side rail from [railBreakpoint] wide.
class AppShell extends StatefulWidget {
  const AppShell({super.key, this.food, this.groceries, this.recipes});

  /// Each section's screen; null shows the section's empty state.
  final Widget? food;
  final Widget? groceries;
  final Widget? recipes;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final wide = MediaQuery.sizeOf(context).width >= railBreakpoint;
    final destinations = [
      (
        label: l10n.navFood,
        icon: Icons.kitchen_outlined,
        selected: Icons.kitchen,
      ),
      (
        label: l10n.navGroceries,
        icon: Icons.shopping_cart_outlined,
        selected: Icons.shopping_cart,
      ),
      (
        label: l10n.navRecipes,
        icon: Icons.menu_book_outlined,
        selected: Icons.menu_book,
      ),
    ];

    // One Scaffold for both layouts, with the IndexedStack last in the Row, so
    // a resize across 840 px keeps each tab's state.
    return Scaffold(
      appBar: AppBar(
        title: Text(destinations[_index].label),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: l10n.accountTitle,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AccountPlaceholderScreen(),
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          if (wide) ...[
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: _select,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final (:label, :icon, :selected) in destinations)
                  NavigationRailDestination(
                    icon: Icon(icon),
                    selectedIcon: Icon(selected),
                    label: Text(label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
          ],
          Expanded(
            child: IndexedStack(
              index: _index,
              children: [
                widget.food ?? EmptySection(message: l10n.foodEmpty),
                widget.groceries ?? EmptySection(message: l10n.groceriesEmpty),
                widget.recipes ?? EmptySection(message: l10n.recipesEmpty),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _select,
              destinations: [
                for (final (:label, :icon, :selected) in destinations)
                  NavigationDestination(
                    icon: Icon(icon),
                    selectedIcon: Icon(selected),
                    label: label,
                  ),
              ],
            ),
    );
  }
}

/// A section's centered empty-state message.
class EmptySection extends StatelessWidget {
  const EmptySection({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );
}

/// Stands in for household and account settings until sign-in exists.
class AccountPlaceholderScreen extends StatelessWidget {
  const AccountPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountTitle)),
      body: EmptySection(message: l10n.accountPlaceholder),
    );
  }
}
