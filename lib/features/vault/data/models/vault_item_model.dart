import '../../domain/entities/vault_item_entity.dart';

class VaultPasswordModel extends VaultPasswordEntity {
  const VaultPasswordModel({
    required super.id,
    required super.title,
    required super.username,
    required super.category,
    required super.iconCodePoint,
  });

  factory VaultPasswordModel.fromJson(Map<String, dynamic> json) {
    return VaultPasswordModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String,
      username: json['username'] as String,
      category: json['category'] as String,
      iconCodePoint: json['iconCodePoint'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'username': username,
        'category': category,
        'iconCodePoint': iconCodePoint,
      };
}

class VaultDocumentModel extends VaultDocumentEntity {
  const VaultDocumentModel({
    required super.id,
    required super.title,
    required super.category,
    required super.expiry,
    required super.isExpiringSoon,
    required super.hasReminder,
    required super.iconCodePoint,
  });

  factory VaultDocumentModel.fromJson(Map<String, dynamic> json) {
    return VaultDocumentModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String,
      category: json['category'] as String,
      expiry: json['expiry'] as String,
      isExpiringSoon: json['isExpiringSoon'] as bool? ?? false,
      hasReminder: json['hasReminder'] as bool? ?? false,
      iconCodePoint: json['iconCodePoint'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'expiry': expiry,
        'isExpiringSoon': isExpiringSoon,
        'hasReminder': hasReminder,
        'iconCodePoint': iconCodePoint,
      };
}
