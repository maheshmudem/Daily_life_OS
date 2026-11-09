import '../../domain/entities/command_palette_entry_entity.dart';

class CommandPaletteEntryModel extends CommandPaletteEntryEntity {
  const CommandPaletteEntryModel({
    required super.id,
    required super.title,
    required super.subtitle,
    required super.module,
    required super.iconType,
    required super.accentColorValue,
    required super.badgeText,
    super.targetTabIndex,
    super.captureModeName,
  });
}
