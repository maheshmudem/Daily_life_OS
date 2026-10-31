import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class VaultPasswordEntity extends Equatable {
  final int id;
  final String title;
  final String username;
  final String category;
  final int iconCodePoint;

  const VaultPasswordEntity({
    required this.id,
    required this.title,
    required this.username,
    required this.category,
    required this.iconCodePoint,
  });

  // ignore: non_const_argument_for_const_parameter
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  @override
  List<Object?> get props => [id, title, username, category];
}

class VaultDocumentEntity extends Equatable {
  final int id;
  final String title;
  final String category;
  final String expiry;
  final bool isExpiringSoon;
  final bool hasReminder;
  final int iconCodePoint;

  const VaultDocumentEntity({
    required this.id,
    required this.title,
    required this.category,
    required this.expiry,
    required this.isExpiringSoon,
    required this.hasReminder,
    required this.iconCodePoint,
  });

  // ignore: non_const_argument_for_const_parameter
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  @override
  List<Object?> get props => [
    id,
    title,
    category,
    expiry,
    isExpiringSoon,
    hasReminder,
  ];
}
