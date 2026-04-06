import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import 'snackbar_helper.dart';

/// A widget that listens to AppProvider error changes and shows a snackbar.
/// Wrap screens with this to get automatic error display.
class ErrorListener extends StatefulWidget {
  final Widget child;

  const ErrorListener({super.key, required this.child});

  @override
  State<ErrorListener> createState() => _ErrorListenerState();
}

class _ErrorListenerState extends State<ErrorListener> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkError();
  }

  void _checkError() {
    final app = context.read<AppProvider>();
    final error = app.consumeError();
    if (error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showErrorSnackbar(context, error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        // Check for new errors each rebuild
        final error = app.consumeError();
        if (error != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) showErrorSnackbar(context, error);
          });
        }
        return widget.child;
      },
    );
  }
}
