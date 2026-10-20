import 'package:flutter/material.dart';
import '../models/vault_item_model.dart';

abstract class VaultLocalDataSource {
  Future<List<VaultPasswordModel>> getPasswords();
  Future<List<VaultDocumentModel>> getDocuments();
}

class VaultLocalDataSourceImpl implements VaultLocalDataSource {
  @override
  Future<List<VaultPasswordModel>> getPasswords() async {
    return [
      VaultPasswordModel(
        id: 1,
        title: 'HDFC NetBanking',
        username: 'user_alex_77',
        category: 'Banking',
        iconCodePoint: Icons.account_balance_rounded.codePoint,
      ),
      VaultPasswordModel(
        id: 2,
        title: 'Primary Google Workspace',
        username: 'alex.dev@gmail.com',
        category: 'Email',
        iconCodePoint: Icons.email_rounded.codePoint,
      ),
      VaultPasswordModel(
        id: 3,
        title: 'Home High-Speed Wi-Fi',
        username: 'SSID: SkyNet_5G',
        category: 'Wi-Fi',
        iconCodePoint: Icons.wifi_password_rounded.codePoint,
      ),
    ];
  }

  @override
  Future<List<VaultDocumentModel>> getDocuments() async {
    return [
      VaultDocumentModel(
        id: 1,
        title: 'MacBook Pro M3 Warranty',
        category: 'Electronics Warranty',
        expiry: 'Expires in 28 days (Nov 16)',
        isExpiringSoon: true,
        hasReminder: true,
        iconCodePoint: Icons.laptop_mac_rounded.codePoint,
      ),
      VaultDocumentModel(
        id: 2,
        title: 'Health Insurance Policy PDF',
        category: 'Medical & Health',
        expiry: 'Valid till Aug 2027',
        isExpiringSoon: false,
        hasReminder: true,
        iconCodePoint: Icons.health_and_safety_rounded.codePoint,
      ),
      VaultDocumentModel(
        id: 3,
        title: 'Motorcycle Comprehensive Insurance',
        category: 'Vehicle Document',
        expiry: 'Valid till Dec 2026',
        isExpiringSoon: false,
        hasReminder: false,
        iconCodePoint: Icons.two_wheeler_rounded.codePoint,
      ),
    ];
  }
}
