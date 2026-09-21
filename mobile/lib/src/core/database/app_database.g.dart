// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $RequestMatchRowsTable extends RequestMatchRows
    with TableInfo<$RequestMatchRowsTable, RequestMatchRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RequestMatchRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bloodRequestIdMeta = const VerificationMeta(
    'bloodRequestId',
  );
  @override
  late final GeneratedColumn<String> bloodRequestId = GeneratedColumn<String>(
    'blood_request_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _responseMeta = const VerificationMeta(
    'response',
  );
  @override
  late final GeneratedColumn<String> response = GeneratedColumn<String>(
    'response',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _respondedAtMeta = const VerificationMeta(
    'respondedAt',
  );
  @override
  late final GeneratedColumn<DateTime> respondedAt = GeneratedColumn<DateTime>(
    'responded_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPendingMeta = const VerificationMeta(
    'isPending',
  );
  @override
  late final GeneratedColumn<bool> isPending = GeneratedColumn<bool>(
    'is_pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pending" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _rejectedReasonMeta = const VerificationMeta(
    'rejectedReason',
  );
  @override
  late final GeneratedColumn<String> rejectedReason = GeneratedColumn<String>(
    'rejected_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bloodRequestId,
    response,
    respondedAt,
    isPending,
    rejectedReason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'request_match_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<RequestMatchRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('blood_request_id')) {
      context.handle(
        _bloodRequestIdMeta,
        bloodRequestId.isAcceptableOrUnknown(
          data['blood_request_id']!,
          _bloodRequestIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_bloodRequestIdMeta);
    }
    if (data.containsKey('response')) {
      context.handle(
        _responseMeta,
        response.isAcceptableOrUnknown(data['response']!, _responseMeta),
      );
    }
    if (data.containsKey('responded_at')) {
      context.handle(
        _respondedAtMeta,
        respondedAt.isAcceptableOrUnknown(
          data['responded_at']!,
          _respondedAtMeta,
        ),
      );
    }
    if (data.containsKey('is_pending')) {
      context.handle(
        _isPendingMeta,
        isPending.isAcceptableOrUnknown(data['is_pending']!, _isPendingMeta),
      );
    }
    if (data.containsKey('rejected_reason')) {
      context.handle(
        _rejectedReasonMeta,
        rejectedReason.isAcceptableOrUnknown(
          data['rejected_reason']!,
          _rejectedReasonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RequestMatchRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RequestMatchRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      bloodRequestId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}blood_request_id'],
      )!,
      response: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}response'],
      ),
      respondedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}responded_at'],
      ),
      isPending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pending'],
      )!,
      rejectedReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rejected_reason'],
      ),
    );
  }

  @override
  $RequestMatchRowsTable createAlias(String alias) {
    return $RequestMatchRowsTable(attachedDatabase, alias);
  }
}

class RequestMatchRow extends DataClass implements Insertable<RequestMatchRow> {
  final String id;
  final String bloodRequestId;
  final String? response;
  final DateTime? respondedAt;

  /// True between the local write and the server's confirmation. What the
  /// PENDING badge reads.
  final bool isPending;

  /// Set when the server refused the queued write — the request closed while
  /// the donor was offline. Server-wins, and the donor is told why.
  final String? rejectedReason;
  const RequestMatchRow({
    required this.id,
    required this.bloodRequestId,
    this.response,
    this.respondedAt,
    required this.isPending,
    this.rejectedReason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['blood_request_id'] = Variable<String>(bloodRequestId);
    if (!nullToAbsent || response != null) {
      map['response'] = Variable<String>(response);
    }
    if (!nullToAbsent || respondedAt != null) {
      map['responded_at'] = Variable<DateTime>(respondedAt);
    }
    map['is_pending'] = Variable<bool>(isPending);
    if (!nullToAbsent || rejectedReason != null) {
      map['rejected_reason'] = Variable<String>(rejectedReason);
    }
    return map;
  }

  RequestMatchRowsCompanion toCompanion(bool nullToAbsent) {
    return RequestMatchRowsCompanion(
      id: Value(id),
      bloodRequestId: Value(bloodRequestId),
      response: response == null && nullToAbsent
          ? const Value.absent()
          : Value(response),
      respondedAt: respondedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(respondedAt),
      isPending: Value(isPending),
      rejectedReason: rejectedReason == null && nullToAbsent
          ? const Value.absent()
          : Value(rejectedReason),
    );
  }

  factory RequestMatchRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RequestMatchRow(
      id: serializer.fromJson<String>(json['id']),
      bloodRequestId: serializer.fromJson<String>(json['bloodRequestId']),
      response: serializer.fromJson<String?>(json['response']),
      respondedAt: serializer.fromJson<DateTime?>(json['respondedAt']),
      isPending: serializer.fromJson<bool>(json['isPending']),
      rejectedReason: serializer.fromJson<String?>(json['rejectedReason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bloodRequestId': serializer.toJson<String>(bloodRequestId),
      'response': serializer.toJson<String?>(response),
      'respondedAt': serializer.toJson<DateTime?>(respondedAt),
      'isPending': serializer.toJson<bool>(isPending),
      'rejectedReason': serializer.toJson<String?>(rejectedReason),
    };
  }

  RequestMatchRow copyWith({
    String? id,
    String? bloodRequestId,
    Value<String?> response = const Value.absent(),
    Value<DateTime?> respondedAt = const Value.absent(),
    bool? isPending,
    Value<String?> rejectedReason = const Value.absent(),
  }) => RequestMatchRow(
    id: id ?? this.id,
    bloodRequestId: bloodRequestId ?? this.bloodRequestId,
    response: response.present ? response.value : this.response,
    respondedAt: respondedAt.present ? respondedAt.value : this.respondedAt,
    isPending: isPending ?? this.isPending,
    rejectedReason: rejectedReason.present
        ? rejectedReason.value
        : this.rejectedReason,
  );
  RequestMatchRow copyWithCompanion(RequestMatchRowsCompanion data) {
    return RequestMatchRow(
      id: data.id.present ? data.id.value : this.id,
      bloodRequestId: data.bloodRequestId.present
          ? data.bloodRequestId.value
          : this.bloodRequestId,
      response: data.response.present ? data.response.value : this.response,
      respondedAt: data.respondedAt.present
          ? data.respondedAt.value
          : this.respondedAt,
      isPending: data.isPending.present ? data.isPending.value : this.isPending,
      rejectedReason: data.rejectedReason.present
          ? data.rejectedReason.value
          : this.rejectedReason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RequestMatchRow(')
          ..write('id: $id, ')
          ..write('bloodRequestId: $bloodRequestId, ')
          ..write('response: $response, ')
          ..write('respondedAt: $respondedAt, ')
          ..write('isPending: $isPending, ')
          ..write('rejectedReason: $rejectedReason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    bloodRequestId,
    response,
    respondedAt,
    isPending,
    rejectedReason,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RequestMatchRow &&
          other.id == this.id &&
          other.bloodRequestId == this.bloodRequestId &&
          other.response == this.response &&
          other.respondedAt == this.respondedAt &&
          other.isPending == this.isPending &&
          other.rejectedReason == this.rejectedReason);
}

class RequestMatchRowsCompanion extends UpdateCompanion<RequestMatchRow> {
  final Value<String> id;
  final Value<String> bloodRequestId;
  final Value<String?> response;
  final Value<DateTime?> respondedAt;
  final Value<bool> isPending;
  final Value<String?> rejectedReason;
  final Value<int> rowid;
  const RequestMatchRowsCompanion({
    this.id = const Value.absent(),
    this.bloodRequestId = const Value.absent(),
    this.response = const Value.absent(),
    this.respondedAt = const Value.absent(),
    this.isPending = const Value.absent(),
    this.rejectedReason = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RequestMatchRowsCompanion.insert({
    required String id,
    required String bloodRequestId,
    this.response = const Value.absent(),
    this.respondedAt = const Value.absent(),
    this.isPending = const Value.absent(),
    this.rejectedReason = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       bloodRequestId = Value(bloodRequestId);
  static Insertable<RequestMatchRow> custom({
    Expression<String>? id,
    Expression<String>? bloodRequestId,
    Expression<String>? response,
    Expression<DateTime>? respondedAt,
    Expression<bool>? isPending,
    Expression<String>? rejectedReason,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bloodRequestId != null) 'blood_request_id': bloodRequestId,
      if (response != null) 'response': response,
      if (respondedAt != null) 'responded_at': respondedAt,
      if (isPending != null) 'is_pending': isPending,
      if (rejectedReason != null) 'rejected_reason': rejectedReason,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RequestMatchRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? bloodRequestId,
    Value<String?>? response,
    Value<DateTime?>? respondedAt,
    Value<bool>? isPending,
    Value<String?>? rejectedReason,
    Value<int>? rowid,
  }) {
    return RequestMatchRowsCompanion(
      id: id ?? this.id,
      bloodRequestId: bloodRequestId ?? this.bloodRequestId,
      response: response ?? this.response,
      respondedAt: respondedAt ?? this.respondedAt,
      isPending: isPending ?? this.isPending,
      rejectedReason: rejectedReason ?? this.rejectedReason,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (bloodRequestId.present) {
      map['blood_request_id'] = Variable<String>(bloodRequestId.value);
    }
    if (response.present) {
      map['response'] = Variable<String>(response.value);
    }
    if (respondedAt.present) {
      map['responded_at'] = Variable<DateTime>(respondedAt.value);
    }
    if (isPending.present) {
      map['is_pending'] = Variable<bool>(isPending.value);
    }
    if (rejectedReason.present) {
      map['rejected_reason'] = Variable<String>(rejectedReason.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RequestMatchRowsCompanion(')
          ..write('id: $id, ')
          ..write('bloodRequestId: $bloodRequestId, ')
          ..write('response: $response, ')
          ..write('respondedAt: $respondedAt, ')
          ..write('isPending: $isPending, ')
          ..write('rejectedReason: $rejectedReason, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingSyncTable extends PendingSync
    with TableInfo<$PendingSyncTable, PendingSyncData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingSyncTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>(
        'last_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _queuedAtMeta = const VerificationMeta(
    'queuedAt',
  );
  @override
  late final GeneratedColumn<DateTime> queuedAt = GeneratedColumn<DateTime>(
    'queued_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entity,
    entityId,
    operation,
    idempotencyKey,
    retryCount,
    lastAttemptAt,
    queuedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_sync';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingSyncData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entity')) {
      context.handle(
        _entityMeta,
        entity.isAcceptableOrUnknown(data['entity']!, _entityMeta),
      );
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('queued_at')) {
      context.handle(
        _queuedAtMeta,
        queuedAt.isAcceptableOrUnknown(data['queued_at']!, _queuedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_queuedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingSyncData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingSyncData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      ),
      queuedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}queued_at'],
      )!,
    );
  }

  @override
  $PendingSyncTable createAlias(String alias) {
    return $PendingSyncTable(attachedDatabase, alias);
  }
}

class PendingSyncData extends DataClass implements Insertable<PendingSyncData> {
  final int id;
  final String entity;
  final String entityId;
  final String operation;

  /// Generated once, replayed unchanged on every retry. Without it, a retry
  /// after a response that was sent but never received records the donor's
  /// acceptance twice.
  final String idempotencyKey;
  final int retryCount;
  final DateTime? lastAttemptAt;
  final DateTime queuedAt;
  const PendingSyncData({
    required this.id,
    required this.entity,
    required this.entityId,
    required this.operation,
    required this.idempotencyKey,
    required this.retryCount,
    this.lastAttemptAt,
    required this.queuedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entity'] = Variable<String>(entity);
    map['entity_id'] = Variable<String>(entityId);
    map['operation'] = Variable<String>(operation);
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    map['queued_at'] = Variable<DateTime>(queuedAt);
    return map;
  }

  PendingSyncCompanion toCompanion(bool nullToAbsent) {
    return PendingSyncCompanion(
      id: Value(id),
      entity: Value(entity),
      entityId: Value(entityId),
      operation: Value(operation),
      idempotencyKey: Value(idempotencyKey),
      retryCount: Value(retryCount),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      queuedAt: Value(queuedAt),
    );
  }

  factory PendingSyncData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingSyncData(
      id: serializer.fromJson<int>(json['id']),
      entity: serializer.fromJson<String>(json['entity']),
      entityId: serializer.fromJson<String>(json['entityId']),
      operation: serializer.fromJson<String>(json['operation']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
      queuedAt: serializer.fromJson<DateTime>(json['queuedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entity': serializer.toJson<String>(entity),
      'entityId': serializer.toJson<String>(entityId),
      'operation': serializer.toJson<String>(operation),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
      'queuedAt': serializer.toJson<DateTime>(queuedAt),
    };
  }

  PendingSyncData copyWith({
    int? id,
    String? entity,
    String? entityId,
    String? operation,
    String? idempotencyKey,
    int? retryCount,
    Value<DateTime?> lastAttemptAt = const Value.absent(),
    DateTime? queuedAt,
  }) => PendingSyncData(
    id: id ?? this.id,
    entity: entity ?? this.entity,
    entityId: entityId ?? this.entityId,
    operation: operation ?? this.operation,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    retryCount: retryCount ?? this.retryCount,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    queuedAt: queuedAt ?? this.queuedAt,
  );
  PendingSyncData copyWithCompanion(PendingSyncCompanion data) {
    return PendingSyncData(
      id: data.id.present ? data.id.value : this.id,
      entity: data.entity.present ? data.entity.value : this.entity,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operation: data.operation.present ? data.operation.value : this.operation,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      queuedAt: data.queuedAt.present ? data.queuedAt.value : this.queuedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingSyncData(')
          ..write('id: $id, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('queuedAt: $queuedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entity,
    entityId,
    operation,
    idempotencyKey,
    retryCount,
    lastAttemptAt,
    queuedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingSyncData &&
          other.id == this.id &&
          other.entity == this.entity &&
          other.entityId == this.entityId &&
          other.operation == this.operation &&
          other.idempotencyKey == this.idempotencyKey &&
          other.retryCount == this.retryCount &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.queuedAt == this.queuedAt);
}

class PendingSyncCompanion extends UpdateCompanion<PendingSyncData> {
  final Value<int> id;
  final Value<String> entity;
  final Value<String> entityId;
  final Value<String> operation;
  final Value<String> idempotencyKey;
  final Value<int> retryCount;
  final Value<DateTime?> lastAttemptAt;
  final Value<DateTime> queuedAt;
  const PendingSyncCompanion({
    this.id = const Value.absent(),
    this.entity = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operation = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.queuedAt = const Value.absent(),
  });
  PendingSyncCompanion.insert({
    this.id = const Value.absent(),
    required String entity,
    required String entityId,
    required String operation,
    required String idempotencyKey,
    this.retryCount = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    required DateTime queuedAt,
  }) : entity = Value(entity),
       entityId = Value(entityId),
       operation = Value(operation),
       idempotencyKey = Value(idempotencyKey),
       queuedAt = Value(queuedAt);
  static Insertable<PendingSyncData> custom({
    Expression<int>? id,
    Expression<String>? entity,
    Expression<String>? entityId,
    Expression<String>? operation,
    Expression<String>? idempotencyKey,
    Expression<int>? retryCount,
    Expression<DateTime>? lastAttemptAt,
    Expression<DateTime>? queuedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entity != null) 'entity': entity,
      if (entityId != null) 'entity_id': entityId,
      if (operation != null) 'operation': operation,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (queuedAt != null) 'queued_at': queuedAt,
    });
  }

  PendingSyncCompanion copyWith({
    Value<int>? id,
    Value<String>? entity,
    Value<String>? entityId,
    Value<String>? operation,
    Value<String>? idempotencyKey,
    Value<int>? retryCount,
    Value<DateTime?>? lastAttemptAt,
    Value<DateTime>? queuedAt,
  }) {
    return PendingSyncCompanion(
      id: id ?? this.id,
      entity: entity ?? this.entity,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      retryCount: retryCount ?? this.retryCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      queuedAt: queuedAt ?? this.queuedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (queuedAt.present) {
      map['queued_at'] = Variable<DateTime>(queuedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingSyncCompanion(')
          ..write('id: $id, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('queuedAt: $queuedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $RequestMatchRowsTable requestMatchRows = $RequestMatchRowsTable(
    this,
  );
  late final $PendingSyncTable pendingSync = $PendingSyncTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    requestMatchRows,
    pendingSync,
  ];
}

typedef $$RequestMatchRowsTableCreateCompanionBuilder =
    RequestMatchRowsCompanion Function({
      required String id,
      required String bloodRequestId,
      Value<String?> response,
      Value<DateTime?> respondedAt,
      Value<bool> isPending,
      Value<String?> rejectedReason,
      Value<int> rowid,
    });
typedef $$RequestMatchRowsTableUpdateCompanionBuilder =
    RequestMatchRowsCompanion Function({
      Value<String> id,
      Value<String> bloodRequestId,
      Value<String?> response,
      Value<DateTime?> respondedAt,
      Value<bool> isPending,
      Value<String?> rejectedReason,
      Value<int> rowid,
    });

class $$RequestMatchRowsTableFilterComposer
    extends Composer<_$AppDatabase, $RequestMatchRowsTable> {
  $$RequestMatchRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bloodRequestId => $composableBuilder(
    column: $table.bloodRequestId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get response => $composableBuilder(
    column: $table.response,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get respondedAt => $composableBuilder(
    column: $table.respondedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPending => $composableBuilder(
    column: $table.isPending,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rejectedReason => $composableBuilder(
    column: $table.rejectedReason,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RequestMatchRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $RequestMatchRowsTable> {
  $$RequestMatchRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bloodRequestId => $composableBuilder(
    column: $table.bloodRequestId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get response => $composableBuilder(
    column: $table.response,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get respondedAt => $composableBuilder(
    column: $table.respondedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPending => $composableBuilder(
    column: $table.isPending,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rejectedReason => $composableBuilder(
    column: $table.rejectedReason,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RequestMatchRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RequestMatchRowsTable> {
  $$RequestMatchRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bloodRequestId => $composableBuilder(
    column: $table.bloodRequestId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get response =>
      $composableBuilder(column: $table.response, builder: (column) => column);

  GeneratedColumn<DateTime> get respondedAt => $composableBuilder(
    column: $table.respondedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPending =>
      $composableBuilder(column: $table.isPending, builder: (column) => column);

  GeneratedColumn<String> get rejectedReason => $composableBuilder(
    column: $table.rejectedReason,
    builder: (column) => column,
  );
}

class $$RequestMatchRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RequestMatchRowsTable,
          RequestMatchRow,
          $$RequestMatchRowsTableFilterComposer,
          $$RequestMatchRowsTableOrderingComposer,
          $$RequestMatchRowsTableAnnotationComposer,
          $$RequestMatchRowsTableCreateCompanionBuilder,
          $$RequestMatchRowsTableUpdateCompanionBuilder,
          (
            RequestMatchRow,
            BaseReferences<
              _$AppDatabase,
              $RequestMatchRowsTable,
              RequestMatchRow
            >,
          ),
          RequestMatchRow,
          PrefetchHooks Function()
        > {
  $$RequestMatchRowsTableTableManager(
    _$AppDatabase db,
    $RequestMatchRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RequestMatchRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RequestMatchRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RequestMatchRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> bloodRequestId = const Value.absent(),
                Value<String?> response = const Value.absent(),
                Value<DateTime?> respondedAt = const Value.absent(),
                Value<bool> isPending = const Value.absent(),
                Value<String?> rejectedReason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RequestMatchRowsCompanion(
                id: id,
                bloodRequestId: bloodRequestId,
                response: response,
                respondedAt: respondedAt,
                isPending: isPending,
                rejectedReason: rejectedReason,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String bloodRequestId,
                Value<String?> response = const Value.absent(),
                Value<DateTime?> respondedAt = const Value.absent(),
                Value<bool> isPending = const Value.absent(),
                Value<String?> rejectedReason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RequestMatchRowsCompanion.insert(
                id: id,
                bloodRequestId: bloodRequestId,
                response: response,
                respondedAt: respondedAt,
                isPending: isPending,
                rejectedReason: rejectedReason,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RequestMatchRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RequestMatchRowsTable,
      RequestMatchRow,
      $$RequestMatchRowsTableFilterComposer,
      $$RequestMatchRowsTableOrderingComposer,
      $$RequestMatchRowsTableAnnotationComposer,
      $$RequestMatchRowsTableCreateCompanionBuilder,
      $$RequestMatchRowsTableUpdateCompanionBuilder,
      (
        RequestMatchRow,
        BaseReferences<_$AppDatabase, $RequestMatchRowsTable, RequestMatchRow>,
      ),
      RequestMatchRow,
      PrefetchHooks Function()
    >;
typedef $$PendingSyncTableCreateCompanionBuilder =
    PendingSyncCompanion Function({
      Value<int> id,
      required String entity,
      required String entityId,
      required String operation,
      required String idempotencyKey,
      Value<int> retryCount,
      Value<DateTime?> lastAttemptAt,
      required DateTime queuedAt,
    });
typedef $$PendingSyncTableUpdateCompanionBuilder =
    PendingSyncCompanion Function({
      Value<int> id,
      Value<String> entity,
      Value<String> entityId,
      Value<String> operation,
      Value<String> idempotencyKey,
      Value<int> retryCount,
      Value<DateTime?> lastAttemptAt,
      Value<DateTime> queuedAt,
    });

class $$PendingSyncTableFilterComposer
    extends Composer<_$AppDatabase, $PendingSyncTable> {
  $$PendingSyncTableFilterComposer({
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

  ColumnFilters<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingSyncTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingSyncTable> {
  $$PendingSyncTableOrderingComposer({
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

  ColumnOrderings<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingSyncTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingSyncTable> {
  $$PendingSyncTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get queuedAt =>
      $composableBuilder(column: $table.queuedAt, builder: (column) => column);
}

class $$PendingSyncTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingSyncTable,
          PendingSyncData,
          $$PendingSyncTableFilterComposer,
          $$PendingSyncTableOrderingComposer,
          $$PendingSyncTableAnnotationComposer,
          $$PendingSyncTableCreateCompanionBuilder,
          $$PendingSyncTableUpdateCompanionBuilder,
          (
            PendingSyncData,
            BaseReferences<_$AppDatabase, $PendingSyncTable, PendingSyncData>,
          ),
          PendingSyncData,
          PrefetchHooks Function()
        > {
  $$PendingSyncTableTableManager(_$AppDatabase db, $PendingSyncTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingSyncTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingSyncTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingSyncTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> entity = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<DateTime> queuedAt = const Value.absent(),
              }) => PendingSyncCompanion(
                id: id,
                entity: entity,
                entityId: entityId,
                operation: operation,
                idempotencyKey: idempotencyKey,
                retryCount: retryCount,
                lastAttemptAt: lastAttemptAt,
                queuedAt: queuedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String entity,
                required String entityId,
                required String operation,
                required String idempotencyKey,
                Value<int> retryCount = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                required DateTime queuedAt,
              }) => PendingSyncCompanion.insert(
                id: id,
                entity: entity,
                entityId: entityId,
                operation: operation,
                idempotencyKey: idempotencyKey,
                retryCount: retryCount,
                lastAttemptAt: lastAttemptAt,
                queuedAt: queuedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingSyncTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingSyncTable,
      PendingSyncData,
      $$PendingSyncTableFilterComposer,
      $$PendingSyncTableOrderingComposer,
      $$PendingSyncTableAnnotationComposer,
      $$PendingSyncTableCreateCompanionBuilder,
      $$PendingSyncTableUpdateCompanionBuilder,
      (
        PendingSyncData,
        BaseReferences<_$AppDatabase, $PendingSyncTable, PendingSyncData>,
      ),
      PendingSyncData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$RequestMatchRowsTableTableManager get requestMatchRows =>
      $$RequestMatchRowsTableTableManager(_db, _db.requestMatchRows);
  $$PendingSyncTableTableManager get pendingSync =>
      $$PendingSyncTableTableManager(_db, _db.pendingSync);
}
