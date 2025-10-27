import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Custom widget that wraps a DataTable with scrollable support for web
class ScrollableDataTable extends StatelessWidget {
  final Widget child;
  final ScrollController? verticalController;
  final ScrollController? horizontalController;

  const ScrollableDataTable({
    super.key,
    required this.child,
    this.verticalController,
    this.horizontalController,
  });

  @override
  Widget build(BuildContext context) {
    final vController = verticalController ?? ScrollController();
    final hController = horizontalController ?? ScrollController();

    return Scrollbar(
      controller: vController,
      thumbVisibility: kIsWeb, // Show scrollbar on web
      thickness: kIsWeb ? 12.0 : null,
      radius: const Radius.circular(10),
      child: SingleChildScrollView(
        controller: vController,
        scrollDirection: Axis.vertical,
        child: Scrollbar(
          controller: hController,
          thumbVisibility: kIsWeb, // Show scrollbar on web
          thickness: kIsWeb ? 12.0 : null,
          radius: const Radius.circular(10),
          scrollbarOrientation: ScrollbarOrientation.bottom,
          child: SingleChildScrollView(
            controller: hController,
            scrollDirection: Axis.horizontal,
            child: child,
          ),
        ),
      ),
    );
  }
}
