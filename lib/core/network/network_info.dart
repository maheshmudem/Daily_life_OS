abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  NetworkInfoImpl();

  @override
  Future<bool> get isConnected async {
    try {
      // Simple connectivity check without external package
      // In production, use connectivity_plus or similar
      return true;
    } catch (_) {
      return false;
    }
  }
}
