import 'package:flutter/material.dart';
import '../constants/string_constants.dart';

class NetworkAwareWidget extends StatelessWidget {
  final Widget child;
  final bool isConnected;

  const NetworkAwareWidget({
    super.key,
    required this.child,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!isConnected)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.orange.shade700,
            child: Row(
              children: [
                const Icon(Icons.wifi_off, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    StringConstants.networkError,
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        Expanded(child: child),
      ],
    );
  }
}
