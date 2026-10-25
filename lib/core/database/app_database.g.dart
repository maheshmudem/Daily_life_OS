// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $HabitsTable extends Habits with TableInfo<$HabitsTable, Habit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconCodePointMeta = const VerificationMeta(
    'iconCodePoint',
  );
  @override
  late final GeneratedColumn<int> iconCodePoint = GeneratedColumn<int>(
    'icon_code_point',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorValueMeta = const VerificationMeta(
    'colorValue',
  );
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
    'color_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _streakDaysMeta = const VerificationMeta(
    'streakDays',
  );
  @override
  late final GeneratedColumn<int> streakDays = GeneratedColumn<int>(
    'streak_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isDoneTodayMeta = const VerificationMeta(
    'isDoneToday',
  );
  @override
  late final GeneratedColumn<bool> isDoneToday = GeneratedColumn<bool>(
    'is_done_today',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_done_today" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastCompletedDateMeta = const VerificationMeta(
    'lastCompletedDate',
  );
  @override
  late final GeneratedColumn<String> lastCompletedDate =
      GeneratedColumn<String>(
        'last_completed_date',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    iconCodePoint,
    colorValue,
    streakDays,
    isDoneToday,
    lastCompletedDate,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habits';
  @override
  VerificationContext validateIntegrity(
    Insertable<Habit> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('icon_code_point')) {
      context.handle(
        _iconCodePointMeta,
        iconCodePoint.isAcceptableOrUnknown(
          data['icon_code_point']!,
          _iconCodePointMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_iconCodePointMeta);
    }
    if (data.containsKey('color_value')) {
      context.handle(
        _colorValueMeta,
        colorValue.isAcceptableOrUnknown(data['color_value']!, _colorValueMeta),
      );
    } else if (isInserting) {
      context.missing(_colorValueMeta);
    }
    if (data.containsKey('streak_days')) {
      context.handle(
        _streakDaysMeta,
        streakDays.isAcceptableOrUnknown(data['streak_days']!, _streakDaysMeta),
      );
    }
    if (data.containsKey('is_done_today')) {
      context.handle(
        _isDoneTodayMeta,
        isDoneToday.isAcceptableOrUnknown(
          data['is_done_today']!,
          _isDoneTodayMeta,
        ),
      );
    }
    if (data.containsKey('last_completed_date')) {
      context.handle(
        _lastCompletedDateMeta,
        lastCompletedDate.isAcceptableOrUnknown(
          data['last_completed_date']!,
          _lastCompletedDateMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Habit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Habit(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      iconCodePoint: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}icon_code_point'],
      )!,
      colorValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_value'],
      )!,
      streakDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}streak_days'],
      )!,
      isDoneToday: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_done_today'],
      )!,
      lastCompletedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_completed_date'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $HabitsTable createAlias(String alias) {
    return $HabitsTable(attachedDatabase, alias);
  }
}

class Habit extends DataClass implements Insertable<Habit> {
  final int id;
  final String title;
  final int iconCodePoint;
  final int colorValue;
  final int streakDays;
  final bool isDoneToday;
  final String? lastCompletedDate;
  final String createdAt;
  const Habit({
    required this.id,
    required this.title,
    required this.iconCodePoint,
    required this.colorValue,
    required this.streakDays,
    required this.isDoneToday,
    this.lastCompletedDate,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['icon_code_point'] = Variable<int>(iconCodePoint);
    map['color_value'] = Variable<int>(colorValue);
    map['streak_days'] = Variable<int>(streakDays);
    map['is_done_today'] = Variable<bool>(isDoneToday);
    if (!nullToAbsent || lastCompletedDate != null) {
      map['last_completed_date'] = Variable<String>(lastCompletedDate);
    }
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  HabitsCompanion toCompanion(bool nullToAbsent) {
    return HabitsCompanion(
      id: Value(id),
      title: Value(title),
      iconCodePoint: Value(iconCodePoint),
      colorValue: Value(colorValue),
      streakDays: Value(streakDays),
      isDoneToday: Value(isDoneToday),
      lastCompletedDate: lastCompletedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastCompletedDate),
      createdAt: Value(createdAt),
    );
  }

  factory Habit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Habit(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      iconCodePoint: serializer.fromJson<int>(json['iconCodePoint']),
      colorValue: serializer.fromJson<int>(json['colorValue']),
      streakDays: serializer.fromJson<int>(json['streakDays']),
      isDoneToday: serializer.fromJson<bool>(json['isDoneToday']),
      lastCompletedDate: serializer.fromJson<String?>(
        json['lastCompletedDate'],
      ),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'iconCodePoint': serializer.toJson<int>(iconCodePoint),
      'colorValue': serializer.toJson<int>(colorValue),
      'streakDays': serializer.toJson<int>(streakDays),
      'isDoneToday': serializer.toJson<bool>(isDoneToday),
      'lastCompletedDate': serializer.toJson<String?>(lastCompletedDate),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  Habit copyWith({
    int? id,
    String? title,
    int? iconCodePoint,
    int? colorValue,
    int? streakDays,
    bool? isDoneToday,
    Value<String?> lastCompletedDate = const Value.absent(),
    String? createdAt,
  }) => Habit(
    id: id ?? this.id,
    title: title ?? this.title,
    iconCodePoint: iconCodePoint ?? this.iconCodePoint,
    colorValue: colorValue ?? this.colorValue,
    streakDays: streakDays ?? this.streakDays,
    isDoneToday: isDoneToday ?? this.isDoneToday,
    lastCompletedDate: lastCompletedDate.present
        ? lastCompletedDate.value
        : this.lastCompletedDate,
    createdAt: createdAt ?? this.createdAt,
  );
  Habit copyWithCompanion(HabitsCompanion data) {
    return Habit(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      iconCodePoint: data.iconCodePoint.present
          ? data.iconCodePoint.value
          : this.iconCodePoint,
      colorValue: data.colorValue.present
          ? data.colorValue.value
          : this.colorValue,
      streakDays: data.streakDays.present
          ? data.streakDays.value
          : this.streakDays,
      isDoneToday: data.isDoneToday.present
          ? data.isDoneToday.value
          : this.isDoneToday,
      lastCompletedDate: data.lastCompletedDate.present
          ? data.lastCompletedDate.value
          : this.lastCompletedDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Habit(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('iconCodePoint: $iconCodePoint, ')
          ..write('colorValue: $colorValue, ')
          ..write('streakDays: $streakDays, ')
          ..write('isDoneToday: $isDoneToday, ')
          ..write('lastCompletedDate: $lastCompletedDate, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    iconCodePoint,
    colorValue,
    streakDays,
    isDoneToday,
    lastCompletedDate,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Habit &&
          other.id == this.id &&
          other.title == this.title &&
          other.iconCodePoint == this.iconCodePoint &&
          other.colorValue == this.colorValue &&
          other.streakDays == this.streakDays &&
          other.isDoneToday == this.isDoneToday &&
          other.lastCompletedDate == this.lastCompletedDate &&
          other.createdAt == this.createdAt);
}

class HabitsCompanion extends UpdateCompanion<Habit> {
  final Value<int> id;
  final Value<String> title;
  final Value<int> iconCodePoint;
  final Value<int> colorValue;
  final Value<int> streakDays;
  final Value<bool> isDoneToday;
  final Value<String?> lastCompletedDate;
  final Value<String> createdAt;
  const HabitsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.iconCodePoint = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.streakDays = const Value.absent(),
    this.isDoneToday = const Value.absent(),
    this.lastCompletedDate = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  HabitsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required int iconCodePoint,
    required int colorValue,
    this.streakDays = const Value.absent(),
    this.isDoneToday = const Value.absent(),
    this.lastCompletedDate = const Value.absent(),
    required String createdAt,
  }) : title = Value(title),
       iconCodePoint = Value(iconCodePoint),
       colorValue = Value(colorValue),
       createdAt = Value(createdAt);
  static Insertable<Habit> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<int>? iconCodePoint,
    Expression<int>? colorValue,
    Expression<int>? streakDays,
    Expression<bool>? isDoneToday,
    Expression<String>? lastCompletedDate,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (iconCodePoint != null) 'icon_code_point': iconCodePoint,
      if (colorValue != null) 'color_value': colorValue,
      if (streakDays != null) 'streak_days': streakDays,
      if (isDoneToday != null) 'is_done_today': isDoneToday,
      if (lastCompletedDate != null) 'last_completed_date': lastCompletedDate,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  HabitsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<int>? iconCodePoint,
    Value<int>? colorValue,
    Value<int>? streakDays,
    Value<bool>? isDoneToday,
    Value<String?>? lastCompletedDate,
    Value<String>? createdAt,
  }) {
    return HabitsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      streakDays: streakDays ?? this.streakDays,
      isDoneToday: isDoneToday ?? this.isDoneToday,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (iconCodePoint.present) {
      map['icon_code_point'] = Variable<int>(iconCodePoint.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (streakDays.present) {
      map['streak_days'] = Variable<int>(streakDays.value);
    }
    if (isDoneToday.present) {
      map['is_done_today'] = Variable<bool>(isDoneToday.value);
    }
    if (lastCompletedDate.present) {
      map['last_completed_date'] = Variable<String>(lastCompletedDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('iconCodePoint: $iconCodePoint, ')
          ..write('colorValue: $colorValue, ')
          ..write('streakDays: $streakDays, ')
          ..write('isDoneToday: $isDoneToday, ')
          ..write('lastCompletedDate: $lastCompletedDate, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $TimelineItemsTable extends TimelineItems
    with TableInfo<$TimelineItemsTable, TimelineItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimelineItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _timeMeta = const VerificationMeta('time');
  @override
  late final GeneratedColumn<String> time = GeneratedColumn<String>(
    'time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorValueMeta = const VerificationMeta(
    'colorValue',
  );
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
    'color_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconCodePointMeta = const VerificationMeta(
    'iconCodePoint',
  );
  @override
  late final GeneratedColumn<int> iconCodePoint = GeneratedColumn<int>(
    'icon_code_point',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDoneMeta = const VerificationMeta('isDone');
  @override
  late final GeneratedColumn<bool> isDone = GeneratedColumn<bool>(
    'is_done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    time,
    title,
    category,
    colorValue,
    iconCodePoint,
    isDone,
    action,
    date,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'timeline_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<TimelineItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('time')) {
      context.handle(
        _timeMeta,
        time.isAcceptableOrUnknown(data['time']!, _timeMeta),
      );
    } else if (isInserting) {
      context.missing(_timeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('color_value')) {
      context.handle(
        _colorValueMeta,
        colorValue.isAcceptableOrUnknown(data['color_value']!, _colorValueMeta),
      );
    } else if (isInserting) {
      context.missing(_colorValueMeta);
    }
    if (data.containsKey('icon_code_point')) {
      context.handle(
        _iconCodePointMeta,
        iconCodePoint.isAcceptableOrUnknown(
          data['icon_code_point']!,
          _iconCodePointMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_iconCodePointMeta);
    }
    if (data.containsKey('is_done')) {
      context.handle(
        _isDoneMeta,
        isDone.isAcceptableOrUnknown(data['is_done']!, _isDoneMeta),
      );
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TimelineItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimelineItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      time: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      colorValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_value'],
      )!,
      iconCodePoint: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}icon_code_point'],
      )!,
      isDone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_done'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
    );
  }

  @override
  $TimelineItemsTable createAlias(String alias) {
    return $TimelineItemsTable(attachedDatabase, alias);
  }
}

class TimelineItem extends DataClass implements Insertable<TimelineItem> {
  final int id;
  final String time;
  final String title;
  final String category;
  final int colorValue;
  final int iconCodePoint;
  final bool isDone;
  final String action;
  final String date;
  const TimelineItem({
    required this.id,
    required this.time,
    required this.title,
    required this.category,
    required this.colorValue,
    required this.iconCodePoint,
    required this.isDone,
    required this.action,
    required this.date,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['time'] = Variable<String>(time);
    map['title'] = Variable<String>(title);
    map['category'] = Variable<String>(category);
    map['color_value'] = Variable<int>(colorValue);
    map['icon_code_point'] = Variable<int>(iconCodePoint);
    map['is_done'] = Variable<bool>(isDone);
    map['action'] = Variable<String>(action);
    map['date'] = Variable<String>(date);
    return map;
  }

  TimelineItemsCompanion toCompanion(bool nullToAbsent) {
    return TimelineItemsCompanion(
      id: Value(id),
      time: Value(time),
      title: Value(title),
      category: Value(category),
      colorValue: Value(colorValue),
      iconCodePoint: Value(iconCodePoint),
      isDone: Value(isDone),
      action: Value(action),
      date: Value(date),
    );
  }

  factory TimelineItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimelineItem(
      id: serializer.fromJson<int>(json['id']),
      time: serializer.fromJson<String>(json['time']),
      title: serializer.fromJson<String>(json['title']),
      category: serializer.fromJson<String>(json['category']),
      colorValue: serializer.fromJson<int>(json['colorValue']),
      iconCodePoint: serializer.fromJson<int>(json['iconCodePoint']),
      isDone: serializer.fromJson<bool>(json['isDone']),
      action: serializer.fromJson<String>(json['action']),
      date: serializer.fromJson<String>(json['date']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'time': serializer.toJson<String>(time),
      'title': serializer.toJson<String>(title),
      'category': serializer.toJson<String>(category),
      'colorValue': serializer.toJson<int>(colorValue),
      'iconCodePoint': serializer.toJson<int>(iconCodePoint),
      'isDone': serializer.toJson<bool>(isDone),
      'action': serializer.toJson<String>(action),
      'date': serializer.toJson<String>(date),
    };
  }

  TimelineItem copyWith({
    int? id,
    String? time,
    String? title,
    String? category,
    int? colorValue,
    int? iconCodePoint,
    bool? isDone,
    String? action,
    String? date,
  }) => TimelineItem(
    id: id ?? this.id,
    time: time ?? this.time,
    title: title ?? this.title,
    category: category ?? this.category,
    colorValue: colorValue ?? this.colorValue,
    iconCodePoint: iconCodePoint ?? this.iconCodePoint,
    isDone: isDone ?? this.isDone,
    action: action ?? this.action,
    date: date ?? this.date,
  );
  TimelineItem copyWithCompanion(TimelineItemsCompanion data) {
    return TimelineItem(
      id: data.id.present ? data.id.value : this.id,
      time: data.time.present ? data.time.value : this.time,
      title: data.title.present ? data.title.value : this.title,
      category: data.category.present ? data.category.value : this.category,
      colorValue: data.colorValue.present
          ? data.colorValue.value
          : this.colorValue,
      iconCodePoint: data.iconCodePoint.present
          ? data.iconCodePoint.value
          : this.iconCodePoint,
      isDone: data.isDone.present ? data.isDone.value : this.isDone,
      action: data.action.present ? data.action.value : this.action,
      date: data.date.present ? data.date.value : this.date,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimelineItem(')
          ..write('id: $id, ')
          ..write('time: $time, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('colorValue: $colorValue, ')
          ..write('iconCodePoint: $iconCodePoint, ')
          ..write('isDone: $isDone, ')
          ..write('action: $action, ')
          ..write('date: $date')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    time,
    title,
    category,
    colorValue,
    iconCodePoint,
    isDone,
    action,
    date,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimelineItem &&
          other.id == this.id &&
          other.time == this.time &&
          other.title == this.title &&
          other.category == this.category &&
          other.colorValue == this.colorValue &&
          other.iconCodePoint == this.iconCodePoint &&
          other.isDone == this.isDone &&
          other.action == this.action &&
          other.date == this.date);
}

class TimelineItemsCompanion extends UpdateCompanion<TimelineItem> {
  final Value<int> id;
  final Value<String> time;
  final Value<String> title;
  final Value<String> category;
  final Value<int> colorValue;
  final Value<int> iconCodePoint;
  final Value<bool> isDone;
  final Value<String> action;
  final Value<String> date;
  const TimelineItemsCompanion({
    this.id = const Value.absent(),
    this.time = const Value.absent(),
    this.title = const Value.absent(),
    this.category = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.iconCodePoint = const Value.absent(),
    this.isDone = const Value.absent(),
    this.action = const Value.absent(),
    this.date = const Value.absent(),
  });
  TimelineItemsCompanion.insert({
    this.id = const Value.absent(),
    required String time,
    required String title,
    required String category,
    required int colorValue,
    required int iconCodePoint,
    this.isDone = const Value.absent(),
    required String action,
    required String date,
  }) : time = Value(time),
       title = Value(title),
       category = Value(category),
       colorValue = Value(colorValue),
       iconCodePoint = Value(iconCodePoint),
       action = Value(action),
       date = Value(date);
  static Insertable<TimelineItem> custom({
    Expression<int>? id,
    Expression<String>? time,
    Expression<String>? title,
    Expression<String>? category,
    Expression<int>? colorValue,
    Expression<int>? iconCodePoint,
    Expression<bool>? isDone,
    Expression<String>? action,
    Expression<String>? date,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (time != null) 'time': time,
      if (title != null) 'title': title,
      if (category != null) 'category': category,
      if (colorValue != null) 'color_value': colorValue,
      if (iconCodePoint != null) 'icon_code_point': iconCodePoint,
      if (isDone != null) 'is_done': isDone,
      if (action != null) 'action': action,
      if (date != null) 'date': date,
    });
  }

  TimelineItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? time,
    Value<String>? title,
    Value<String>? category,
    Value<int>? colorValue,
    Value<int>? iconCodePoint,
    Value<bool>? isDone,
    Value<String>? action,
    Value<String>? date,
  }) {
    return TimelineItemsCompanion(
      id: id ?? this.id,
      time: time ?? this.time,
      title: title ?? this.title,
      category: category ?? this.category,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      isDone: isDone ?? this.isDone,
      action: action ?? this.action,
      date: date ?? this.date,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (time.present) {
      map['time'] = Variable<String>(time.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (iconCodePoint.present) {
      map['icon_code_point'] = Variable<int>(iconCodePoint.value);
    }
    if (isDone.present) {
      map['is_done'] = Variable<bool>(isDone.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimelineItemsCompanion(')
          ..write('id: $id, ')
          ..write('time: $time, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('colorValue: $colorValue, ')
          ..write('iconCodePoint: $iconCodePoint, ')
          ..write('isDone: $isDone, ')
          ..write('action: $action, ')
          ..write('date: $date')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, Transaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconCodePointMeta = const VerificationMeta(
    'iconCodePoint',
  );
  @override
  late final GeneratedColumn<int> iconCodePoint = GeneratedColumn<int>(
    'icon_code_point',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('expense'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    category,
    amount,
    mode,
    iconCodePoint,
    date,
    type,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Transaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('icon_code_point')) {
      context.handle(
        _iconCodePointMeta,
        iconCodePoint.isAcceptableOrUnknown(
          data['icon_code_point']!,
          _iconCodePointMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_iconCodePointMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Transaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      iconCodePoint: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}icon_code_point'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class Transaction extends DataClass implements Insertable<Transaction> {
  final int id;
  final String title;
  final String category;
  final double amount;
  final String mode;
  final int iconCodePoint;
  final String date;
  final String type;
  const Transaction({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.mode,
    required this.iconCodePoint,
    required this.date,
    required this.type,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['category'] = Variable<String>(category);
    map['amount'] = Variable<double>(amount);
    map['mode'] = Variable<String>(mode);
    map['icon_code_point'] = Variable<int>(iconCodePoint);
    map['date'] = Variable<String>(date);
    map['type'] = Variable<String>(type);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      title: Value(title),
      category: Value(category),
      amount: Value(amount),
      mode: Value(mode),
      iconCodePoint: Value(iconCodePoint),
      date: Value(date),
      type: Value(type),
    );
  }

  factory Transaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transaction(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      category: serializer.fromJson<String>(json['category']),
      amount: serializer.fromJson<double>(json['amount']),
      mode: serializer.fromJson<String>(json['mode']),
      iconCodePoint: serializer.fromJson<int>(json['iconCodePoint']),
      date: serializer.fromJson<String>(json['date']),
      type: serializer.fromJson<String>(json['type']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'category': serializer.toJson<String>(category),
      'amount': serializer.toJson<double>(amount),
      'mode': serializer.toJson<String>(mode),
      'iconCodePoint': serializer.toJson<int>(iconCodePoint),
      'date': serializer.toJson<String>(date),
      'type': serializer.toJson<String>(type),
    };
  }

  Transaction copyWith({
    int? id,
    String? title,
    String? category,
    double? amount,
    String? mode,
    int? iconCodePoint,
    String? date,
    String? type,
  }) => Transaction(
    id: id ?? this.id,
    title: title ?? this.title,
    category: category ?? this.category,
    amount: amount ?? this.amount,
    mode: mode ?? this.mode,
    iconCodePoint: iconCodePoint ?? this.iconCodePoint,
    date: date ?? this.date,
    type: type ?? this.type,
  );
  Transaction copyWithCompanion(TransactionsCompanion data) {
    return Transaction(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      category: data.category.present ? data.category.value : this.category,
      amount: data.amount.present ? data.amount.value : this.amount,
      mode: data.mode.present ? data.mode.value : this.mode,
      iconCodePoint: data.iconCodePoint.present
          ? data.iconCodePoint.value
          : this.iconCodePoint,
      date: data.date.present ? data.date.value : this.date,
      type: data.type.present ? data.type.value : this.type,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transaction(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('amount: $amount, ')
          ..write('mode: $mode, ')
          ..write('iconCodePoint: $iconCodePoint, ')
          ..write('date: $date, ')
          ..write('type: $type')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, category, amount, mode, iconCodePoint, date, type);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.id == this.id &&
          other.title == this.title &&
          other.category == this.category &&
          other.amount == this.amount &&
          other.mode == this.mode &&
          other.iconCodePoint == this.iconCodePoint &&
          other.date == this.date &&
          other.type == this.type);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> category;
  final Value<double> amount;
  final Value<String> mode;
  final Value<int> iconCodePoint;
  final Value<String> date;
  final Value<String> type;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.category = const Value.absent(),
    this.amount = const Value.absent(),
    this.mode = const Value.absent(),
    this.iconCodePoint = const Value.absent(),
    this.date = const Value.absent(),
    this.type = const Value.absent(),
  });
  TransactionsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String category,
    required double amount,
    required String mode,
    required int iconCodePoint,
    required String date,
    this.type = const Value.absent(),
  }) : title = Value(title),
       category = Value(category),
       amount = Value(amount),
       mode = Value(mode),
       iconCodePoint = Value(iconCodePoint),
       date = Value(date);
  static Insertable<Transaction> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? category,
    Expression<double>? amount,
    Expression<String>? mode,
    Expression<int>? iconCodePoint,
    Expression<String>? date,
    Expression<String>? type,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (category != null) 'category': category,
      if (amount != null) 'amount': amount,
      if (mode != null) 'mode': mode,
      if (iconCodePoint != null) 'icon_code_point': iconCodePoint,
      if (date != null) 'date': date,
      if (type != null) 'type': type,
    });
  }

  TransactionsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? category,
    Value<double>? amount,
    Value<String>? mode,
    Value<int>? iconCodePoint,
    Value<String>? date,
    Value<String>? type,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      mode: mode ?? this.mode,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      date: date ?? this.date,
      type: type ?? this.type,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (iconCodePoint.present) {
      map['icon_code_point'] = Variable<int>(iconCodePoint.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('amount: $amount, ')
          ..write('mode: $mode, ')
          ..write('iconCodePoint: $iconCodePoint, ')
          ..write('date: $date, ')
          ..write('type: $type')
          ..write(')'))
        .toString();
  }
}

class $BudgetSettingsTable extends BudgetSettings
    with TableInfo<$BudgetSettingsTable, BudgetSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _monthlyBudgetMeta = const VerificationMeta(
    'monthlyBudget',
  );
  @override
  late final GeneratedColumn<double> monthlyBudget = GeneratedColumn<double>(
    'monthly_budget',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(40000),
  );
  static const VerificationMeta _fixedBillsMeta = const VerificationMeta(
    'fixedBills',
  );
  @override
  late final GeneratedColumn<double> fixedBills = GeneratedColumn<double>(
    'fixed_bills',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(8000),
  );
  @override
  List<GeneratedColumn> get $columns => [id, monthlyBudget, fixedBills];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budget_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<BudgetSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('monthly_budget')) {
      context.handle(
        _monthlyBudgetMeta,
        monthlyBudget.isAcceptableOrUnknown(
          data['monthly_budget']!,
          _monthlyBudgetMeta,
        ),
      );
    }
    if (data.containsKey('fixed_bills')) {
      context.handle(
        _fixedBillsMeta,
        fixedBills.isAcceptableOrUnknown(data['fixed_bills']!, _fixedBillsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BudgetSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BudgetSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      monthlyBudget: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monthly_budget'],
      )!,
      fixedBills: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fixed_bills'],
      )!,
    );
  }

  @override
  $BudgetSettingsTable createAlias(String alias) {
    return $BudgetSettingsTable(attachedDatabase, alias);
  }
}

class BudgetSetting extends DataClass implements Insertable<BudgetSetting> {
  final int id;
  final double monthlyBudget;
  final double fixedBills;
  const BudgetSetting({
    required this.id,
    required this.monthlyBudget,
    required this.fixedBills,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['monthly_budget'] = Variable<double>(monthlyBudget);
    map['fixed_bills'] = Variable<double>(fixedBills);
    return map;
  }

  BudgetSettingsCompanion toCompanion(bool nullToAbsent) {
    return BudgetSettingsCompanion(
      id: Value(id),
      monthlyBudget: Value(monthlyBudget),
      fixedBills: Value(fixedBills),
    );
  }

  factory BudgetSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BudgetSetting(
      id: serializer.fromJson<int>(json['id']),
      monthlyBudget: serializer.fromJson<double>(json['monthlyBudget']),
      fixedBills: serializer.fromJson<double>(json['fixedBills']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'monthlyBudget': serializer.toJson<double>(monthlyBudget),
      'fixedBills': serializer.toJson<double>(fixedBills),
    };
  }

  BudgetSetting copyWith({
    int? id,
    double? monthlyBudget,
    double? fixedBills,
  }) => BudgetSetting(
    id: id ?? this.id,
    monthlyBudget: monthlyBudget ?? this.monthlyBudget,
    fixedBills: fixedBills ?? this.fixedBills,
  );
  BudgetSetting copyWithCompanion(BudgetSettingsCompanion data) {
    return BudgetSetting(
      id: data.id.present ? data.id.value : this.id,
      monthlyBudget: data.monthlyBudget.present
          ? data.monthlyBudget.value
          : this.monthlyBudget,
      fixedBills: data.fixedBills.present
          ? data.fixedBills.value
          : this.fixedBills,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BudgetSetting(')
          ..write('id: $id, ')
          ..write('monthlyBudget: $monthlyBudget, ')
          ..write('fixedBills: $fixedBills')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, monthlyBudget, fixedBills);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BudgetSetting &&
          other.id == this.id &&
          other.monthlyBudget == this.monthlyBudget &&
          other.fixedBills == this.fixedBills);
}

class BudgetSettingsCompanion extends UpdateCompanion<BudgetSetting> {
  final Value<int> id;
  final Value<double> monthlyBudget;
  final Value<double> fixedBills;
  const BudgetSettingsCompanion({
    this.id = const Value.absent(),
    this.monthlyBudget = const Value.absent(),
    this.fixedBills = const Value.absent(),
  });
  BudgetSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.monthlyBudget = const Value.absent(),
    this.fixedBills = const Value.absent(),
  });
  static Insertable<BudgetSetting> custom({
    Expression<int>? id,
    Expression<double>? monthlyBudget,
    Expression<double>? fixedBills,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (monthlyBudget != null) 'monthly_budget': monthlyBudget,
      if (fixedBills != null) 'fixed_bills': fixedBills,
    });
  }

  BudgetSettingsCompanion copyWith({
    Value<int>? id,
    Value<double>? monthlyBudget,
    Value<double>? fixedBills,
  }) {
    return BudgetSettingsCompanion(
      id: id ?? this.id,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      fixedBills: fixedBills ?? this.fixedBills,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (monthlyBudget.present) {
      map['monthly_budget'] = Variable<double>(monthlyBudget.value);
    }
    if (fixedBills.present) {
      map['fixed_bills'] = Variable<double>(fixedBills.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetSettingsCompanion(')
          ..write('id: $id, ')
          ..write('monthlyBudget: $monthlyBudget, ')
          ..write('fixedBills: $fixedBills')
          ..write(')'))
        .toString();
  }
}

class $SubscriptionsTable extends Subscriptions
    with TableInfo<$SubscriptionsTable, Subscription> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubscriptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _renewalDateMeta = const VerificationMeta(
    'renewalDate',
  );
  @override
  late final GeneratedColumn<String> renewalDate = GeneratedColumn<String>(
    'renewal_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _autoKillEnabledMeta = const VerificationMeta(
    'autoKillEnabled',
  );
  @override
  late final GeneratedColumn<bool> autoKillEnabled = GeneratedColumn<bool>(
    'auto_kill_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_kill_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _iconCodePointMeta = const VerificationMeta(
    'iconCodePoint',
  );
  @override
  late final GeneratedColumn<int> iconCodePoint = GeneratedColumn<int>(
    'icon_code_point',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    amount,
    renewalDate,
    autoKillEnabled,
    iconCodePoint,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subscriptions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Subscription> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('renewal_date')) {
      context.handle(
        _renewalDateMeta,
        renewalDate.isAcceptableOrUnknown(
          data['renewal_date']!,
          _renewalDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_renewalDateMeta);
    }
    if (data.containsKey('auto_kill_enabled')) {
      context.handle(
        _autoKillEnabledMeta,
        autoKillEnabled.isAcceptableOrUnknown(
          data['auto_kill_enabled']!,
          _autoKillEnabledMeta,
        ),
      );
    }
    if (data.containsKey('icon_code_point')) {
      context.handle(
        _iconCodePointMeta,
        iconCodePoint.isAcceptableOrUnknown(
          data['icon_code_point']!,
          _iconCodePointMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_iconCodePointMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Subscription map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Subscription(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      renewalDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}renewal_date'],
      )!,
      autoKillEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_kill_enabled'],
      )!,
      iconCodePoint: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}icon_code_point'],
      )!,
    );
  }

  @override
  $SubscriptionsTable createAlias(String alias) {
    return $SubscriptionsTable(attachedDatabase, alias);
  }
}

class Subscription extends DataClass implements Insertable<Subscription> {
  final int id;
  final String name;
  final double amount;
  final String renewalDate;
  final bool autoKillEnabled;
  final int iconCodePoint;
  const Subscription({
    required this.id,
    required this.name,
    required this.amount,
    required this.renewalDate,
    required this.autoKillEnabled,
    required this.iconCodePoint,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['amount'] = Variable<double>(amount);
    map['renewal_date'] = Variable<String>(renewalDate);
    map['auto_kill_enabled'] = Variable<bool>(autoKillEnabled);
    map['icon_code_point'] = Variable<int>(iconCodePoint);
    return map;
  }

  SubscriptionsCompanion toCompanion(bool nullToAbsent) {
    return SubscriptionsCompanion(
      id: Value(id),
      name: Value(name),
      amount: Value(amount),
      renewalDate: Value(renewalDate),
      autoKillEnabled: Value(autoKillEnabled),
      iconCodePoint: Value(iconCodePoint),
    );
  }

  factory Subscription.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Subscription(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      amount: serializer.fromJson<double>(json['amount']),
      renewalDate: serializer.fromJson<String>(json['renewalDate']),
      autoKillEnabled: serializer.fromJson<bool>(json['autoKillEnabled']),
      iconCodePoint: serializer.fromJson<int>(json['iconCodePoint']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'amount': serializer.toJson<double>(amount),
      'renewalDate': serializer.toJson<String>(renewalDate),
      'autoKillEnabled': serializer.toJson<bool>(autoKillEnabled),
      'iconCodePoint': serializer.toJson<int>(iconCodePoint),
    };
  }

  Subscription copyWith({
    int? id,
    String? name,
    double? amount,
    String? renewalDate,
    bool? autoKillEnabled,
    int? iconCodePoint,
  }) => Subscription(
    id: id ?? this.id,
    name: name ?? this.name,
    amount: amount ?? this.amount,
    renewalDate: renewalDate ?? this.renewalDate,
    autoKillEnabled: autoKillEnabled ?? this.autoKillEnabled,
    iconCodePoint: iconCodePoint ?? this.iconCodePoint,
  );
  Subscription copyWithCompanion(SubscriptionsCompanion data) {
    return Subscription(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      amount: data.amount.present ? data.amount.value : this.amount,
      renewalDate: data.renewalDate.present
          ? data.renewalDate.value
          : this.renewalDate,
      autoKillEnabled: data.autoKillEnabled.present
          ? data.autoKillEnabled.value
          : this.autoKillEnabled,
      iconCodePoint: data.iconCodePoint.present
          ? data.iconCodePoint.value
          : this.iconCodePoint,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Subscription(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('renewalDate: $renewalDate, ')
          ..write('autoKillEnabled: $autoKillEnabled, ')
          ..write('iconCodePoint: $iconCodePoint')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    amount,
    renewalDate,
    autoKillEnabled,
    iconCodePoint,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Subscription &&
          other.id == this.id &&
          other.name == this.name &&
          other.amount == this.amount &&
          other.renewalDate == this.renewalDate &&
          other.autoKillEnabled == this.autoKillEnabled &&
          other.iconCodePoint == this.iconCodePoint);
}

class SubscriptionsCompanion extends UpdateCompanion<Subscription> {
  final Value<int> id;
  final Value<String> name;
  final Value<double> amount;
  final Value<String> renewalDate;
  final Value<bool> autoKillEnabled;
  final Value<int> iconCodePoint;
  const SubscriptionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.amount = const Value.absent(),
    this.renewalDate = const Value.absent(),
    this.autoKillEnabled = const Value.absent(),
    this.iconCodePoint = const Value.absent(),
  });
  SubscriptionsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required double amount,
    required String renewalDate,
    this.autoKillEnabled = const Value.absent(),
    required int iconCodePoint,
  }) : name = Value(name),
       amount = Value(amount),
       renewalDate = Value(renewalDate),
       iconCodePoint = Value(iconCodePoint);
  static Insertable<Subscription> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<double>? amount,
    Expression<String>? renewalDate,
    Expression<bool>? autoKillEnabled,
    Expression<int>? iconCodePoint,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (amount != null) 'amount': amount,
      if (renewalDate != null) 'renewal_date': renewalDate,
      if (autoKillEnabled != null) 'auto_kill_enabled': autoKillEnabled,
      if (iconCodePoint != null) 'icon_code_point': iconCodePoint,
    });
  }

  SubscriptionsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<double>? amount,
    Value<String>? renewalDate,
    Value<bool>? autoKillEnabled,
    Value<int>? iconCodePoint,
  }) {
    return SubscriptionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      renewalDate: renewalDate ?? this.renewalDate,
      autoKillEnabled: autoKillEnabled ?? this.autoKillEnabled,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (renewalDate.present) {
      map['renewal_date'] = Variable<String>(renewalDate.value);
    }
    if (autoKillEnabled.present) {
      map['auto_kill_enabled'] = Variable<bool>(autoKillEnabled.value);
    }
    if (iconCodePoint.present) {
      map['icon_code_point'] = Variable<int>(iconCodePoint.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubscriptionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('renewalDate: $renewalDate, ')
          ..write('autoKillEnabled: $autoKillEnabled, ')
          ..write('iconCodePoint: $iconCodePoint')
          ..write(')'))
        .toString();
  }
}

class $IouEntriesTable extends IouEntries
    with TableInfo<$IouEntriesTable, IouEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IouEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _personMeta = const VerificationMeta('person');
  @override
  late final GeneratedColumn<String> person = GeneratedColumn<String>(
    'person',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isSettledMeta = const VerificationMeta(
    'isSettled',
  );
  @override
  late final GeneratedColumn<bool> isSettled = GeneratedColumn<bool>(
    'is_settled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_settled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    person,
    amount,
    type,
    note,
    date,
    isSettled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'iou_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<IouEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('person')) {
      context.handle(
        _personMeta,
        person.isAcceptableOrUnknown(data['person']!, _personMeta),
      );
    } else if (isInserting) {
      context.missing(_personMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    } else if (isInserting) {
      context.missing(_noteMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('is_settled')) {
      context.handle(
        _isSettledMeta,
        isSettled.isAcceptableOrUnknown(data['is_settled']!, _isSettledMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IouEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IouEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      person: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      isSettled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_settled'],
      )!,
    );
  }

  @override
  $IouEntriesTable createAlias(String alias) {
    return $IouEntriesTable(attachedDatabase, alias);
  }
}

class IouEntry extends DataClass implements Insertable<IouEntry> {
  final int id;
  final String person;
  final double amount;
  final String type;
  final String note;
  final String date;
  final bool isSettled;
  const IouEntry({
    required this.id,
    required this.person,
    required this.amount,
    required this.type,
    required this.note,
    required this.date,
    required this.isSettled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['person'] = Variable<String>(person);
    map['amount'] = Variable<double>(amount);
    map['type'] = Variable<String>(type);
    map['note'] = Variable<String>(note);
    map['date'] = Variable<String>(date);
    map['is_settled'] = Variable<bool>(isSettled);
    return map;
  }

  IouEntriesCompanion toCompanion(bool nullToAbsent) {
    return IouEntriesCompanion(
      id: Value(id),
      person: Value(person),
      amount: Value(amount),
      type: Value(type),
      note: Value(note),
      date: Value(date),
      isSettled: Value(isSettled),
    );
  }

  factory IouEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IouEntry(
      id: serializer.fromJson<int>(json['id']),
      person: serializer.fromJson<String>(json['person']),
      amount: serializer.fromJson<double>(json['amount']),
      type: serializer.fromJson<String>(json['type']),
      note: serializer.fromJson<String>(json['note']),
      date: serializer.fromJson<String>(json['date']),
      isSettled: serializer.fromJson<bool>(json['isSettled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'person': serializer.toJson<String>(person),
      'amount': serializer.toJson<double>(amount),
      'type': serializer.toJson<String>(type),
      'note': serializer.toJson<String>(note),
      'date': serializer.toJson<String>(date),
      'isSettled': serializer.toJson<bool>(isSettled),
    };
  }

  IouEntry copyWith({
    int? id,
    String? person,
    double? amount,
    String? type,
    String? note,
    String? date,
    bool? isSettled,
  }) => IouEntry(
    id: id ?? this.id,
    person: person ?? this.person,
    amount: amount ?? this.amount,
    type: type ?? this.type,
    note: note ?? this.note,
    date: date ?? this.date,
    isSettled: isSettled ?? this.isSettled,
  );
  IouEntry copyWithCompanion(IouEntriesCompanion data) {
    return IouEntry(
      id: data.id.present ? data.id.value : this.id,
      person: data.person.present ? data.person.value : this.person,
      amount: data.amount.present ? data.amount.value : this.amount,
      type: data.type.present ? data.type.value : this.type,
      note: data.note.present ? data.note.value : this.note,
      date: data.date.present ? data.date.value : this.date,
      isSettled: data.isSettled.present ? data.isSettled.value : this.isSettled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IouEntry(')
          ..write('id: $id, ')
          ..write('person: $person, ')
          ..write('amount: $amount, ')
          ..write('type: $type, ')
          ..write('note: $note, ')
          ..write('date: $date, ')
          ..write('isSettled: $isSettled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, person, amount, type, note, date, isSettled);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IouEntry &&
          other.id == this.id &&
          other.person == this.person &&
          other.amount == this.amount &&
          other.type == this.type &&
          other.note == this.note &&
          other.date == this.date &&
          other.isSettled == this.isSettled);
}

class IouEntriesCompanion extends UpdateCompanion<IouEntry> {
  final Value<int> id;
  final Value<String> person;
  final Value<double> amount;
  final Value<String> type;
  final Value<String> note;
  final Value<String> date;
  final Value<bool> isSettled;
  const IouEntriesCompanion({
    this.id = const Value.absent(),
    this.person = const Value.absent(),
    this.amount = const Value.absent(),
    this.type = const Value.absent(),
    this.note = const Value.absent(),
    this.date = const Value.absent(),
    this.isSettled = const Value.absent(),
  });
  IouEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String person,
    required double amount,
    required String type,
    required String note,
    required String date,
    this.isSettled = const Value.absent(),
  }) : person = Value(person),
       amount = Value(amount),
       type = Value(type),
       note = Value(note),
       date = Value(date);
  static Insertable<IouEntry> custom({
    Expression<int>? id,
    Expression<String>? person,
    Expression<double>? amount,
    Expression<String>? type,
    Expression<String>? note,
    Expression<String>? date,
    Expression<bool>? isSettled,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (person != null) 'person': person,
      if (amount != null) 'amount': amount,
      if (type != null) 'type': type,
      if (note != null) 'note': note,
      if (date != null) 'date': date,
      if (isSettled != null) 'is_settled': isSettled,
    });
  }

  IouEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? person,
    Value<double>? amount,
    Value<String>? type,
    Value<String>? note,
    Value<String>? date,
    Value<bool>? isSettled,
  }) {
    return IouEntriesCompanion(
      id: id ?? this.id,
      person: person ?? this.person,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      note: note ?? this.note,
      date: date ?? this.date,
      isSettled: isSettled ?? this.isSettled,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (person.present) {
      map['person'] = Variable<String>(person.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (isSettled.present) {
      map['is_settled'] = Variable<bool>(isSettled.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IouEntriesCompanion(')
          ..write('id: $id, ')
          ..write('person: $person, ')
          ..write('amount: $amount, ')
          ..write('type: $type, ')
          ..write('note: $note, ')
          ..write('date: $date, ')
          ..write('isSettled: $isSettled')
          ..write(')'))
        .toString();
  }
}

class $NotesTable extends Notes with TableInfo<$NotesTable, Note> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorValueMeta = const VerificationMeta(
    'colorValue',
  );
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
    'color_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isPinnedMeta = const VerificationMeta(
    'isPinned',
  );
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
    'is_pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    content,
    colorValue,
    isPinned,
    tags,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Note> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('color_value')) {
      context.handle(
        _colorValueMeta,
        colorValue.isAcceptableOrUnknown(data['color_value']!, _colorValueMeta),
      );
    } else if (isInserting) {
      context.missing(_colorValueMeta);
    }
    if (data.containsKey('is_pinned')) {
      context.handle(
        _isPinnedMeta,
        isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Note map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Note(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      colorValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_value'],
      )!,
      isPinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pinned'],
      )!,
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $NotesTable createAlias(String alias) {
    return $NotesTable(attachedDatabase, alias);
  }
}

class Note extends DataClass implements Insertable<Note> {
  final int id;
  final String title;
  final String content;
  final int colorValue;
  final bool isPinned;
  final String tags;
  final String createdAt;
  final String updatedAt;
  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.colorValue,
    required this.isPinned,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['content'] = Variable<String>(content);
    map['color_value'] = Variable<int>(colorValue);
    map['is_pinned'] = Variable<bool>(isPinned);
    map['tags'] = Variable<String>(tags);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      id: Value(id),
      title: Value(title),
      content: Value(content),
      colorValue: Value(colorValue),
      isPinned: Value(isPinned),
      tags: Value(tags),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Note.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Note(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      colorValue: serializer.fromJson<int>(json['colorValue']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      tags: serializer.fromJson<String>(json['tags']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String>(content),
      'colorValue': serializer.toJson<int>(colorValue),
      'isPinned': serializer.toJson<bool>(isPinned),
      'tags': serializer.toJson<String>(tags),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  Note copyWith({
    int? id,
    String? title,
    String? content,
    int? colorValue,
    bool? isPinned,
    String? tags,
    String? createdAt,
    String? updatedAt,
  }) => Note(
    id: id ?? this.id,
    title: title ?? this.title,
    content: content ?? this.content,
    colorValue: colorValue ?? this.colorValue,
    isPinned: isPinned ?? this.isPinned,
    tags: tags ?? this.tags,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Note copyWithCompanion(NotesCompanion data) {
    return Note(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      colorValue: data.colorValue.present
          ? data.colorValue.value
          : this.colorValue,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
      tags: data.tags.present ? data.tags.value : this.tags,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Note(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('colorValue: $colorValue, ')
          ..write('isPinned: $isPinned, ')
          ..write('tags: $tags, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    content,
    colorValue,
    isPinned,
    tags,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Note &&
          other.id == this.id &&
          other.title == this.title &&
          other.content == this.content &&
          other.colorValue == this.colorValue &&
          other.isPinned == this.isPinned &&
          other.tags == this.tags &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class NotesCompanion extends UpdateCompanion<Note> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> content;
  final Value<int> colorValue;
  final Value<bool> isPinned;
  final Value<String> tags;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  const NotesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.tags = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  NotesCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String content,
    required int colorValue,
    this.isPinned = const Value.absent(),
    this.tags = const Value.absent(),
    required String createdAt,
    required String updatedAt,
  }) : title = Value(title),
       content = Value(content),
       colorValue = Value(colorValue),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Note> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? content,
    Expression<int>? colorValue,
    Expression<bool>? isPinned,
    Expression<String>? tags,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (colorValue != null) 'color_value': colorValue,
      if (isPinned != null) 'is_pinned': isPinned,
      if (tags != null) 'tags': tags,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  NotesCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? content,
    Value<int>? colorValue,
    Value<bool>? isPinned,
    Value<String>? tags,
    Value<String>? createdAt,
    Value<String>? updatedAt,
  }) {
    return NotesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      colorValue: colorValue ?? this.colorValue,
      isPinned: isPinned ?? this.isPinned,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('colorValue: $colorValue, ')
          ..write('isPinned: $isPinned, ')
          ..write('tags: $tags, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PlannerItemsTable extends PlannerItems
    with TableInfo<$PlannerItemsTable, PlannerItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlannerItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<String> startTime = GeneratedColumn<String>(
    'start_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<String> endTime = GeneratedColumn<String>(
    'end_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorValueMeta = const VerificationMeta(
    'colorValue',
  );
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
    'color_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconCodePointMeta = const VerificationMeta(
    'iconCodePoint',
  );
  @override
  late final GeneratedColumn<int> iconCodePoint = GeneratedColumn<int>(
    'icon_code_point',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDoneMeta = const VerificationMeta('isDone');
  @override
  late final GeneratedColumn<bool> isDone = GeneratedColumn<bool>(
    'is_done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _repeatTypeMeta = const VerificationMeta(
    'repeatType',
  );
  @override
  late final GeneratedColumn<String> repeatType = GeneratedColumn<String>(
    'repeat_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _repeatDaysMeta = const VerificationMeta(
    'repeatDays',
  );
  @override
  late final GeneratedColumn<String> repeatDays = GeneratedColumn<String>(
    'repeat_days',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<String> endDate = GeneratedColumn<String>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('medium'),
  );
  static const VerificationMeta _reminderOffsetMinutesMeta =
      const VerificationMeta('reminderOffsetMinutes');
  @override
  late final GeneratedColumn<int> reminderOffsetMinutes = GeneratedColumn<int>(
    'reminder_offset_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _checklistJsonMeta = const VerificationMeta(
    'checklistJson',
  );
  @override
  late final GeneratedColumn<String> checklistJson = GeneratedColumn<String>(
    'checklist_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _completedDatesMeta = const VerificationMeta(
    'completedDates',
  );
  @override
  late final GeneratedColumn<String> completedDates = GeneratedColumn<String>(
    'completed_dates',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    date,
    startTime,
    endTime,
    category,
    colorValue,
    iconCodePoint,
    isDone,
    notes,
    repeatType,
    repeatDays,
    endDate,
    priority,
    reminderOffsetMinutes,
    checklistJson,
    completedDates,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'planner_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlannerItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('color_value')) {
      context.handle(
        _colorValueMeta,
        colorValue.isAcceptableOrUnknown(data['color_value']!, _colorValueMeta),
      );
    } else if (isInserting) {
      context.missing(_colorValueMeta);
    }
    if (data.containsKey('icon_code_point')) {
      context.handle(
        _iconCodePointMeta,
        iconCodePoint.isAcceptableOrUnknown(
          data['icon_code_point']!,
          _iconCodePointMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_iconCodePointMeta);
    }
    if (data.containsKey('is_done')) {
      context.handle(
        _isDoneMeta,
        isDone.isAcceptableOrUnknown(data['is_done']!, _isDoneMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('repeat_type')) {
      context.handle(
        _repeatTypeMeta,
        repeatType.isAcceptableOrUnknown(data['repeat_type']!, _repeatTypeMeta),
      );
    }
    if (data.containsKey('repeat_days')) {
      context.handle(
        _repeatDaysMeta,
        repeatDays.isAcceptableOrUnknown(data['repeat_days']!, _repeatDaysMeta),
      );
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('reminder_offset_minutes')) {
      context.handle(
        _reminderOffsetMinutesMeta,
        reminderOffsetMinutes.isAcceptableOrUnknown(
          data['reminder_offset_minutes']!,
          _reminderOffsetMinutesMeta,
        ),
      );
    }
    if (data.containsKey('checklist_json')) {
      context.handle(
        _checklistJsonMeta,
        checklistJson.isAcceptableOrUnknown(
          data['checklist_json']!,
          _checklistJsonMeta,
        ),
      );
    }
    if (data.containsKey('completed_dates')) {
      context.handle(
        _completedDatesMeta,
        completedDates.isAcceptableOrUnknown(
          data['completed_dates']!,
          _completedDatesMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlannerItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlannerItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_time'],
      ),
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_time'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      colorValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_value'],
      )!,
      iconCodePoint: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}icon_code_point'],
      )!,
      isDone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_done'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      repeatType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repeat_type'],
      )!,
      repeatDays: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repeat_days'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_date'],
      ),
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}priority'],
      )!,
      reminderOffsetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_offset_minutes'],
      )!,
      checklistJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checklist_json'],
      )!,
      completedDates: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}completed_dates'],
      )!,
    );
  }

  @override
  $PlannerItemsTable createAlias(String alias) {
    return $PlannerItemsTable(attachedDatabase, alias);
  }
}

class PlannerItem extends DataClass implements Insertable<PlannerItem> {
  final int id;
  final String title;
  final String date;
  final String? startTime;
  final String? endTime;
  final String category;
  final int colorValue;
  final int iconCodePoint;
  final bool isDone;
  final String notes;
  final String repeatType;
  final String repeatDays;
  final String? endDate;
  final String priority;
  final int reminderOffsetMinutes;
  final String checklistJson;
  final String completedDates;
  const PlannerItem({
    required this.id,
    required this.title,
    required this.date,
    this.startTime,
    this.endTime,
    required this.category,
    required this.colorValue,
    required this.iconCodePoint,
    required this.isDone,
    required this.notes,
    required this.repeatType,
    required this.repeatDays,
    this.endDate,
    required this.priority,
    required this.reminderOffsetMinutes,
    required this.checklistJson,
    required this.completedDates,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['date'] = Variable<String>(date);
    if (!nullToAbsent || startTime != null) {
      map['start_time'] = Variable<String>(startTime);
    }
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<String>(endTime);
    }
    map['category'] = Variable<String>(category);
    map['color_value'] = Variable<int>(colorValue);
    map['icon_code_point'] = Variable<int>(iconCodePoint);
    map['is_done'] = Variable<bool>(isDone);
    map['notes'] = Variable<String>(notes);
    map['repeat_type'] = Variable<String>(repeatType);
    map['repeat_days'] = Variable<String>(repeatDays);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<String>(endDate);
    }
    map['priority'] = Variable<String>(priority);
    map['reminder_offset_minutes'] = Variable<int>(reminderOffsetMinutes);
    map['checklist_json'] = Variable<String>(checklistJson);
    map['completed_dates'] = Variable<String>(completedDates);
    return map;
  }

  PlannerItemsCompanion toCompanion(bool nullToAbsent) {
    return PlannerItemsCompanion(
      id: Value(id),
      title: Value(title),
      date: Value(date),
      startTime: startTime == null && nullToAbsent
          ? const Value.absent()
          : Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      category: Value(category),
      colorValue: Value(colorValue),
      iconCodePoint: Value(iconCodePoint),
      isDone: Value(isDone),
      notes: Value(notes),
      repeatType: Value(repeatType),
      repeatDays: Value(repeatDays),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      priority: Value(priority),
      reminderOffsetMinutes: Value(reminderOffsetMinutes),
      checklistJson: Value(checklistJson),
      completedDates: Value(completedDates),
    );
  }

  factory PlannerItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlannerItem(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      date: serializer.fromJson<String>(json['date']),
      startTime: serializer.fromJson<String?>(json['startTime']),
      endTime: serializer.fromJson<String?>(json['endTime']),
      category: serializer.fromJson<String>(json['category']),
      colorValue: serializer.fromJson<int>(json['colorValue']),
      iconCodePoint: serializer.fromJson<int>(json['iconCodePoint']),
      isDone: serializer.fromJson<bool>(json['isDone']),
      notes: serializer.fromJson<String>(json['notes']),
      repeatType: serializer.fromJson<String>(json['repeatType']),
      repeatDays: serializer.fromJson<String>(json['repeatDays']),
      endDate: serializer.fromJson<String?>(json['endDate']),
      priority: serializer.fromJson<String>(json['priority']),
      reminderOffsetMinutes: serializer.fromJson<int>(
        json['reminderOffsetMinutes'],
      ),
      checklistJson: serializer.fromJson<String>(json['checklistJson']),
      completedDates: serializer.fromJson<String>(json['completedDates']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'date': serializer.toJson<String>(date),
      'startTime': serializer.toJson<String?>(startTime),
      'endTime': serializer.toJson<String?>(endTime),
      'category': serializer.toJson<String>(category),
      'colorValue': serializer.toJson<int>(colorValue),
      'iconCodePoint': serializer.toJson<int>(iconCodePoint),
      'isDone': serializer.toJson<bool>(isDone),
      'notes': serializer.toJson<String>(notes),
      'repeatType': serializer.toJson<String>(repeatType),
      'repeatDays': serializer.toJson<String>(repeatDays),
      'endDate': serializer.toJson<String?>(endDate),
      'priority': serializer.toJson<String>(priority),
      'reminderOffsetMinutes': serializer.toJson<int>(reminderOffsetMinutes),
      'checklistJson': serializer.toJson<String>(checklistJson),
      'completedDates': serializer.toJson<String>(completedDates),
    };
  }

  PlannerItem copyWith({
    int? id,
    String? title,
    String? date,
    Value<String?> startTime = const Value.absent(),
    Value<String?> endTime = const Value.absent(),
    String? category,
    int? colorValue,
    int? iconCodePoint,
    bool? isDone,
    String? notes,
    String? repeatType,
    String? repeatDays,
    Value<String?> endDate = const Value.absent(),
    String? priority,
    int? reminderOffsetMinutes,
    String? checklistJson,
    String? completedDates,
  }) => PlannerItem(
    id: id ?? this.id,
    title: title ?? this.title,
    date: date ?? this.date,
    startTime: startTime.present ? startTime.value : this.startTime,
    endTime: endTime.present ? endTime.value : this.endTime,
    category: category ?? this.category,
    colorValue: colorValue ?? this.colorValue,
    iconCodePoint: iconCodePoint ?? this.iconCodePoint,
    isDone: isDone ?? this.isDone,
    notes: notes ?? this.notes,
    repeatType: repeatType ?? this.repeatType,
    repeatDays: repeatDays ?? this.repeatDays,
    endDate: endDate.present ? endDate.value : this.endDate,
    priority: priority ?? this.priority,
    reminderOffsetMinutes: reminderOffsetMinutes ?? this.reminderOffsetMinutes,
    checklistJson: checklistJson ?? this.checklistJson,
    completedDates: completedDates ?? this.completedDates,
  );
  PlannerItem copyWithCompanion(PlannerItemsCompanion data) {
    return PlannerItem(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      date: data.date.present ? data.date.value : this.date,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      category: data.category.present ? data.category.value : this.category,
      colorValue: data.colorValue.present
          ? data.colorValue.value
          : this.colorValue,
      iconCodePoint: data.iconCodePoint.present
          ? data.iconCodePoint.value
          : this.iconCodePoint,
      isDone: data.isDone.present ? data.isDone.value : this.isDone,
      notes: data.notes.present ? data.notes.value : this.notes,
      repeatType: data.repeatType.present
          ? data.repeatType.value
          : this.repeatType,
      repeatDays: data.repeatDays.present
          ? data.repeatDays.value
          : this.repeatDays,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      priority: data.priority.present ? data.priority.value : this.priority,
      reminderOffsetMinutes: data.reminderOffsetMinutes.present
          ? data.reminderOffsetMinutes.value
          : this.reminderOffsetMinutes,
      checklistJson: data.checklistJson.present
          ? data.checklistJson.value
          : this.checklistJson,
      completedDates: data.completedDates.present
          ? data.completedDates.value
          : this.completedDates,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlannerItem(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('date: $date, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('category: $category, ')
          ..write('colorValue: $colorValue, ')
          ..write('iconCodePoint: $iconCodePoint, ')
          ..write('isDone: $isDone, ')
          ..write('notes: $notes, ')
          ..write('repeatType: $repeatType, ')
          ..write('repeatDays: $repeatDays, ')
          ..write('endDate: $endDate, ')
          ..write('priority: $priority, ')
          ..write('reminderOffsetMinutes: $reminderOffsetMinutes, ')
          ..write('checklistJson: $checklistJson, ')
          ..write('completedDates: $completedDates')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    date,
    startTime,
    endTime,
    category,
    colorValue,
    iconCodePoint,
    isDone,
    notes,
    repeatType,
    repeatDays,
    endDate,
    priority,
    reminderOffsetMinutes,
    checklistJson,
    completedDates,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlannerItem &&
          other.id == this.id &&
          other.title == this.title &&
          other.date == this.date &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.category == this.category &&
          other.colorValue == this.colorValue &&
          other.iconCodePoint == this.iconCodePoint &&
          other.isDone == this.isDone &&
          other.notes == this.notes &&
          other.repeatType == this.repeatType &&
          other.repeatDays == this.repeatDays &&
          other.endDate == this.endDate &&
          other.priority == this.priority &&
          other.reminderOffsetMinutes == this.reminderOffsetMinutes &&
          other.checklistJson == this.checklistJson &&
          other.completedDates == this.completedDates);
}

class PlannerItemsCompanion extends UpdateCompanion<PlannerItem> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> date;
  final Value<String?> startTime;
  final Value<String?> endTime;
  final Value<String> category;
  final Value<int> colorValue;
  final Value<int> iconCodePoint;
  final Value<bool> isDone;
  final Value<String> notes;
  final Value<String> repeatType;
  final Value<String> repeatDays;
  final Value<String?> endDate;
  final Value<String> priority;
  final Value<int> reminderOffsetMinutes;
  final Value<String> checklistJson;
  final Value<String> completedDates;
  const PlannerItemsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.date = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.category = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.iconCodePoint = const Value.absent(),
    this.isDone = const Value.absent(),
    this.notes = const Value.absent(),
    this.repeatType = const Value.absent(),
    this.repeatDays = const Value.absent(),
    this.endDate = const Value.absent(),
    this.priority = const Value.absent(),
    this.reminderOffsetMinutes = const Value.absent(),
    this.checklistJson = const Value.absent(),
    this.completedDates = const Value.absent(),
  });
  PlannerItemsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String date,
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    required String category,
    required int colorValue,
    required int iconCodePoint,
    this.isDone = const Value.absent(),
    this.notes = const Value.absent(),
    this.repeatType = const Value.absent(),
    this.repeatDays = const Value.absent(),
    this.endDate = const Value.absent(),
    this.priority = const Value.absent(),
    this.reminderOffsetMinutes = const Value.absent(),
    this.checklistJson = const Value.absent(),
    this.completedDates = const Value.absent(),
  }) : title = Value(title),
       date = Value(date),
       category = Value(category),
       colorValue = Value(colorValue),
       iconCodePoint = Value(iconCodePoint);
  static Insertable<PlannerItem> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? date,
    Expression<String>? startTime,
    Expression<String>? endTime,
    Expression<String>? category,
    Expression<int>? colorValue,
    Expression<int>? iconCodePoint,
    Expression<bool>? isDone,
    Expression<String>? notes,
    Expression<String>? repeatType,
    Expression<String>? repeatDays,
    Expression<String>? endDate,
    Expression<String>? priority,
    Expression<int>? reminderOffsetMinutes,
    Expression<String>? checklistJson,
    Expression<String>? completedDates,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (date != null) 'date': date,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (category != null) 'category': category,
      if (colorValue != null) 'color_value': colorValue,
      if (iconCodePoint != null) 'icon_code_point': iconCodePoint,
      if (isDone != null) 'is_done': isDone,
      if (notes != null) 'notes': notes,
      if (repeatType != null) 'repeat_type': repeatType,
      if (repeatDays != null) 'repeat_days': repeatDays,
      if (endDate != null) 'end_date': endDate,
      if (priority != null) 'priority': priority,
      if (reminderOffsetMinutes != null)
        'reminder_offset_minutes': reminderOffsetMinutes,
      if (checklistJson != null) 'checklist_json': checklistJson,
      if (completedDates != null) 'completed_dates': completedDates,
    });
  }

  PlannerItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? date,
    Value<String?>? startTime,
    Value<String?>? endTime,
    Value<String>? category,
    Value<int>? colorValue,
    Value<int>? iconCodePoint,
    Value<bool>? isDone,
    Value<String>? notes,
    Value<String>? repeatType,
    Value<String>? repeatDays,
    Value<String?>? endDate,
    Value<String>? priority,
    Value<int>? reminderOffsetMinutes,
    Value<String>? checklistJson,
    Value<String>? completedDates,
  }) {
    return PlannerItemsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      category: category ?? this.category,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      isDone: isDone ?? this.isDone,
      notes: notes ?? this.notes,
      repeatType: repeatType ?? this.repeatType,
      repeatDays: repeatDays ?? this.repeatDays,
      endDate: endDate ?? this.endDate,
      priority: priority ?? this.priority,
      reminderOffsetMinutes:
          reminderOffsetMinutes ?? this.reminderOffsetMinutes,
      checklistJson: checklistJson ?? this.checklistJson,
      completedDates: completedDates ?? this.completedDates,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<String>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<String>(endTime.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (iconCodePoint.present) {
      map['icon_code_point'] = Variable<int>(iconCodePoint.value);
    }
    if (isDone.present) {
      map['is_done'] = Variable<bool>(isDone.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (repeatType.present) {
      map['repeat_type'] = Variable<String>(repeatType.value);
    }
    if (repeatDays.present) {
      map['repeat_days'] = Variable<String>(repeatDays.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(endDate.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (reminderOffsetMinutes.present) {
      map['reminder_offset_minutes'] = Variable<int>(
        reminderOffsetMinutes.value,
      );
    }
    if (checklistJson.present) {
      map['checklist_json'] = Variable<String>(checklistJson.value);
    }
    if (completedDates.present) {
      map['completed_dates'] = Variable<String>(completedDates.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlannerItemsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('date: $date, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('category: $category, ')
          ..write('colorValue: $colorValue, ')
          ..write('iconCodePoint: $iconCodePoint, ')
          ..write('isDone: $isDone, ')
          ..write('notes: $notes, ')
          ..write('repeatType: $repeatType, ')
          ..write('repeatDays: $repeatDays, ')
          ..write('endDate: $endDate, ')
          ..write('priority: $priority, ')
          ..write('reminderOffsetMinutes: $reminderOffsetMinutes, ')
          ..write('checklistJson: $checklistJson, ')
          ..write('completedDates: $completedDates')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $HabitsTable habits = $HabitsTable(this);
  late final $TimelineItemsTable timelineItems = $TimelineItemsTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $BudgetSettingsTable budgetSettings = $BudgetSettingsTable(this);
  late final $SubscriptionsTable subscriptions = $SubscriptionsTable(this);
  late final $IouEntriesTable iouEntries = $IouEntriesTable(this);
  late final $NotesTable notes = $NotesTable(this);
  late final $PlannerItemsTable plannerItems = $PlannerItemsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    habits,
    timelineItems,
    transactions,
    budgetSettings,
    subscriptions,
    iouEntries,
    notes,
    plannerItems,
  ];
}

typedef $$HabitsTableCreateCompanionBuilder =
    HabitsCompanion Function({
      Value<int> id,
      required String title,
      required int iconCodePoint,
      required int colorValue,
      Value<int> streakDays,
      Value<bool> isDoneToday,
      Value<String?> lastCompletedDate,
      required String createdAt,
    });
typedef $$HabitsTableUpdateCompanionBuilder =
    HabitsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<int> iconCodePoint,
      Value<int> colorValue,
      Value<int> streakDays,
      Value<bool> isDoneToday,
      Value<String?> lastCompletedDate,
      Value<String> createdAt,
    });

class $$HabitsTableFilterComposer
    extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get iconCodePoint => $composableBuilder(
    column: $table.iconCodePoint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get streakDays => $composableBuilder(
    column: $table.streakDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDoneToday => $composableBuilder(
    column: $table.isDoneToday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastCompletedDate => $composableBuilder(
    column: $table.lastCompletedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HabitsTableOrderingComposer
    extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get iconCodePoint => $composableBuilder(
    column: $table.iconCodePoint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get streakDays => $composableBuilder(
    column: $table.streakDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDoneToday => $composableBuilder(
    column: $table.isDoneToday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastCompletedDate => $composableBuilder(
    column: $table.lastCompletedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HabitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get iconCodePoint => $composableBuilder(
    column: $table.iconCodePoint,
    builder: (column) => column,
  );

  GeneratedColumn<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => column,
  );

  GeneratedColumn<int> get streakDays => $composableBuilder(
    column: $table.streakDays,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDoneToday => $composableBuilder(
    column: $table.isDoneToday,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastCompletedDate => $composableBuilder(
    column: $table.lastCompletedDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$HabitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HabitsTable,
          Habit,
          $$HabitsTableFilterComposer,
          $$HabitsTableOrderingComposer,
          $$HabitsTableAnnotationComposer,
          $$HabitsTableCreateCompanionBuilder,
          $$HabitsTableUpdateCompanionBuilder,
          (Habit, BaseReferences<_$AppDatabase, $HabitsTable, Habit>),
          Habit,
          PrefetchHooks Function()
        > {
  $$HabitsTableTableManager(_$AppDatabase db, $HabitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> iconCodePoint = const Value.absent(),
                Value<int> colorValue = const Value.absent(),
                Value<int> streakDays = const Value.absent(),
                Value<bool> isDoneToday = const Value.absent(),
                Value<String?> lastCompletedDate = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
              }) => HabitsCompanion(
                id: id,
                title: title,
                iconCodePoint: iconCodePoint,
                colorValue: colorValue,
                streakDays: streakDays,
                isDoneToday: isDoneToday,
                lastCompletedDate: lastCompletedDate,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required int iconCodePoint,
                required int colorValue,
                Value<int> streakDays = const Value.absent(),
                Value<bool> isDoneToday = const Value.absent(),
                Value<String?> lastCompletedDate = const Value.absent(),
                required String createdAt,
              }) => HabitsCompanion.insert(
                id: id,
                title: title,
                iconCodePoint: iconCodePoint,
                colorValue: colorValue,
                streakDays: streakDays,
                isDoneToday: isDoneToday,
                lastCompletedDate: lastCompletedDate,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HabitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HabitsTable,
      Habit,
      $$HabitsTableFilterComposer,
      $$HabitsTableOrderingComposer,
      $$HabitsTableAnnotationComposer,
      $$HabitsTableCreateCompanionBuilder,
      $$HabitsTableUpdateCompanionBuilder,
      (Habit, BaseReferences<_$AppDatabase, $HabitsTable, Habit>),
      Habit,
      PrefetchHooks Function()
    >;
typedef $$TimelineItemsTableCreateCompanionBuilder =
    TimelineItemsCompanion Function({
      Value<int> id,
      required String time,
      required String title,
      required String category,
      required int colorValue,
      required int iconCodePoint,
      Value<bool> isDone,
      required String action,
      required String date,
    });
typedef $$TimelineItemsTableUpdateCompanionBuilder =
    TimelineItemsCompanion Function({
      Value<int> id,
      Value<String> time,
      Value<String> title,
      Value<String> category,
      Value<int> colorValue,
      Value<int> iconCodePoint,
      Value<bool> isDone,
      Value<String> action,
      Value<String> date,
    });

class $$TimelineItemsTableFilterComposer
    extends Composer<_$AppDatabase, $TimelineItemsTable> {
  $$TimelineItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get iconCodePoint => $composableBuilder(
    column: $table.iconCodePoint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDone => $composableBuilder(
    column: $table.isDone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TimelineItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $TimelineItemsTable> {
  $$TimelineItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get iconCodePoint => $composableBuilder(
    column: $table.iconCodePoint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDone => $composableBuilder(
    column: $table.isDone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TimelineItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TimelineItemsTable> {
  $$TimelineItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get time =>
      $composableBuilder(column: $table.time, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => column,
  );

  GeneratedColumn<int> get iconCodePoint => $composableBuilder(
    column: $table.iconCodePoint,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDone =>
      $composableBuilder(column: $table.isDone, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);
}

class $$TimelineItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TimelineItemsTable,
          TimelineItem,
          $$TimelineItemsTableFilterComposer,
          $$TimelineItemsTableOrderingComposer,
          $$TimelineItemsTableAnnotationComposer,
          $$TimelineItemsTableCreateCompanionBuilder,
          $$TimelineItemsTableUpdateCompanionBuilder,
          (
            TimelineItem,
            BaseReferences<_$AppDatabase, $TimelineItemsTable, TimelineItem>,
          ),
          TimelineItem,
          PrefetchHooks Function()
        > {
  $$TimelineItemsTableTableManager(_$AppDatabase db, $TimelineItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimelineItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TimelineItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TimelineItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> time = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> colorValue = const Value.absent(),
                Value<int> iconCodePoint = const Value.absent(),
                Value<bool> isDone = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String> date = const Value.absent(),
              }) => TimelineItemsCompanion(
                id: id,
                time: time,
                title: title,
                category: category,
                colorValue: colorValue,
                iconCodePoint: iconCodePoint,
                isDone: isDone,
                action: action,
                date: date,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String time,
                required String title,
                required String category,
                required int colorValue,
                required int iconCodePoint,
                Value<bool> isDone = const Value.absent(),
                required String action,
                required String date,
              }) => TimelineItemsCompanion.insert(
                id: id,
                time: time,
                title: title,
                category: category,
                colorValue: colorValue,
                iconCodePoint: iconCodePoint,
                isDone: isDone,
                action: action,
                date: date,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TimelineItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TimelineItemsTable,
      TimelineItem,
      $$TimelineItemsTableFilterComposer,
      $$TimelineItemsTableOrderingComposer,
      $$TimelineItemsTableAnnotationComposer,
      $$TimelineItemsTableCreateCompanionBuilder,
      $$TimelineItemsTableUpdateCompanionBuilder,
      (
        TimelineItem,
        BaseReferences<_$AppDatabase, $TimelineItemsTable, TimelineItem>,
      ),
      TimelineItem,
      PrefetchHooks Function()
    >;
typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> id,
      required String title,
      required String category,
      required double amount,
      required String mode,
      required int iconCodePoint,
      required String date,
      Value<String> type,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> category,
      Value<double> amount,
      Value<String> mode,
      Value<int> iconCodePoint,
      Value<String> date,
      Value<String> type,
    });

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get iconCodePoint => $composableBuilder(
    column: $table.iconCodePoint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get iconCodePoint => $composableBuilder(
    column: $table.iconCodePoint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<int> get iconCodePoint => $composableBuilder(
    column: $table.iconCodePoint,
    builder: (column) => column,
  );

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          Transaction,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (
            Transaction,
            BaseReferences<_$AppDatabase, $TransactionsTable, Transaction>,
          ),
          Transaction,
          PrefetchHooks Function()
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<int> iconCodePoint = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> type = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                title: title,
                category: category,
                amount: amount,
                mode: mode,
                iconCodePoint: iconCodePoint,
                date: date,
                type: type,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required String category,
                required double amount,
                required String mode,
                required int iconCodePoint,
                required String date,
                Value<String> type = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                title: title,
                category: category,
                amount: amount,
                mode: mode,
                iconCodePoint: iconCodePoint,
                date: date,
                type: type,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      Transaction,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (
        Transaction,
        BaseReferences<_$AppDatabase, $TransactionsTable, Transaction>,
      ),
      Transaction,
      PrefetchHooks Function()
    >;
typedef $$BudgetSettingsTableCreateCompanionBuilder =
    BudgetSettingsCompanion Function({
      Value<int> id,
      Value<double> monthlyBudget,
      Value<double> fixedBills,
    });
typedef $$BudgetSettingsTableUpdateCompanionBuilder =
    BudgetSettingsCompanion Function({
      Value<int> id,
      Value<double> monthlyBudget,
      Value<double> fixedBills,
    });

class $$BudgetSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetSettingsTable> {
  $$BudgetSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get monthlyBudget => $composableBuilder(
    column: $table.monthlyBudget,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fixedBills => $composableBuilder(
    column: $table.fixedBills,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BudgetSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetSettingsTable> {
  $$BudgetSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get monthlyBudget => $composableBuilder(
    column: $table.monthlyBudget,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fixedBills => $composableBuilder(
    column: $table.fixedBills,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BudgetSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetSettingsTable> {
  $$BudgetSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get monthlyBudget => $composableBuilder(
    column: $table.monthlyBudget,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fixedBills => $composableBuilder(
    column: $table.fixedBills,
    builder: (column) => column,
  );
}

class $$BudgetSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BudgetSettingsTable,
          BudgetSetting,
          $$BudgetSettingsTableFilterComposer,
          $$BudgetSettingsTableOrderingComposer,
          $$BudgetSettingsTableAnnotationComposer,
          $$BudgetSettingsTableCreateCompanionBuilder,
          $$BudgetSettingsTableUpdateCompanionBuilder,
          (
            BudgetSetting,
            BaseReferences<_$AppDatabase, $BudgetSettingsTable, BudgetSetting>,
          ),
          BudgetSetting,
          PrefetchHooks Function()
        > {
  $$BudgetSettingsTableTableManager(
    _$AppDatabase db,
    $BudgetSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double> monthlyBudget = const Value.absent(),
                Value<double> fixedBills = const Value.absent(),
              }) => BudgetSettingsCompanion(
                id: id,
                monthlyBudget: monthlyBudget,
                fixedBills: fixedBills,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double> monthlyBudget = const Value.absent(),
                Value<double> fixedBills = const Value.absent(),
              }) => BudgetSettingsCompanion.insert(
                id: id,
                monthlyBudget: monthlyBudget,
                fixedBills: fixedBills,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BudgetSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BudgetSettingsTable,
      BudgetSetting,
      $$BudgetSettingsTableFilterComposer,
      $$BudgetSettingsTableOrderingComposer,
      $$BudgetSettingsTableAnnotationComposer,
      $$BudgetSettingsTableCreateCompanionBuilder,
      $$BudgetSettingsTableUpdateCompanionBuilder,
      (
        BudgetSetting,
        BaseReferences<_$AppDatabase, $BudgetSettingsTable, BudgetSetting>,
      ),
      BudgetSetting,
      PrefetchHooks Function()
    >;
typedef $$SubscriptionsTableCreateCompanionBuilder =
    SubscriptionsCompanion Function({
      Value<int> id,
      required String name,
      required double amount,
      required String renewalDate,
      Value<bool> autoKillEnabled,
      required int iconCodePoint,
    });
typedef $$SubscriptionsTableUpdateCompanionBuilder =
    SubscriptionsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<double> amount,
      Value<String> renewalDate,
      Value<bool> autoKillEnabled,
      Value<int> iconCodePoint,
    });

class $$SubscriptionsTableFilterComposer
    extends Composer<_$AppDatabase, $SubscriptionsTable> {
  $$SubscriptionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get renewalDate => $composableBuilder(
    column: $table.renewalDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoKillEnabled => $composableBuilder(
    column: $table.autoKillEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get iconCodePoint => $composableBuilder(
    column: $table.iconCodePoint,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SubscriptionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SubscriptionsTable> {
  $$SubscriptionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get renewalDate => $composableBuilder(
    column: $table.renewalDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoKillEnabled => $composableBuilder(
    column: $table.autoKillEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get iconCodePoint => $composableBuilder(
    column: $table.iconCodePoint,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SubscriptionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubscriptionsTable> {
  $$SubscriptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get renewalDate => $composableBuilder(
    column: $table.renewalDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get autoKillEnabled => $composableBuilder(
    column: $table.autoKillEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get iconCodePoint => $composableBuilder(
    column: $table.iconCodePoint,
    builder: (column) => column,
  );
}

class $$SubscriptionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SubscriptionsTable,
          Subscription,
          $$SubscriptionsTableFilterComposer,
          $$SubscriptionsTableOrderingComposer,
          $$SubscriptionsTableAnnotationComposer,
          $$SubscriptionsTableCreateCompanionBuilder,
          $$SubscriptionsTableUpdateCompanionBuilder,
          (
            Subscription,
            BaseReferences<_$AppDatabase, $SubscriptionsTable, Subscription>,
          ),
          Subscription,
          PrefetchHooks Function()
        > {
  $$SubscriptionsTableTableManager(_$AppDatabase db, $SubscriptionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubscriptionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubscriptionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubscriptionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> renewalDate = const Value.absent(),
                Value<bool> autoKillEnabled = const Value.absent(),
                Value<int> iconCodePoint = const Value.absent(),
              }) => SubscriptionsCompanion(
                id: id,
                name: name,
                amount: amount,
                renewalDate: renewalDate,
                autoKillEnabled: autoKillEnabled,
                iconCodePoint: iconCodePoint,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required double amount,
                required String renewalDate,
                Value<bool> autoKillEnabled = const Value.absent(),
                required int iconCodePoint,
              }) => SubscriptionsCompanion.insert(
                id: id,
                name: name,
                amount: amount,
                renewalDate: renewalDate,
                autoKillEnabled: autoKillEnabled,
                iconCodePoint: iconCodePoint,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SubscriptionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SubscriptionsTable,
      Subscription,
      $$SubscriptionsTableFilterComposer,
      $$SubscriptionsTableOrderingComposer,
      $$SubscriptionsTableAnnotationComposer,
      $$SubscriptionsTableCreateCompanionBuilder,
      $$SubscriptionsTableUpdateCompanionBuilder,
      (
        Subscription,
        BaseReferences<_$AppDatabase, $SubscriptionsTable, Subscription>,
      ),
      Subscription,
      PrefetchHooks Function()
    >;
typedef $$IouEntriesTableCreateCompanionBuilder =
    IouEntriesCompanion Function({
      Value<int> id,
      required String person,
      required double amount,
      required String type,
      required String note,
      required String date,
      Value<bool> isSettled,
    });
typedef $$IouEntriesTableUpdateCompanionBuilder =
    IouEntriesCompanion Function({
      Value<int> id,
      Value<String> person,
      Value<double> amount,
      Value<String> type,
      Value<String> note,
      Value<String> date,
      Value<bool> isSettled,
    });

class $$IouEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $IouEntriesTable> {
  $$IouEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get person => $composableBuilder(
    column: $table.person,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSettled => $composableBuilder(
    column: $table.isSettled,
    builder: (column) => ColumnFilters(column),
  );
}

class $$IouEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $IouEntriesTable> {
  $$IouEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get person => $composableBuilder(
    column: $table.person,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSettled => $composableBuilder(
    column: $table.isSettled,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IouEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $IouEntriesTable> {
  $$IouEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get person =>
      $composableBuilder(column: $table.person, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<bool> get isSettled =>
      $composableBuilder(column: $table.isSettled, builder: (column) => column);
}

class $$IouEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IouEntriesTable,
          IouEntry,
          $$IouEntriesTableFilterComposer,
          $$IouEntriesTableOrderingComposer,
          $$IouEntriesTableAnnotationComposer,
          $$IouEntriesTableCreateCompanionBuilder,
          $$IouEntriesTableUpdateCompanionBuilder,
          (IouEntry, BaseReferences<_$AppDatabase, $IouEntriesTable, IouEntry>),
          IouEntry,
          PrefetchHooks Function()
        > {
  $$IouEntriesTableTableManager(_$AppDatabase db, $IouEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IouEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IouEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IouEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> person = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<bool> isSettled = const Value.absent(),
              }) => IouEntriesCompanion(
                id: id,
                person: person,
                amount: amount,
                type: type,
                note: note,
                date: date,
                isSettled: isSettled,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String person,
                required double amount,
                required String type,
                required String note,
                required String date,
                Value<bool> isSettled = const Value.absent(),
              }) => IouEntriesCompanion.insert(
                id: id,
                person: person,
                amount: amount,
                type: type,
                note: note,
                date: date,
                isSettled: isSettled,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IouEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IouEntriesTable,
      IouEntry,
      $$IouEntriesTableFilterComposer,
      $$IouEntriesTableOrderingComposer,
      $$IouEntriesTableAnnotationComposer,
      $$IouEntriesTableCreateCompanionBuilder,
      $$IouEntriesTableUpdateCompanionBuilder,
      (IouEntry, BaseReferences<_$AppDatabase, $IouEntriesTable, IouEntry>),
      IouEntry,
      PrefetchHooks Function()
    >;
typedef $$NotesTableCreateCompanionBuilder =
    NotesCompanion Function({
      Value<int> id,
      required String title,
      required String content,
      required int colorValue,
      Value<bool> isPinned,
      Value<String> tags,
      required String createdAt,
      required String updatedAt,
    });
typedef $$NotesTableUpdateCompanionBuilder =
    NotesCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> content,
      Value<int> colorValue,
      Value<bool> isPinned,
      Value<String> tags,
      Value<String> createdAt,
      Value<String> updatedAt,
    });

class $$NotesTableFilterComposer extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotesTableOrderingComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$NotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotesTable,
          Note,
          $$NotesTableFilterComposer,
          $$NotesTableOrderingComposer,
          $$NotesTableAnnotationComposer,
          $$NotesTableCreateCompanionBuilder,
          $$NotesTableUpdateCompanionBuilder,
          (Note, BaseReferences<_$AppDatabase, $NotesTable, Note>),
          Note,
          PrefetchHooks Function()
        > {
  $$NotesTableTableManager(_$AppDatabase db, $NotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<int> colorValue = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
              }) => NotesCompanion(
                id: id,
                title: title,
                content: content,
                colorValue: colorValue,
                isPinned: isPinned,
                tags: tags,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required String content,
                required int colorValue,
                Value<bool> isPinned = const Value.absent(),
                Value<String> tags = const Value.absent(),
                required String createdAt,
                required String updatedAt,
              }) => NotesCompanion.insert(
                id: id,
                title: title,
                content: content,
                colorValue: colorValue,
                isPinned: isPinned,
                tags: tags,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotesTable,
      Note,
      $$NotesTableFilterComposer,
      $$NotesTableOrderingComposer,
      $$NotesTableAnnotationComposer,
      $$NotesTableCreateCompanionBuilder,
      $$NotesTableUpdateCompanionBuilder,
      (Note, BaseReferences<_$AppDatabase, $NotesTable, Note>),
      Note,
      PrefetchHooks Function()
    >;
typedef $$PlannerItemsTableCreateCompanionBuilder =
    PlannerItemsCompanion Function({
      Value<int> id,
      required String title,
      required String date,
      Value<String?> startTime,
      Value<String?> endTime,
      required String category,
      required int colorValue,
      required int iconCodePoint,
      Value<bool> isDone,
      Value<String> notes,
      Value<String> repeatType,
      Value<String> repeatDays,
      Value<String?> endDate,
      Value<String> priority,
      Value<int> reminderOffsetMinutes,
      Value<String> checklistJson,
      Value<String> completedDates,
    });
typedef $$PlannerItemsTableUpdateCompanionBuilder =
    PlannerItemsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> date,
      Value<String?> startTime,
      Value<String?> endTime,
      Value<String> category,
      Value<int> colorValue,
      Value<int> iconCodePoint,
      Value<bool> isDone,
      Value<String> notes,
      Value<String> repeatType,
      Value<String> repeatDays,
      Value<String?> endDate,
      Value<String> priority,
      Value<int> reminderOffsetMinutes,
      Value<String> checklistJson,
      Value<String> completedDates,
    });

class $$PlannerItemsTableFilterComposer
    extends Composer<_$AppDatabase, $PlannerItemsTable> {
  $$PlannerItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get iconCodePoint => $composableBuilder(
    column: $table.iconCodePoint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDone => $composableBuilder(
    column: $table.isDone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repeatType => $composableBuilder(
    column: $table.repeatType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repeatDays => $composableBuilder(
    column: $table.repeatDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderOffsetMinutes => $composableBuilder(
    column: $table.reminderOffsetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checklistJson => $composableBuilder(
    column: $table.checklistJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get completedDates => $composableBuilder(
    column: $table.completedDates,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlannerItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlannerItemsTable> {
  $$PlannerItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get iconCodePoint => $composableBuilder(
    column: $table.iconCodePoint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDone => $composableBuilder(
    column: $table.isDone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repeatType => $composableBuilder(
    column: $table.repeatType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repeatDays => $composableBuilder(
    column: $table.repeatDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderOffsetMinutes => $composableBuilder(
    column: $table.reminderOffsetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checklistJson => $composableBuilder(
    column: $table.checklistJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get completedDates => $composableBuilder(
    column: $table.completedDates,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlannerItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlannerItemsTable> {
  $$PlannerItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<String> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => column,
  );

  GeneratedColumn<int> get iconCodePoint => $composableBuilder(
    column: $table.iconCodePoint,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDone =>
      $composableBuilder(column: $table.isDone, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get repeatType => $composableBuilder(
    column: $table.repeatType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get repeatDays => $composableBuilder(
    column: $table.repeatDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<int> get reminderOffsetMinutes => $composableBuilder(
    column: $table.reminderOffsetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get checklistJson => $composableBuilder(
    column: $table.checklistJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get completedDates => $composableBuilder(
    column: $table.completedDates,
    builder: (column) => column,
  );
}

class $$PlannerItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlannerItemsTable,
          PlannerItem,
          $$PlannerItemsTableFilterComposer,
          $$PlannerItemsTableOrderingComposer,
          $$PlannerItemsTableAnnotationComposer,
          $$PlannerItemsTableCreateCompanionBuilder,
          $$PlannerItemsTableUpdateCompanionBuilder,
          (
            PlannerItem,
            BaseReferences<_$AppDatabase, $PlannerItemsTable, PlannerItem>,
          ),
          PlannerItem,
          PrefetchHooks Function()
        > {
  $$PlannerItemsTableTableManager(_$AppDatabase db, $PlannerItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlannerItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlannerItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlannerItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String?> startTime = const Value.absent(),
                Value<String?> endTime = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> colorValue = const Value.absent(),
                Value<int> iconCodePoint = const Value.absent(),
                Value<bool> isDone = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String> repeatType = const Value.absent(),
                Value<String> repeatDays = const Value.absent(),
                Value<String?> endDate = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<int> reminderOffsetMinutes = const Value.absent(),
                Value<String> checklistJson = const Value.absent(),
                Value<String> completedDates = const Value.absent(),
              }) => PlannerItemsCompanion(
                id: id,
                title: title,
                date: date,
                startTime: startTime,
                endTime: endTime,
                category: category,
                colorValue: colorValue,
                iconCodePoint: iconCodePoint,
                isDone: isDone,
                notes: notes,
                repeatType: repeatType,
                repeatDays: repeatDays,
                endDate: endDate,
                priority: priority,
                reminderOffsetMinutes: reminderOffsetMinutes,
                checklistJson: checklistJson,
                completedDates: completedDates,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required String date,
                Value<String?> startTime = const Value.absent(),
                Value<String?> endTime = const Value.absent(),
                required String category,
                required int colorValue,
                required int iconCodePoint,
                Value<bool> isDone = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String> repeatType = const Value.absent(),
                Value<String> repeatDays = const Value.absent(),
                Value<String?> endDate = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<int> reminderOffsetMinutes = const Value.absent(),
                Value<String> checklistJson = const Value.absent(),
                Value<String> completedDates = const Value.absent(),
              }) => PlannerItemsCompanion.insert(
                id: id,
                title: title,
                date: date,
                startTime: startTime,
                endTime: endTime,
                category: category,
                colorValue: colorValue,
                iconCodePoint: iconCodePoint,
                isDone: isDone,
                notes: notes,
                repeatType: repeatType,
                repeatDays: repeatDays,
                endDate: endDate,
                priority: priority,
                reminderOffsetMinutes: reminderOffsetMinutes,
                checklistJson: checklistJson,
                completedDates: completedDates,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlannerItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlannerItemsTable,
      PlannerItem,
      $$PlannerItemsTableFilterComposer,
      $$PlannerItemsTableOrderingComposer,
      $$PlannerItemsTableAnnotationComposer,
      $$PlannerItemsTableCreateCompanionBuilder,
      $$PlannerItemsTableUpdateCompanionBuilder,
      (
        PlannerItem,
        BaseReferences<_$AppDatabase, $PlannerItemsTable, PlannerItem>,
      ),
      PlannerItem,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$HabitsTableTableManager get habits =>
      $$HabitsTableTableManager(_db, _db.habits);
  $$TimelineItemsTableTableManager get timelineItems =>
      $$TimelineItemsTableTableManager(_db, _db.timelineItems);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$BudgetSettingsTableTableManager get budgetSettings =>
      $$BudgetSettingsTableTableManager(_db, _db.budgetSettings);
  $$SubscriptionsTableTableManager get subscriptions =>
      $$SubscriptionsTableTableManager(_db, _db.subscriptions);
  $$IouEntriesTableTableManager get iouEntries =>
      $$IouEntriesTableTableManager(_db, _db.iouEntries);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db, _db.notes);
  $$PlannerItemsTableTableManager get plannerItems =>
      $$PlannerItemsTableTableManager(_db, _db.plannerItems);
}
