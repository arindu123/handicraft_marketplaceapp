import 'package:flutter/material.dart';

import 'handicraft_showcase.dart';

/// Visual order differs from the page indexes to keep discovery in the centre.
class HandicraftNavigationBar extends StatelessWidget {
  const HandicraftNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  static const atlas = 'assets/images/navigation/handicraft_atlas.png';
  static const _clay = Color(0xFF9A4023);

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    child: DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFEDE7DF))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 3, 4, 3),
          child: Row(
            children: [
              _destination(0, 'Home', Icons.home_outlined, Icons.home),
              _destination(2, 'Saved', Icons.favorite_outline, Icons.favorite),
              Expanded(
                flex: 2,
                child: Center(
                  heightFactor: 1,
                  child: Semantics(
                    label: 'Explore handmade products',
                    button: true,
                    selected: selectedIndex == 1,
                    child: Tooltip(
                      message: 'Explore handmade products',
                      child: SizedBox(
                        width: 72,
                        height: 48,
                        child: Material(
                          color: const Color(0xFFFFE68A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(
                              color: selectedIndex == 1
                                  ? _clay
                                  : const Color(0xFFFFE68A),
                              width: 2,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => onDestinationSelected(1),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: ExcludeSemantics(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: HandicraftShowcase(
                                    imageBuilder: (_, index) => Center(
                                      child: AspectRatio(
                                        aspectRatio: 1,
                                        child: _AtlasCell(index: index),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _destination(
                3,
                'Cart',
                Icons.shopping_cart_outlined,
                Icons.shopping_cart,
              ),
              _destination(4, 'Profile', Icons.person_outline, Icons.person),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _destination(
    int index,
    String label,
    IconData icon,
    IconData activeIcon,
  ) {
    final selected = selectedIndex == index;
    final color = selected ? _clay : const Color(0xFF72716E);
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onDestinationSelected(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(selected ? activeIcon : icon, size: 24, color: color),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AtlasCell extends StatelessWidget {
  const _AtlasCell({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) => ClipRect(
      child: OverflowBox(
        alignment: Alignment(
          index.isEven ? -1 : 1,
          index >= 4 ? 0 : (index < 2 ? -1 : 1),
        ),
        minWidth: constraints.maxWidth * 2,
        maxWidth: constraints.maxWidth * 2,
        minHeight: constraints.maxHeight * (index >= 4 ? 1 : 2),
        maxHeight: constraints.maxHeight * (index >= 4 ? 1 : 2),
        child: Image.asset(
          index >= 4
              ? 'assets/images/navigation/handicraft_extra.png'
              : HandicraftNavigationBar.atlas,
          fit: BoxFit.fill,
        ),
      ),
    ),
  );
}
