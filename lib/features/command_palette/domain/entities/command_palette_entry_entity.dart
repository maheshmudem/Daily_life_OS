import 'package:equatable/equatable.dart';

/// Supported module filters for the Universal Command Palette.
class CommandPaletteModules {
  CommandPaletteModules._();

  static const String all = 'All';
  static const String actions = 'Actions';
  static const String today = 'Today';
  static const String planner = 'Planner';
  static const String money = 'Money';
  static const String notes = 'Notes';
  static const String vault = 'Vault';

  static const List<String> ordered = [
    all,
    actions,
    today,
    planner,
    money,
    notes,
    vault,
  ];
}

/// Pure domain icon identifier mapped to constant Material icons in presentation.
enum CommandPaletteIconType {
  bolt,
  mic,
  scanner,
  timer,
  wallet,
  lightbulb,
  security,
  repeat,
  schedule,
  eventAvailable,
  northEast,
  southWest,
  autorenew,
  handshake,
  pushPin,
  stickyNote,
  key,
  verifiedUser,
}

/// Domain entity representing an indexed item or command in the
/// Universal Command Palette & Cross-Module Spotlight Search.
class CommandPaletteEntryEntity extends Equatable {
  final String id;
  final String title;
  final String subtitle;
  final String module;
  final CommandPaletteIconType iconType;
  final int accentColorValue;
  final String badgeText;
  final int? targetTabIndex;
  final String? captureModeName; // 'text', 'voice', 'scan'

  const CommandPaletteEntryEntity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.module,
    required this.iconType,
    required this.accentColorValue,
    required this.badgeText,
    this.targetTabIndex,
    this.captureModeName,
  });

  bool matchesQuery(String normalizedQuery) {
    if (normalizedQuery.isEmpty) return true;
    return title.toLowerCase().contains(normalizedQuery) ||
        subtitle.toLowerCase().contains(normalizedQuery) ||
        module.toLowerCase().contains(normalizedQuery) ||
        badgeText.toLowerCase().contains(normalizedQuery);
  }

  @override
  List<Object?> get props => [
    id,
    title,
    subtitle,
    module,
    iconType,
    accentColorValue,
    badgeText,
    targetTabIndex,
    captureModeName,
  ];
}
