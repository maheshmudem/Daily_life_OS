import '../../../../core/database/app_database.dart';
import '../../domain/entities/subscription_entity.dart';

class SubscriptionModel extends SubscriptionEntity {
  const SubscriptionModel({
    required super.id,
    required super.name,
    required super.amount,
    required super.renewalDate,
    required super.autoKillEnabled,
    required super.iconCodePoint,
  });

  factory SubscriptionModel.fromDrift(Subscription row) {
    return SubscriptionModel(
      id: row.id,
      name: row.name,
      amount: row.amount,
      renewalDate: row.renewalDate,
      autoKillEnabled: row.autoKillEnabled,
      iconCodePoint: row.iconCodePoint,
    );
  }

  factory SubscriptionModel.fromEntity(SubscriptionEntity entity) {
    return SubscriptionModel(
      id: entity.id,
      name: entity.name,
      amount: entity.amount,
      renewalDate: entity.renewalDate,
      autoKillEnabled: entity.autoKillEnabled,
      iconCodePoint: entity.iconCodePoint,
    );
  }
}

class IouModel extends IouEntity {
  const IouModel({
    required super.id,
    required super.person,
    required super.amount,
    required super.type,
    required super.note,
    required super.date,
    required super.isSettled,
  });

  factory IouModel.fromDrift(IouEntry row) {
    return IouModel(
      id: row.id,
      person: row.person,
      amount: row.amount,
      type: row.type,
      note: row.note,
      date: row.date,
      isSettled: row.isSettled,
    );
  }

  factory IouModel.fromEntity(IouEntity entity) {
    return IouModel(
      id: entity.id,
      person: entity.person,
      amount: entity.amount,
      type: entity.type,
      note: entity.note,
      date: entity.date,
      isSettled: entity.isSettled,
    );
  }
}
