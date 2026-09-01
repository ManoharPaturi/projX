// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_db.dart';

// ignore_for_file: type=lint
class $TenantsTable extends Tenants with TableInfo<$TenantsTable, Tenant> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TenantsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _planMeta = const VerificationMeta('plan');
  @override
  late final GeneratedColumn<String> plan = GeneratedColumn<String>(
    'plan',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> createdAt =
      GeneratedColumn<String>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        clientDefault: nowIsoUtc,
      ).withConverter<DateTime>($TenantsTable.$convertercreatedAt);
  @override
  List<GeneratedColumn> get $columns => [id, name, plan, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tenants';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tenant> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('plan')) {
      context.handle(
        _planMeta,
        plan.isAcceptableOrUnknown(data['plan']!, _planMeta),
      );
    } else if (isInserting) {
      context.missing(_planMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tenant map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tenant(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      plan: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan'],
      )!,
      createdAt: $TenantsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}created_at'],
        )!,
      ),
    );
  }

  @override
  $TenantsTable createAlias(String alias) {
    return $TenantsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, String> $convertercreatedAt =
      const IsoDateTimeConverter();
}

class Tenant extends DataClass implements Insertable<Tenant> {
  final String id;
  final String name;
  final String plan;

  /// ISO-8601 UTC TEXT — see [IsoDateTimeConverter].
  final DateTime createdAt;
  const Tenant({
    required this.id,
    required this.name,
    required this.plan,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['plan'] = Variable<String>(plan);
    {
      map['created_at'] = Variable<String>(
        $TenantsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    return map;
  }

  TenantsCompanion toCompanion(bool nullToAbsent) {
    return TenantsCompanion(
      id: Value(id),
      name: Value(name),
      plan: Value(plan),
      createdAt: Value(createdAt),
    );
  }

  factory Tenant.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tenant(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      plan: serializer.fromJson<String>(json['plan']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'plan': serializer.toJson<String>(plan),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Tenant copyWith({
    String? id,
    String? name,
    String? plan,
    DateTime? createdAt,
  }) => Tenant(
    id: id ?? this.id,
    name: name ?? this.name,
    plan: plan ?? this.plan,
    createdAt: createdAt ?? this.createdAt,
  );
  Tenant copyWithCompanion(TenantsCompanion data) {
    return Tenant(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      plan: data.plan.present ? data.plan.value : this.plan,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tenant(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('plan: $plan, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, plan, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tenant &&
          other.id == this.id &&
          other.name == this.name &&
          other.plan == this.plan &&
          other.createdAt == this.createdAt);
}

class TenantsCompanion extends UpdateCompanion<Tenant> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> plan;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const TenantsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.plan = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TenantsCompanion.insert({
    required String id,
    required String name,
    required String plan,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       plan = Value(plan);
  static Insertable<Tenant> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? plan,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (plan != null) 'plan': plan,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TenantsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? plan,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return TenantsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      plan: plan ?? this.plan,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (plan.present) {
      map['plan'] = Variable<String>(plan.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(
        $TenantsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TenantsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('plan: $plan, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InstitutesTable extends Institutes
    with TableInfo<$InstitutesTable, Institute> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InstitutesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> createdAt =
      GeneratedColumn<String>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        clientDefault: nowIsoUtc,
      ).withConverter<DateTime>($InstitutesTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<SyncState, String> syncState =
      GeneratedColumn<String>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('pending'),
      ).withConverter<SyncState>($InstitutesTable.$convertersyncState);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tenantId,
    name,
    code,
    createdAt,
    syncState,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'institutes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Institute> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Institute map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Institute(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      createdAt: $InstitutesTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      syncState: $InstitutesTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
    );
  }

  @override
  $InstitutesTable createAlias(String alias) {
    return $InstitutesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, String> $convertercreatedAt =
      const IsoDateTimeConverter();
  static JsonTypeConverter2<SyncState, String, String> $convertersyncState =
      const EnumNameConverter<SyncState>(SyncState.values);
}

class Institute extends DataClass implements Insertable<Institute> {
  /// Client-generated UUID — the sync idempotency key.
  final String id;
  final String tenantId;
  final String name;
  final String code;
  final DateTime createdAt;
  final SyncState syncState;
  const Institute({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.code,
    required this.createdAt,
    required this.syncState,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    map['name'] = Variable<String>(name);
    map['code'] = Variable<String>(code);
    {
      map['created_at'] = Variable<String>(
        $InstitutesTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['sync_state'] = Variable<String>(
        $InstitutesTable.$convertersyncState.toSql(syncState),
      );
    }
    return map;
  }

  InstitutesCompanion toCompanion(bool nullToAbsent) {
    return InstitutesCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      name: Value(name),
      code: Value(code),
      createdAt: Value(createdAt),
      syncState: Value(syncState),
    );
  }

  factory Institute.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Institute(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      name: serializer.fromJson<String>(json['name']),
      code: serializer.fromJson<String>(json['code']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncState: $InstitutesTable.$convertersyncState.fromJson(
        serializer.fromJson<String>(json['syncState']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'name': serializer.toJson<String>(name),
      'code': serializer.toJson<String>(code),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncState': serializer.toJson<String>(
        $InstitutesTable.$convertersyncState.toJson(syncState),
      ),
    };
  }

  Institute copyWith({
    String? id,
    String? tenantId,
    String? name,
    String? code,
    DateTime? createdAt,
    SyncState? syncState,
  }) => Institute(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    name: name ?? this.name,
    code: code ?? this.code,
    createdAt: createdAt ?? this.createdAt,
    syncState: syncState ?? this.syncState,
  );
  Institute copyWithCompanion(InstitutesCompanion data) {
    return Institute(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      name: data.name.present ? data.name.value : this.name,
      code: data.code.present ? data.code.value : this.code,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Institute(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncState: $syncState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, tenantId, name, code, createdAt, syncState);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Institute &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.name == this.name &&
          other.code == this.code &&
          other.createdAt == this.createdAt &&
          other.syncState == this.syncState);
}

class InstitutesCompanion extends UpdateCompanion<Institute> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String> name;
  final Value<String> code;
  final Value<DateTime> createdAt;
  final Value<SyncState> syncState;
  final Value<int> rowid;
  const InstitutesCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.name = const Value.absent(),
    this.code = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InstitutesCompanion.insert({
    this.id = const Value.absent(),
    required String tenantId,
    required String name,
    required String code,
    this.createdAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       name = Value(name),
       code = Value(code);
  static Insertable<Institute> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? name,
    Expression<String>? code,
    Expression<String>? createdAt,
    Expression<String>? syncState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (name != null) 'name': name,
      if (code != null) 'code': code,
      if (createdAt != null) 'created_at': createdAt,
      if (syncState != null) 'sync_state': syncState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InstitutesCompanion copyWith({
    Value<String>? id,
    Value<String>? tenantId,
    Value<String>? name,
    Value<String>? code,
    Value<DateTime>? createdAt,
    Value<SyncState>? syncState,
    Value<int>? rowid,
  }) {
    return InstitutesCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      code: code ?? this.code,
      createdAt: createdAt ?? this.createdAt,
      syncState: syncState ?? this.syncState,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(
        $InstitutesTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(
        $InstitutesTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InstitutesCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncState: $syncState, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StudentsTable extends Students with TableInfo<$StudentsTable, Student> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StudentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _instituteIdMeta = const VerificationMeta(
    'instituteId',
  );
  @override
  late final GeneratedColumn<String> instituteId = GeneratedColumn<String>(
    'institute_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES institutes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _rollNoMeta = const VerificationMeta('rollNo');
  @override
  late final GeneratedColumn<String> rollNo = GeneratedColumn<String>(
    'roll_no',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _batchMeta = const VerificationMeta('batch');
  @override
  late final GeneratedColumn<String> batch = GeneratedColumn<String>(
    'batch',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> createdAt =
      GeneratedColumn<String>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        clientDefault: nowIsoUtc,
      ).withConverter<DateTime>($StudentsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<SyncState, String> syncState =
      GeneratedColumn<String>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('pending'),
      ).withConverter<SyncState>($StudentsTable.$convertersyncState);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tenantId,
    instituteId,
    rollNo,
    name,
    batch,
    createdAt,
    syncState,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'students';
  @override
  VerificationContext validateIntegrity(
    Insertable<Student> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('institute_id')) {
      context.handle(
        _instituteIdMeta,
        instituteId.isAcceptableOrUnknown(
          data['institute_id']!,
          _instituteIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_instituteIdMeta);
    }
    if (data.containsKey('roll_no')) {
      context.handle(
        _rollNoMeta,
        rollNo.isAcceptableOrUnknown(data['roll_no']!, _rollNoMeta),
      );
    } else if (isInserting) {
      context.missing(_rollNoMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('batch')) {
      context.handle(
        _batchMeta,
        batch.isAcceptableOrUnknown(data['batch']!, _batchMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Student map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Student(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      instituteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}institute_id'],
      )!,
      rollNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}roll_no'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      batch: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch'],
      ),
      createdAt: $StudentsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      syncState: $StudentsTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
    );
  }

  @override
  $StudentsTable createAlias(String alias) {
    return $StudentsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, String> $convertercreatedAt =
      const IsoDateTimeConverter();
  static JsonTypeConverter2<SyncState, String, String> $convertersyncState =
      const EnumNameConverter<SyncState>(SyncState.values);
}

class Student extends DataClass implements Insertable<Student> {
  final String id;

  /// LEADING tenant column (plan §4: every domain table is tenant-first).
  final String tenantId;

  /// Deleting an institute takes its roster with it (schema_test pins this).
  final String instituteId;
  final String rollNo;

  /// PII-min (plan risk #9): roll numbers, not names, are the student key.
  final String? name;
  final String? batch;
  final DateTime createdAt;
  final SyncState syncState;
  const Student({
    required this.id,
    required this.tenantId,
    required this.instituteId,
    required this.rollNo,
    this.name,
    this.batch,
    required this.createdAt,
    required this.syncState,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    map['institute_id'] = Variable<String>(instituteId);
    map['roll_no'] = Variable<String>(rollNo);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || batch != null) {
      map['batch'] = Variable<String>(batch);
    }
    {
      map['created_at'] = Variable<String>(
        $StudentsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['sync_state'] = Variable<String>(
        $StudentsTable.$convertersyncState.toSql(syncState),
      );
    }
    return map;
  }

  StudentsCompanion toCompanion(bool nullToAbsent) {
    return StudentsCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      instituteId: Value(instituteId),
      rollNo: Value(rollNo),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      batch: batch == null && nullToAbsent
          ? const Value.absent()
          : Value(batch),
      createdAt: Value(createdAt),
      syncState: Value(syncState),
    );
  }

  factory Student.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Student(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      instituteId: serializer.fromJson<String>(json['instituteId']),
      rollNo: serializer.fromJson<String>(json['rollNo']),
      name: serializer.fromJson<String?>(json['name']),
      batch: serializer.fromJson<String?>(json['batch']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncState: $StudentsTable.$convertersyncState.fromJson(
        serializer.fromJson<String>(json['syncState']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'instituteId': serializer.toJson<String>(instituteId),
      'rollNo': serializer.toJson<String>(rollNo),
      'name': serializer.toJson<String?>(name),
      'batch': serializer.toJson<String?>(batch),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncState': serializer.toJson<String>(
        $StudentsTable.$convertersyncState.toJson(syncState),
      ),
    };
  }

  Student copyWith({
    String? id,
    String? tenantId,
    String? instituteId,
    String? rollNo,
    Value<String?> name = const Value.absent(),
    Value<String?> batch = const Value.absent(),
    DateTime? createdAt,
    SyncState? syncState,
  }) => Student(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    instituteId: instituteId ?? this.instituteId,
    rollNo: rollNo ?? this.rollNo,
    name: name.present ? name.value : this.name,
    batch: batch.present ? batch.value : this.batch,
    createdAt: createdAt ?? this.createdAt,
    syncState: syncState ?? this.syncState,
  );
  Student copyWithCompanion(StudentsCompanion data) {
    return Student(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      instituteId: data.instituteId.present
          ? data.instituteId.value
          : this.instituteId,
      rollNo: data.rollNo.present ? data.rollNo.value : this.rollNo,
      name: data.name.present ? data.name.value : this.name,
      batch: data.batch.present ? data.batch.value : this.batch,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Student(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('instituteId: $instituteId, ')
          ..write('rollNo: $rollNo, ')
          ..write('name: $name, ')
          ..write('batch: $batch, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncState: $syncState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tenantId,
    instituteId,
    rollNo,
    name,
    batch,
    createdAt,
    syncState,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Student &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.instituteId == this.instituteId &&
          other.rollNo == this.rollNo &&
          other.name == this.name &&
          other.batch == this.batch &&
          other.createdAt == this.createdAt &&
          other.syncState == this.syncState);
}

class StudentsCompanion extends UpdateCompanion<Student> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String> instituteId;
  final Value<String> rollNo;
  final Value<String?> name;
  final Value<String?> batch;
  final Value<DateTime> createdAt;
  final Value<SyncState> syncState;
  final Value<int> rowid;
  const StudentsCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.instituteId = const Value.absent(),
    this.rollNo = const Value.absent(),
    this.name = const Value.absent(),
    this.batch = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StudentsCompanion.insert({
    this.id = const Value.absent(),
    required String tenantId,
    required String instituteId,
    required String rollNo,
    this.name = const Value.absent(),
    this.batch = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       instituteId = Value(instituteId),
       rollNo = Value(rollNo);
  static Insertable<Student> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? instituteId,
    Expression<String>? rollNo,
    Expression<String>? name,
    Expression<String>? batch,
    Expression<String>? createdAt,
    Expression<String>? syncState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (instituteId != null) 'institute_id': instituteId,
      if (rollNo != null) 'roll_no': rollNo,
      if (name != null) 'name': name,
      if (batch != null) 'batch': batch,
      if (createdAt != null) 'created_at': createdAt,
      if (syncState != null) 'sync_state': syncState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StudentsCompanion copyWith({
    Value<String>? id,
    Value<String>? tenantId,
    Value<String>? instituteId,
    Value<String>? rollNo,
    Value<String?>? name,
    Value<String?>? batch,
    Value<DateTime>? createdAt,
    Value<SyncState>? syncState,
    Value<int>? rowid,
  }) {
    return StudentsCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      instituteId: instituteId ?? this.instituteId,
      rollNo: rollNo ?? this.rollNo,
      name: name ?? this.name,
      batch: batch ?? this.batch,
      createdAt: createdAt ?? this.createdAt,
      syncState: syncState ?? this.syncState,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (instituteId.present) {
      map['institute_id'] = Variable<String>(instituteId.value);
    }
    if (rollNo.present) {
      map['roll_no'] = Variable<String>(rollNo.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (batch.present) {
      map['batch'] = Variable<String>(batch.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(
        $StudentsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(
        $StudentsTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudentsCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('instituteId: $instituteId, ')
          ..write('rollNo: $rollNo, ')
          ..write('name: $name, ')
          ..write('batch: $batch, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncState: $syncState, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SheetLayoutsTable extends SheetLayouts
    with TableInfo<$SheetLayoutsTable, SheetLayout> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SheetLayoutsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _layoutIdMeta = const VerificationMeta(
    'layoutId',
  );
  @override
  late final GeneratedColumn<String> layoutId = GeneratedColumn<String>(
    'layout_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _layoutVersionMeta = const VerificationMeta(
    'layoutVersion',
  );
  @override
  late final GeneratedColumn<int> layoutVersion = GeneratedColumn<int>(
    'layout_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _specJsonMeta = const VerificationMeta(
    'specJson',
  );
  @override
  late final GeneratedColumn<String> specJson = GeneratedColumn<String>(
    'spec_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _specHashMeta = const VerificationMeta(
    'specHash',
  );
  @override
  late final GeneratedColumn<String> specHash = GeneratedColumn<String>(
    'spec_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> createdAt =
      GeneratedColumn<String>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        clientDefault: nowIsoUtc,
      ).withConverter<DateTime>($SheetLayoutsTable.$convertercreatedAt);
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tenantId,
    layoutId,
    layoutVersion,
    specJson,
    specHash,
    createdAt,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sheet_layouts';
  @override
  VerificationContext validateIntegrity(
    Insertable<SheetLayout> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('layout_id')) {
      context.handle(
        _layoutIdMeta,
        layoutId.isAcceptableOrUnknown(data['layout_id']!, _layoutIdMeta),
      );
    } else if (isInserting) {
      context.missing(_layoutIdMeta);
    }
    if (data.containsKey('layout_version')) {
      context.handle(
        _layoutVersionMeta,
        layoutVersion.isAcceptableOrUnknown(
          data['layout_version']!,
          _layoutVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_layoutVersionMeta);
    }
    if (data.containsKey('spec_json')) {
      context.handle(
        _specJsonMeta,
        specJson.isAcceptableOrUnknown(data['spec_json']!, _specJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_specJsonMeta);
    }
    if (data.containsKey('spec_hash')) {
      context.handle(
        _specHashMeta,
        specHash.isAcceptableOrUnknown(data['spec_hash']!, _specHashMeta),
      );
    } else if (isInserting) {
      context.missing(_specHashMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SheetLayout map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SheetLayout(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      layoutId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}layout_id'],
      )!,
      layoutVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}layout_version'],
      )!,
      specJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}spec_json'],
      )!,
      specHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}spec_hash'],
      )!,
      createdAt: $SheetLayoutsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $SheetLayoutsTable createAlias(String alias) {
    return $SheetLayoutsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, String> $convertercreatedAt =
      const IsoDateTimeConverter();
}

class SheetLayout extends DataClass implements Insertable<SheetLayout> {
  final String id;
  final String tenantId;
  final String layoutId;
  final int layoutVersion;

  /// Canonical JSON of the `SheetSpec` (omr_spec) — round-trips through
  /// `SheetSpec.fromJson`.
  final String specJson;

  /// `specSha256(spec)` — sha256 hex of the spec's canonical JSON.
  final String specHash;
  final DateTime createdAt;
  final bool isActive;
  const SheetLayout({
    required this.id,
    required this.tenantId,
    required this.layoutId,
    required this.layoutVersion,
    required this.specJson,
    required this.specHash,
    required this.createdAt,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    map['layout_id'] = Variable<String>(layoutId);
    map['layout_version'] = Variable<int>(layoutVersion);
    map['spec_json'] = Variable<String>(specJson);
    map['spec_hash'] = Variable<String>(specHash);
    {
      map['created_at'] = Variable<String>(
        $SheetLayoutsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  SheetLayoutsCompanion toCompanion(bool nullToAbsent) {
    return SheetLayoutsCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      layoutId: Value(layoutId),
      layoutVersion: Value(layoutVersion),
      specJson: Value(specJson),
      specHash: Value(specHash),
      createdAt: Value(createdAt),
      isActive: Value(isActive),
    );
  }

  factory SheetLayout.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SheetLayout(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      layoutId: serializer.fromJson<String>(json['layoutId']),
      layoutVersion: serializer.fromJson<int>(json['layoutVersion']),
      specJson: serializer.fromJson<String>(json['specJson']),
      specHash: serializer.fromJson<String>(json['specHash']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'layoutId': serializer.toJson<String>(layoutId),
      'layoutVersion': serializer.toJson<int>(layoutVersion),
      'specJson': serializer.toJson<String>(specJson),
      'specHash': serializer.toJson<String>(specHash),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  SheetLayout copyWith({
    String? id,
    String? tenantId,
    String? layoutId,
    int? layoutVersion,
    String? specJson,
    String? specHash,
    DateTime? createdAt,
    bool? isActive,
  }) => SheetLayout(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    layoutId: layoutId ?? this.layoutId,
    layoutVersion: layoutVersion ?? this.layoutVersion,
    specJson: specJson ?? this.specJson,
    specHash: specHash ?? this.specHash,
    createdAt: createdAt ?? this.createdAt,
    isActive: isActive ?? this.isActive,
  );
  SheetLayout copyWithCompanion(SheetLayoutsCompanion data) {
    return SheetLayout(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      layoutId: data.layoutId.present ? data.layoutId.value : this.layoutId,
      layoutVersion: data.layoutVersion.present
          ? data.layoutVersion.value
          : this.layoutVersion,
      specJson: data.specJson.present ? data.specJson.value : this.specJson,
      specHash: data.specHash.present ? data.specHash.value : this.specHash,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SheetLayout(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('layoutId: $layoutId, ')
          ..write('layoutVersion: $layoutVersion, ')
          ..write('specJson: $specJson, ')
          ..write('specHash: $specHash, ')
          ..write('createdAt: $createdAt, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tenantId,
    layoutId,
    layoutVersion,
    specJson,
    specHash,
    createdAt,
    isActive,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SheetLayout &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.layoutId == this.layoutId &&
          other.layoutVersion == this.layoutVersion &&
          other.specJson == this.specJson &&
          other.specHash == this.specHash &&
          other.createdAt == this.createdAt &&
          other.isActive == this.isActive);
}

class SheetLayoutsCompanion extends UpdateCompanion<SheetLayout> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String> layoutId;
  final Value<int> layoutVersion;
  final Value<String> specJson;
  final Value<String> specHash;
  final Value<DateTime> createdAt;
  final Value<bool> isActive;
  final Value<int> rowid;
  const SheetLayoutsCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.layoutId = const Value.absent(),
    this.layoutVersion = const Value.absent(),
    this.specJson = const Value.absent(),
    this.specHash = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SheetLayoutsCompanion.insert({
    this.id = const Value.absent(),
    required String tenantId,
    required String layoutId,
    required int layoutVersion,
    required String specJson,
    required String specHash,
    this.createdAt = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       layoutId = Value(layoutId),
       layoutVersion = Value(layoutVersion),
       specJson = Value(specJson),
       specHash = Value(specHash);
  static Insertable<SheetLayout> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? layoutId,
    Expression<int>? layoutVersion,
    Expression<String>? specJson,
    Expression<String>? specHash,
    Expression<String>? createdAt,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (layoutId != null) 'layout_id': layoutId,
      if (layoutVersion != null) 'layout_version': layoutVersion,
      if (specJson != null) 'spec_json': specJson,
      if (specHash != null) 'spec_hash': specHash,
      if (createdAt != null) 'created_at': createdAt,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SheetLayoutsCompanion copyWith({
    Value<String>? id,
    Value<String>? tenantId,
    Value<String>? layoutId,
    Value<int>? layoutVersion,
    Value<String>? specJson,
    Value<String>? specHash,
    Value<DateTime>? createdAt,
    Value<bool>? isActive,
    Value<int>? rowid,
  }) {
    return SheetLayoutsCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      layoutId: layoutId ?? this.layoutId,
      layoutVersion: layoutVersion ?? this.layoutVersion,
      specJson: specJson ?? this.specJson,
      specHash: specHash ?? this.specHash,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (layoutId.present) {
      map['layout_id'] = Variable<String>(layoutId.value);
    }
    if (layoutVersion.present) {
      map['layout_version'] = Variable<int>(layoutVersion.value);
    }
    if (specJson.present) {
      map['spec_json'] = Variable<String>(specJson.value);
    }
    if (specHash.present) {
      map['spec_hash'] = Variable<String>(specHash.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(
        $SheetLayoutsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SheetLayoutsCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('layoutId: $layoutId, ')
          ..write('layoutVersion: $layoutVersion, ')
          ..write('specJson: $specJson, ')
          ..write('specHash: $specHash, ')
          ..write('createdAt: $createdAt, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExamsTable extends Exams with TableInfo<$ExamsTable, Exam> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExamsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _instituteIdMeta = const VerificationMeta(
    'instituteId',
  );
  @override
  late final GeneratedColumn<String> instituteId = GeneratedColumn<String>(
    'institute_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES institutes (id) ON DELETE RESTRICT',
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
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> heldAt =
      GeneratedColumn<String>(
        'held_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        clientDefault: nowIsoUtc,
      ).withConverter<DateTime?>($ExamsTable.$converterheldAtn);
  static const VerificationMeta _sheetLayoutIdMeta = const VerificationMeta(
    'sheetLayoutId',
  );
  @override
  late final GeneratedColumn<String> sheetLayoutId = GeneratedColumn<String>(
    'sheet_layout_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sheet_layouts (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _totalQuestionsMeta = const VerificationMeta(
    'totalQuestions',
  );
  @override
  late final GeneratedColumn<int> totalQuestions = GeneratedColumn<int>(
    'total_questions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ExamStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('draft'),
      ).withConverter<ExamStatus>($ExamsTable.$converterstatus);
  static const VerificationMeta _gradingConfigJsonMeta = const VerificationMeta(
    'gradingConfigJson',
  );
  @override
  late final GeneratedColumn<String> gradingConfigJson =
      GeneratedColumn<String>(
        'grading_config_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('{}'),
      );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> createdAt =
      GeneratedColumn<String>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        clientDefault: nowIsoUtc,
      ).withConverter<DateTime>($ExamsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<SyncState, String> syncState =
      GeneratedColumn<String>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('pending'),
      ).withConverter<SyncState>($ExamsTable.$convertersyncState);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tenantId,
    instituteId,
    name,
    heldAt,
    sheetLayoutId,
    totalQuestions,
    status,
    gradingConfigJson,
    createdAt,
    syncState,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exams';
  @override
  VerificationContext validateIntegrity(
    Insertable<Exam> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('institute_id')) {
      context.handle(
        _instituteIdMeta,
        instituteId.isAcceptableOrUnknown(
          data['institute_id']!,
          _instituteIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_instituteIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sheet_layout_id')) {
      context.handle(
        _sheetLayoutIdMeta,
        sheetLayoutId.isAcceptableOrUnknown(
          data['sheet_layout_id']!,
          _sheetLayoutIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sheetLayoutIdMeta);
    }
    if (data.containsKey('total_questions')) {
      context.handle(
        _totalQuestionsMeta,
        totalQuestions.isAcceptableOrUnknown(
          data['total_questions']!,
          _totalQuestionsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalQuestionsMeta);
    }
    if (data.containsKey('grading_config_json')) {
      context.handle(
        _gradingConfigJsonMeta,
        gradingConfigJson.isAcceptableOrUnknown(
          data['grading_config_json']!,
          _gradingConfigJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Exam map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Exam(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      instituteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}institute_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      heldAt: $ExamsTable.$converterheldAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}held_at'],
        ),
      ),
      sheetLayoutId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sheet_layout_id'],
      )!,
      totalQuestions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_questions'],
      )!,
      status: $ExamsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      gradingConfigJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grading_config_json'],
      )!,
      createdAt: $ExamsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      syncState: $ExamsTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
    );
  }

  @override
  $ExamsTable createAlias(String alias) {
    return $ExamsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, String> $converterheldAt =
      const IsoDateTimeConverter();
  static TypeConverter<DateTime?, String?> $converterheldAtn =
      NullAwareTypeConverter.wrap($converterheldAt);
  static JsonTypeConverter2<ExamStatus, String, String> $converterstatus =
      const EnumNameConverter<ExamStatus>(ExamStatus.values);
  static TypeConverter<DateTime, String> $convertercreatedAt =
      const IsoDateTimeConverter();
  static JsonTypeConverter2<SyncState, String, String> $convertersyncState =
      const EnumNameConverter<SyncState>(SyncState.values);
}

class Exam extends DataClass implements Insertable<Exam> {
  final String id;
  final String tenantId;

  /// Audited history wins over tidy deletes: an exam outlives its institute
  /// record (results reference exams with RESTRICT anyway).
  final String instituteId;
  final String name;
  final DateTime? heldAt;

  /// Layouts are immutable printed artifacts — never delete under an exam.
  final String sheetLayoutId;
  final int totalQuestions;
  final ExamStatus status;

  /// JSON: scoring preset + section overrides selected in exam setup.
  final String gradingConfigJson;
  final DateTime createdAt;
  final SyncState syncState;
  const Exam({
    required this.id,
    required this.tenantId,
    required this.instituteId,
    required this.name,
    this.heldAt,
    required this.sheetLayoutId,
    required this.totalQuestions,
    required this.status,
    required this.gradingConfigJson,
    required this.createdAt,
    required this.syncState,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    map['institute_id'] = Variable<String>(instituteId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || heldAt != null) {
      map['held_at'] = Variable<String>(
        $ExamsTable.$converterheldAtn.toSql(heldAt),
      );
    }
    map['sheet_layout_id'] = Variable<String>(sheetLayoutId);
    map['total_questions'] = Variable<int>(totalQuestions);
    {
      map['status'] = Variable<String>(
        $ExamsTable.$converterstatus.toSql(status),
      );
    }
    map['grading_config_json'] = Variable<String>(gradingConfigJson);
    {
      map['created_at'] = Variable<String>(
        $ExamsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['sync_state'] = Variable<String>(
        $ExamsTable.$convertersyncState.toSql(syncState),
      );
    }
    return map;
  }

  ExamsCompanion toCompanion(bool nullToAbsent) {
    return ExamsCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      instituteId: Value(instituteId),
      name: Value(name),
      heldAt: heldAt == null && nullToAbsent
          ? const Value.absent()
          : Value(heldAt),
      sheetLayoutId: Value(sheetLayoutId),
      totalQuestions: Value(totalQuestions),
      status: Value(status),
      gradingConfigJson: Value(gradingConfigJson),
      createdAt: Value(createdAt),
      syncState: Value(syncState),
    );
  }

  factory Exam.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Exam(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      instituteId: serializer.fromJson<String>(json['instituteId']),
      name: serializer.fromJson<String>(json['name']),
      heldAt: serializer.fromJson<DateTime?>(json['heldAt']),
      sheetLayoutId: serializer.fromJson<String>(json['sheetLayoutId']),
      totalQuestions: serializer.fromJson<int>(json['totalQuestions']),
      status: $ExamsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      gradingConfigJson: serializer.fromJson<String>(json['gradingConfigJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncState: $ExamsTable.$convertersyncState.fromJson(
        serializer.fromJson<String>(json['syncState']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'instituteId': serializer.toJson<String>(instituteId),
      'name': serializer.toJson<String>(name),
      'heldAt': serializer.toJson<DateTime?>(heldAt),
      'sheetLayoutId': serializer.toJson<String>(sheetLayoutId),
      'totalQuestions': serializer.toJson<int>(totalQuestions),
      'status': serializer.toJson<String>(
        $ExamsTable.$converterstatus.toJson(status),
      ),
      'gradingConfigJson': serializer.toJson<String>(gradingConfigJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncState': serializer.toJson<String>(
        $ExamsTable.$convertersyncState.toJson(syncState),
      ),
    };
  }

  Exam copyWith({
    String? id,
    String? tenantId,
    String? instituteId,
    String? name,
    Value<DateTime?> heldAt = const Value.absent(),
    String? sheetLayoutId,
    int? totalQuestions,
    ExamStatus? status,
    String? gradingConfigJson,
    DateTime? createdAt,
    SyncState? syncState,
  }) => Exam(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    instituteId: instituteId ?? this.instituteId,
    name: name ?? this.name,
    heldAt: heldAt.present ? heldAt.value : this.heldAt,
    sheetLayoutId: sheetLayoutId ?? this.sheetLayoutId,
    totalQuestions: totalQuestions ?? this.totalQuestions,
    status: status ?? this.status,
    gradingConfigJson: gradingConfigJson ?? this.gradingConfigJson,
    createdAt: createdAt ?? this.createdAt,
    syncState: syncState ?? this.syncState,
  );
  Exam copyWithCompanion(ExamsCompanion data) {
    return Exam(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      instituteId: data.instituteId.present
          ? data.instituteId.value
          : this.instituteId,
      name: data.name.present ? data.name.value : this.name,
      heldAt: data.heldAt.present ? data.heldAt.value : this.heldAt,
      sheetLayoutId: data.sheetLayoutId.present
          ? data.sheetLayoutId.value
          : this.sheetLayoutId,
      totalQuestions: data.totalQuestions.present
          ? data.totalQuestions.value
          : this.totalQuestions,
      status: data.status.present ? data.status.value : this.status,
      gradingConfigJson: data.gradingConfigJson.present
          ? data.gradingConfigJson.value
          : this.gradingConfigJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Exam(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('instituteId: $instituteId, ')
          ..write('name: $name, ')
          ..write('heldAt: $heldAt, ')
          ..write('sheetLayoutId: $sheetLayoutId, ')
          ..write('totalQuestions: $totalQuestions, ')
          ..write('status: $status, ')
          ..write('gradingConfigJson: $gradingConfigJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncState: $syncState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tenantId,
    instituteId,
    name,
    heldAt,
    sheetLayoutId,
    totalQuestions,
    status,
    gradingConfigJson,
    createdAt,
    syncState,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Exam &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.instituteId == this.instituteId &&
          other.name == this.name &&
          other.heldAt == this.heldAt &&
          other.sheetLayoutId == this.sheetLayoutId &&
          other.totalQuestions == this.totalQuestions &&
          other.status == this.status &&
          other.gradingConfigJson == this.gradingConfigJson &&
          other.createdAt == this.createdAt &&
          other.syncState == this.syncState);
}

class ExamsCompanion extends UpdateCompanion<Exam> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String> instituteId;
  final Value<String> name;
  final Value<DateTime?> heldAt;
  final Value<String> sheetLayoutId;
  final Value<int> totalQuestions;
  final Value<ExamStatus> status;
  final Value<String> gradingConfigJson;
  final Value<DateTime> createdAt;
  final Value<SyncState> syncState;
  final Value<int> rowid;
  const ExamsCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.instituteId = const Value.absent(),
    this.name = const Value.absent(),
    this.heldAt = const Value.absent(),
    this.sheetLayoutId = const Value.absent(),
    this.totalQuestions = const Value.absent(),
    this.status = const Value.absent(),
    this.gradingConfigJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExamsCompanion.insert({
    this.id = const Value.absent(),
    required String tenantId,
    required String instituteId,
    required String name,
    this.heldAt = const Value.absent(),
    required String sheetLayoutId,
    required int totalQuestions,
    this.status = const Value.absent(),
    this.gradingConfigJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       instituteId = Value(instituteId),
       name = Value(name),
       sheetLayoutId = Value(sheetLayoutId),
       totalQuestions = Value(totalQuestions);
  static Insertable<Exam> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? instituteId,
    Expression<String>? name,
    Expression<String>? heldAt,
    Expression<String>? sheetLayoutId,
    Expression<int>? totalQuestions,
    Expression<String>? status,
    Expression<String>? gradingConfigJson,
    Expression<String>? createdAt,
    Expression<String>? syncState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (instituteId != null) 'institute_id': instituteId,
      if (name != null) 'name': name,
      if (heldAt != null) 'held_at': heldAt,
      if (sheetLayoutId != null) 'sheet_layout_id': sheetLayoutId,
      if (totalQuestions != null) 'total_questions': totalQuestions,
      if (status != null) 'status': status,
      if (gradingConfigJson != null) 'grading_config_json': gradingConfigJson,
      if (createdAt != null) 'created_at': createdAt,
      if (syncState != null) 'sync_state': syncState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExamsCompanion copyWith({
    Value<String>? id,
    Value<String>? tenantId,
    Value<String>? instituteId,
    Value<String>? name,
    Value<DateTime?>? heldAt,
    Value<String>? sheetLayoutId,
    Value<int>? totalQuestions,
    Value<ExamStatus>? status,
    Value<String>? gradingConfigJson,
    Value<DateTime>? createdAt,
    Value<SyncState>? syncState,
    Value<int>? rowid,
  }) {
    return ExamsCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      instituteId: instituteId ?? this.instituteId,
      name: name ?? this.name,
      heldAt: heldAt ?? this.heldAt,
      sheetLayoutId: sheetLayoutId ?? this.sheetLayoutId,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      status: status ?? this.status,
      gradingConfigJson: gradingConfigJson ?? this.gradingConfigJson,
      createdAt: createdAt ?? this.createdAt,
      syncState: syncState ?? this.syncState,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (instituteId.present) {
      map['institute_id'] = Variable<String>(instituteId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (heldAt.present) {
      map['held_at'] = Variable<String>(
        $ExamsTable.$converterheldAtn.toSql(heldAt.value),
      );
    }
    if (sheetLayoutId.present) {
      map['sheet_layout_id'] = Variable<String>(sheetLayoutId.value);
    }
    if (totalQuestions.present) {
      map['total_questions'] = Variable<int>(totalQuestions.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $ExamsTable.$converterstatus.toSql(status.value),
      );
    }
    if (gradingConfigJson.present) {
      map['grading_config_json'] = Variable<String>(gradingConfigJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(
        $ExamsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(
        $ExamsTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExamsCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('instituteId: $instituteId, ')
          ..write('name: $name, ')
          ..write('heldAt: $heldAt, ')
          ..write('sheetLayoutId: $sheetLayoutId, ')
          ..write('totalQuestions: $totalQuestions, ')
          ..write('status: $status, ')
          ..write('gradingConfigJson: $gradingConfigJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncState: $syncState, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuestionSetsTable extends QuestionSets
    with TableInfo<$QuestionSetsTable, QuestionSet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestionSetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _examIdMeta = const VerificationMeta('examId');
  @override
  late final GeneratedColumn<String> examId = GeneratedColumn<String>(
    'exam_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exams (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _setCodeMeta = const VerificationMeta(
    'setCode',
  );
  @override
  late final GeneratedColumn<String> setCode = GeneratedColumn<String>(
    'set_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionMapJsonMeta = const VerificationMeta(
    'questionMapJson',
  );
  @override
  late final GeneratedColumn<String> questionMapJson = GeneratedColumn<String>(
    'question_map_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tenantId,
    examId,
    setCode,
    questionMapJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'question_sets';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuestionSet> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('exam_id')) {
      context.handle(
        _examIdMeta,
        examId.isAcceptableOrUnknown(data['exam_id']!, _examIdMeta),
      );
    } else if (isInserting) {
      context.missing(_examIdMeta);
    }
    if (data.containsKey('set_code')) {
      context.handle(
        _setCodeMeta,
        setCode.isAcceptableOrUnknown(data['set_code']!, _setCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_setCodeMeta);
    }
    if (data.containsKey('question_map_json')) {
      context.handle(
        _questionMapJsonMeta,
        questionMapJson.isAcceptableOrUnknown(
          data['question_map_json']!,
          _questionMapJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_questionMapJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {examId, setCode};
  @override
  QuestionSet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuestionSet(
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      examId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exam_id'],
      )!,
      setCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}set_code'],
      )!,
      questionMapJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_map_json'],
      )!,
    );
  }

  @override
  $QuestionSetsTable createAlias(String alias) {
    return $QuestionSetsTable(attachedDatabase, alias);
  }
}

class QuestionSet extends DataClass implements Insertable<QuestionSet> {
  final String tenantId;

  /// Sets die with their exam.
  final String examId;
  final String setCode;
  final String questionMapJson;
  const QuestionSet({
    required this.tenantId,
    required this.examId,
    required this.setCode,
    required this.questionMapJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tenant_id'] = Variable<String>(tenantId);
    map['exam_id'] = Variable<String>(examId);
    map['set_code'] = Variable<String>(setCode);
    map['question_map_json'] = Variable<String>(questionMapJson);
    return map;
  }

  QuestionSetsCompanion toCompanion(bool nullToAbsent) {
    return QuestionSetsCompanion(
      tenantId: Value(tenantId),
      examId: Value(examId),
      setCode: Value(setCode),
      questionMapJson: Value(questionMapJson),
    );
  }

  factory QuestionSet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuestionSet(
      tenantId: serializer.fromJson<String>(json['tenantId']),
      examId: serializer.fromJson<String>(json['examId']),
      setCode: serializer.fromJson<String>(json['setCode']),
      questionMapJson: serializer.fromJson<String>(json['questionMapJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tenantId': serializer.toJson<String>(tenantId),
      'examId': serializer.toJson<String>(examId),
      'setCode': serializer.toJson<String>(setCode),
      'questionMapJson': serializer.toJson<String>(questionMapJson),
    };
  }

  QuestionSet copyWith({
    String? tenantId,
    String? examId,
    String? setCode,
    String? questionMapJson,
  }) => QuestionSet(
    tenantId: tenantId ?? this.tenantId,
    examId: examId ?? this.examId,
    setCode: setCode ?? this.setCode,
    questionMapJson: questionMapJson ?? this.questionMapJson,
  );
  QuestionSet copyWithCompanion(QuestionSetsCompanion data) {
    return QuestionSet(
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      examId: data.examId.present ? data.examId.value : this.examId,
      setCode: data.setCode.present ? data.setCode.value : this.setCode,
      questionMapJson: data.questionMapJson.present
          ? data.questionMapJson.value
          : this.questionMapJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuestionSet(')
          ..write('tenantId: $tenantId, ')
          ..write('examId: $examId, ')
          ..write('setCode: $setCode, ')
          ..write('questionMapJson: $questionMapJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(tenantId, examId, setCode, questionMapJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuestionSet &&
          other.tenantId == this.tenantId &&
          other.examId == this.examId &&
          other.setCode == this.setCode &&
          other.questionMapJson == this.questionMapJson);
}

class QuestionSetsCompanion extends UpdateCompanion<QuestionSet> {
  final Value<String> tenantId;
  final Value<String> examId;
  final Value<String> setCode;
  final Value<String> questionMapJson;
  final Value<int> rowid;
  const QuestionSetsCompanion({
    this.tenantId = const Value.absent(),
    this.examId = const Value.absent(),
    this.setCode = const Value.absent(),
    this.questionMapJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuestionSetsCompanion.insert({
    required String tenantId,
    required String examId,
    required String setCode,
    required String questionMapJson,
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       examId = Value(examId),
       setCode = Value(setCode),
       questionMapJson = Value(questionMapJson);
  static Insertable<QuestionSet> custom({
    Expression<String>? tenantId,
    Expression<String>? examId,
    Expression<String>? setCode,
    Expression<String>? questionMapJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tenantId != null) 'tenant_id': tenantId,
      if (examId != null) 'exam_id': examId,
      if (setCode != null) 'set_code': setCode,
      if (questionMapJson != null) 'question_map_json': questionMapJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuestionSetsCompanion copyWith({
    Value<String>? tenantId,
    Value<String>? examId,
    Value<String>? setCode,
    Value<String>? questionMapJson,
    Value<int>? rowid,
  }) {
    return QuestionSetsCompanion(
      tenantId: tenantId ?? this.tenantId,
      examId: examId ?? this.examId,
      setCode: setCode ?? this.setCode,
      questionMapJson: questionMapJson ?? this.questionMapJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (examId.present) {
      map['exam_id'] = Variable<String>(examId.value);
    }
    if (setCode.present) {
      map['set_code'] = Variable<String>(setCode.value);
    }
    if (questionMapJson.present) {
      map['question_map_json'] = Variable<String>(questionMapJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuestionSetsCompanion(')
          ..write('tenantId: $tenantId, ')
          ..write('examId: $examId, ')
          ..write('setCode: $setCode, ')
          ..write('questionMapJson: $questionMapJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ScoringRulesTable extends ScoringRules
    with TableInfo<$ScoringRulesTable, ScoringRule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScoringRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  @override
  late final GeneratedColumnWithTypeConverter<ScoringStrategyKind, String>
  strategy = GeneratedColumn<String>(
    'strategy',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<ScoringStrategyKind>($ScoringRulesTable.$converterstrategy);
  static const VerificationMeta _paramsJsonMeta = const VerificationMeta(
    'paramsJson',
  );
  @override
  late final GeneratedColumn<String> paramsJson = GeneratedColumn<String>(
    'params_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tenantId,
    name,
    strategy,
    paramsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scoring_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScoringRule> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('params_json')) {
      context.handle(
        _paramsJsonMeta,
        paramsJson.isAcceptableOrUnknown(data['params_json']!, _paramsJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_paramsJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScoringRule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScoringRule(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      strategy: $ScoringRulesTable.$converterstrategy.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}strategy'],
        )!,
      ),
      paramsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}params_json'],
      )!,
    );
  }

  @override
  $ScoringRulesTable createAlias(String alias) {
    return $ScoringRulesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ScoringStrategyKind, String, String>
  $converterstrategy = const EnumNameConverter<ScoringStrategyKind>(
    ScoringStrategyKind.values,
  );
}

class ScoringRule extends DataClass implements Insertable<ScoringRule> {
  final String id;
  final String tenantId;
  final String name;
  final ScoringStrategyKind strategy;

  /// JSON params, e.g. `{'correct': 4, 'wrong': -1, 'unattempted': 0}`.
  final String paramsJson;
  const ScoringRule({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.strategy,
    required this.paramsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    map['name'] = Variable<String>(name);
    {
      map['strategy'] = Variable<String>(
        $ScoringRulesTable.$converterstrategy.toSql(strategy),
      );
    }
    map['params_json'] = Variable<String>(paramsJson);
    return map;
  }

  ScoringRulesCompanion toCompanion(bool nullToAbsent) {
    return ScoringRulesCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      name: Value(name),
      strategy: Value(strategy),
      paramsJson: Value(paramsJson),
    );
  }

  factory ScoringRule.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScoringRule(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      name: serializer.fromJson<String>(json['name']),
      strategy: $ScoringRulesTable.$converterstrategy.fromJson(
        serializer.fromJson<String>(json['strategy']),
      ),
      paramsJson: serializer.fromJson<String>(json['paramsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'name': serializer.toJson<String>(name),
      'strategy': serializer.toJson<String>(
        $ScoringRulesTable.$converterstrategy.toJson(strategy),
      ),
      'paramsJson': serializer.toJson<String>(paramsJson),
    };
  }

  ScoringRule copyWith({
    String? id,
    String? tenantId,
    String? name,
    ScoringStrategyKind? strategy,
    String? paramsJson,
  }) => ScoringRule(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    name: name ?? this.name,
    strategy: strategy ?? this.strategy,
    paramsJson: paramsJson ?? this.paramsJson,
  );
  ScoringRule copyWithCompanion(ScoringRulesCompanion data) {
    return ScoringRule(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      name: data.name.present ? data.name.value : this.name,
      strategy: data.strategy.present ? data.strategy.value : this.strategy,
      paramsJson: data.paramsJson.present
          ? data.paramsJson.value
          : this.paramsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScoringRule(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('name: $name, ')
          ..write('strategy: $strategy, ')
          ..write('paramsJson: $paramsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, tenantId, name, strategy, paramsJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScoringRule &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.name == this.name &&
          other.strategy == this.strategy &&
          other.paramsJson == this.paramsJson);
}

class ScoringRulesCompanion extends UpdateCompanion<ScoringRule> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String> name;
  final Value<ScoringStrategyKind> strategy;
  final Value<String> paramsJson;
  final Value<int> rowid;
  const ScoringRulesCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.name = const Value.absent(),
    this.strategy = const Value.absent(),
    this.paramsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScoringRulesCompanion.insert({
    this.id = const Value.absent(),
    required String tenantId,
    required String name,
    required ScoringStrategyKind strategy,
    required String paramsJson,
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       name = Value(name),
       strategy = Value(strategy),
       paramsJson = Value(paramsJson);
  static Insertable<ScoringRule> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? name,
    Expression<String>? strategy,
    Expression<String>? paramsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (name != null) 'name': name,
      if (strategy != null) 'strategy': strategy,
      if (paramsJson != null) 'params_json': paramsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScoringRulesCompanion copyWith({
    Value<String>? id,
    Value<String>? tenantId,
    Value<String>? name,
    Value<ScoringStrategyKind>? strategy,
    Value<String>? paramsJson,
    Value<int>? rowid,
  }) {
    return ScoringRulesCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      strategy: strategy ?? this.strategy,
      paramsJson: paramsJson ?? this.paramsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (strategy.present) {
      map['strategy'] = Variable<String>(
        $ScoringRulesTable.$converterstrategy.toSql(strategy.value),
      );
    }
    if (paramsJson.present) {
      map['params_json'] = Variable<String>(paramsJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScoringRulesCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('name: $name, ')
          ..write('strategy: $strategy, ')
          ..write('paramsJson: $paramsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AnswerKeyVersionsTable extends AnswerKeyVersions
    with TableInfo<$AnswerKeyVersionsTable, AnswerKeyVersion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnswerKeyVersionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _examIdMeta = const VerificationMeta('examId');
  @override
  late final GeneratedColumn<String> examId = GeneratedColumn<String>(
    'exam_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exams (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<KeyVersionStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('provisional'),
      ).withConverter<KeyVersionStatus>(
        $AnswerKeyVersionsTable.$converterstatus,
      );
  static const VerificationMeta _supersedesIdMeta = const VerificationMeta(
    'supersedesId',
  );
  @override
  late final GeneratedColumn<String> supersedesId = GeneratedColumn<String>(
    'supersedes_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES answer_key_versions (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> createdAt =
      GeneratedColumn<String>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        clientDefault: nowIsoUtc,
      ).withConverter<DateTime>($AnswerKeyVersionsTable.$convertercreatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tenantId,
    examId,
    version,
    status,
    supersedesId,
    createdBy,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'answer_key_versions';
  @override
  VerificationContext validateIntegrity(
    Insertable<AnswerKeyVersion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('exam_id')) {
      context.handle(
        _examIdMeta,
        examId.isAcceptableOrUnknown(data['exam_id']!, _examIdMeta),
      );
    } else if (isInserting) {
      context.missing(_examIdMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('supersedes_id')) {
      context.handle(
        _supersedesIdMeta,
        supersedesId.isAcceptableOrUnknown(
          data['supersedes_id']!,
          _supersedesIdMeta,
        ),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    } else if (isInserting) {
      context.missing(_createdByMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AnswerKeyVersion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnswerKeyVersion(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      examId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exam_id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      status: $AnswerKeyVersionsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      supersedesId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supersedes_id'],
      ),
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      )!,
      createdAt: $AnswerKeyVersionsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}created_at'],
        )!,
      ),
    );
  }

  @override
  $AnswerKeyVersionsTable createAlias(String alias) {
    return $AnswerKeyVersionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<KeyVersionStatus, String, String> $converterstatus =
      const EnumNameConverter<KeyVersionStatus>(KeyVersionStatus.values);
  static TypeConverter<DateTime, String> $convertercreatedAt =
      const IsoDateTimeConverter();
}

class AnswerKeyVersion extends DataClass
    implements Insertable<AnswerKeyVersion> {
  final String id;
  final String tenantId;

  /// Key versions die with their exam — unless results still reference them,
  /// in which case the RESTRICT on results blocks the delete (audit wins).
  final String examId;
  final int version;
  final KeyVersionStatus status;

  /// The version this one replaces, if any. SET NULL on delete because old
  /// versions are never deleted in practice and the chain must not block.
  final String? supersedesId;
  final String createdBy;
  final DateTime createdAt;
  const AnswerKeyVersion({
    required this.id,
    required this.tenantId,
    required this.examId,
    required this.version,
    required this.status,
    this.supersedesId,
    required this.createdBy,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    map['exam_id'] = Variable<String>(examId);
    map['version'] = Variable<int>(version);
    {
      map['status'] = Variable<String>(
        $AnswerKeyVersionsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || supersedesId != null) {
      map['supersedes_id'] = Variable<String>(supersedesId);
    }
    map['created_by'] = Variable<String>(createdBy);
    {
      map['created_at'] = Variable<String>(
        $AnswerKeyVersionsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    return map;
  }

  AnswerKeyVersionsCompanion toCompanion(bool nullToAbsent) {
    return AnswerKeyVersionsCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      examId: Value(examId),
      version: Value(version),
      status: Value(status),
      supersedesId: supersedesId == null && nullToAbsent
          ? const Value.absent()
          : Value(supersedesId),
      createdBy: Value(createdBy),
      createdAt: Value(createdAt),
    );
  }

  factory AnswerKeyVersion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnswerKeyVersion(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      examId: serializer.fromJson<String>(json['examId']),
      version: serializer.fromJson<int>(json['version']),
      status: $AnswerKeyVersionsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      supersedesId: serializer.fromJson<String?>(json['supersedesId']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'examId': serializer.toJson<String>(examId),
      'version': serializer.toJson<int>(version),
      'status': serializer.toJson<String>(
        $AnswerKeyVersionsTable.$converterstatus.toJson(status),
      ),
      'supersedesId': serializer.toJson<String?>(supersedesId),
      'createdBy': serializer.toJson<String>(createdBy),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AnswerKeyVersion copyWith({
    String? id,
    String? tenantId,
    String? examId,
    int? version,
    KeyVersionStatus? status,
    Value<String?> supersedesId = const Value.absent(),
    String? createdBy,
    DateTime? createdAt,
  }) => AnswerKeyVersion(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    examId: examId ?? this.examId,
    version: version ?? this.version,
    status: status ?? this.status,
    supersedesId: supersedesId.present ? supersedesId.value : this.supersedesId,
    createdBy: createdBy ?? this.createdBy,
    createdAt: createdAt ?? this.createdAt,
  );
  AnswerKeyVersion copyWithCompanion(AnswerKeyVersionsCompanion data) {
    return AnswerKeyVersion(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      examId: data.examId.present ? data.examId.value : this.examId,
      version: data.version.present ? data.version.value : this.version,
      status: data.status.present ? data.status.value : this.status,
      supersedesId: data.supersedesId.present
          ? data.supersedesId.value
          : this.supersedesId,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnswerKeyVersion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('examId: $examId, ')
          ..write('version: $version, ')
          ..write('status: $status, ')
          ..write('supersedesId: $supersedesId, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tenantId,
    examId,
    version,
    status,
    supersedesId,
    createdBy,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnswerKeyVersion &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.examId == this.examId &&
          other.version == this.version &&
          other.status == this.status &&
          other.supersedesId == this.supersedesId &&
          other.createdBy == this.createdBy &&
          other.createdAt == this.createdAt);
}

class AnswerKeyVersionsCompanion extends UpdateCompanion<AnswerKeyVersion> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String> examId;
  final Value<int> version;
  final Value<KeyVersionStatus> status;
  final Value<String?> supersedesId;
  final Value<String> createdBy;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AnswerKeyVersionsCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.examId = const Value.absent(),
    this.version = const Value.absent(),
    this.status = const Value.absent(),
    this.supersedesId = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AnswerKeyVersionsCompanion.insert({
    this.id = const Value.absent(),
    required String tenantId,
    required String examId,
    required int version,
    this.status = const Value.absent(),
    this.supersedesId = const Value.absent(),
    required String createdBy,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       examId = Value(examId),
       version = Value(version),
       createdBy = Value(createdBy);
  static Insertable<AnswerKeyVersion> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? examId,
    Expression<int>? version,
    Expression<String>? status,
    Expression<String>? supersedesId,
    Expression<String>? createdBy,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (examId != null) 'exam_id': examId,
      if (version != null) 'version': version,
      if (status != null) 'status': status,
      if (supersedesId != null) 'supersedes_id': supersedesId,
      if (createdBy != null) 'created_by': createdBy,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AnswerKeyVersionsCompanion copyWith({
    Value<String>? id,
    Value<String>? tenantId,
    Value<String>? examId,
    Value<int>? version,
    Value<KeyVersionStatus>? status,
    Value<String?>? supersedesId,
    Value<String>? createdBy,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return AnswerKeyVersionsCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      examId: examId ?? this.examId,
      version: version ?? this.version,
      status: status ?? this.status,
      supersedesId: supersedesId ?? this.supersedesId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (examId.present) {
      map['exam_id'] = Variable<String>(examId.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $AnswerKeyVersionsTable.$converterstatus.toSql(status.value),
      );
    }
    if (supersedesId.present) {
      map['supersedes_id'] = Variable<String>(supersedesId.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(
        $AnswerKeyVersionsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnswerKeyVersionsCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('examId: $examId, ')
          ..write('version: $version, ')
          ..write('status: $status, ')
          ..write('supersedesId: $supersedesId, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AnswerKeyEntriesTable extends AnswerKeyEntries
    with TableInfo<$AnswerKeyEntriesTable, AnswerKeyEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnswerKeyEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyVersionIdMeta = const VerificationMeta(
    'keyVersionId',
  );
  @override
  late final GeneratedColumn<String> keyVersionId = GeneratedColumn<String>(
    'key_version_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES answer_key_versions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _setCodeMeta = const VerificationMeta(
    'setCode',
  );
  @override
  late final GeneratedColumn<String> setCode = GeneratedColumn<String>(
    'set_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionIdMeta = const VerificationMeta(
    'questionId',
  );
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
    'question_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _correctOptionsJsonMeta =
      const VerificationMeta('correctOptionsJson');
  @override
  late final GeneratedColumn<String> correctOptionsJson =
      GeneratedColumn<String>(
        'correct_options_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _correctIntegerMeta = const VerificationMeta(
    'correctInteger',
  );
  @override
  late final GeneratedColumn<int> correctInteger = GeneratedColumn<int>(
    'correct_integer',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<KeyEntryState, String> state =
      GeneratedColumn<String>(
        'state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('normal'),
      ).withConverter<KeyEntryState>($AnswerKeyEntriesTable.$converterstate);
  static const VerificationMeta _scoringRuleIdMeta = const VerificationMeta(
    'scoringRuleId',
  );
  @override
  late final GeneratedColumn<String> scoringRuleId = GeneratedColumn<String>(
    'scoring_rule_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES scoring_rules (id) ON DELETE SET NULL',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    tenantId,
    keyVersionId,
    setCode,
    questionId,
    correctOptionsJson,
    correctInteger,
    state,
    scoringRuleId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'answer_key_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<AnswerKeyEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('key_version_id')) {
      context.handle(
        _keyVersionIdMeta,
        keyVersionId.isAcceptableOrUnknown(
          data['key_version_id']!,
          _keyVersionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_keyVersionIdMeta);
    }
    if (data.containsKey('set_code')) {
      context.handle(
        _setCodeMeta,
        setCode.isAcceptableOrUnknown(data['set_code']!, _setCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_setCodeMeta);
    }
    if (data.containsKey('question_id')) {
      context.handle(
        _questionIdMeta,
        questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('correct_options_json')) {
      context.handle(
        _correctOptionsJsonMeta,
        correctOptionsJson.isAcceptableOrUnknown(
          data['correct_options_json']!,
          _correctOptionsJsonMeta,
        ),
      );
    }
    if (data.containsKey('correct_integer')) {
      context.handle(
        _correctIntegerMeta,
        correctInteger.isAcceptableOrUnknown(
          data['correct_integer']!,
          _correctIntegerMeta,
        ),
      );
    }
    if (data.containsKey('scoring_rule_id')) {
      context.handle(
        _scoringRuleIdMeta,
        scoringRuleId.isAcceptableOrUnknown(
          data['scoring_rule_id']!,
          _scoringRuleIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {keyVersionId, setCode, questionId};
  @override
  AnswerKeyEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnswerKeyEntry(
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      keyVersionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key_version_id'],
      )!,
      setCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}set_code'],
      )!,
      questionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_id'],
      )!,
      correctOptionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}correct_options_json'],
      )!,
      correctInteger: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct_integer'],
      ),
      state: $AnswerKeyEntriesTable.$converterstate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}state'],
        )!,
      ),
      scoringRuleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scoring_rule_id'],
      ),
    );
  }

  @override
  $AnswerKeyEntriesTable createAlias(String alias) {
    return $AnswerKeyEntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<KeyEntryState, String, String> $converterstate =
      const EnumNameConverter<KeyEntryState>(KeyEntryState.values);
}

class AnswerKeyEntry extends DataClass implements Insertable<AnswerKeyEntry> {
  final String tenantId;

  /// Entries die with their version.
  final String keyVersionId;

  /// Set code ('A'..'D', or '' for single-set papers).
  final String setCode;

  /// Canonical question id, e.g. 'q17'.
  final String questionId;

  /// JSON array of correct option indexes into the bubble row,
  /// e.g. '[0]' or '[0, 2]' for multi-correct.
  final String correctOptionsJson;

  /// For integer-digit questions (JEE-Adv numeric), if applicable.
  final int? correctInteger;

  /// NTA key-correction state, first-class (plan §5).
  final KeyEntryState state;

  /// Per-question scoring override, if any.
  final String? scoringRuleId;
  const AnswerKeyEntry({
    required this.tenantId,
    required this.keyVersionId,
    required this.setCode,
    required this.questionId,
    required this.correctOptionsJson,
    this.correctInteger,
    required this.state,
    this.scoringRuleId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tenant_id'] = Variable<String>(tenantId);
    map['key_version_id'] = Variable<String>(keyVersionId);
    map['set_code'] = Variable<String>(setCode);
    map['question_id'] = Variable<String>(questionId);
    map['correct_options_json'] = Variable<String>(correctOptionsJson);
    if (!nullToAbsent || correctInteger != null) {
      map['correct_integer'] = Variable<int>(correctInteger);
    }
    {
      map['state'] = Variable<String>(
        $AnswerKeyEntriesTable.$converterstate.toSql(state),
      );
    }
    if (!nullToAbsent || scoringRuleId != null) {
      map['scoring_rule_id'] = Variable<String>(scoringRuleId);
    }
    return map;
  }

  AnswerKeyEntriesCompanion toCompanion(bool nullToAbsent) {
    return AnswerKeyEntriesCompanion(
      tenantId: Value(tenantId),
      keyVersionId: Value(keyVersionId),
      setCode: Value(setCode),
      questionId: Value(questionId),
      correctOptionsJson: Value(correctOptionsJson),
      correctInteger: correctInteger == null && nullToAbsent
          ? const Value.absent()
          : Value(correctInteger),
      state: Value(state),
      scoringRuleId: scoringRuleId == null && nullToAbsent
          ? const Value.absent()
          : Value(scoringRuleId),
    );
  }

  factory AnswerKeyEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnswerKeyEntry(
      tenantId: serializer.fromJson<String>(json['tenantId']),
      keyVersionId: serializer.fromJson<String>(json['keyVersionId']),
      setCode: serializer.fromJson<String>(json['setCode']),
      questionId: serializer.fromJson<String>(json['questionId']),
      correctOptionsJson: serializer.fromJson<String>(
        json['correctOptionsJson'],
      ),
      correctInteger: serializer.fromJson<int?>(json['correctInteger']),
      state: $AnswerKeyEntriesTable.$converterstate.fromJson(
        serializer.fromJson<String>(json['state']),
      ),
      scoringRuleId: serializer.fromJson<String?>(json['scoringRuleId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tenantId': serializer.toJson<String>(tenantId),
      'keyVersionId': serializer.toJson<String>(keyVersionId),
      'setCode': serializer.toJson<String>(setCode),
      'questionId': serializer.toJson<String>(questionId),
      'correctOptionsJson': serializer.toJson<String>(correctOptionsJson),
      'correctInteger': serializer.toJson<int?>(correctInteger),
      'state': serializer.toJson<String>(
        $AnswerKeyEntriesTable.$converterstate.toJson(state),
      ),
      'scoringRuleId': serializer.toJson<String?>(scoringRuleId),
    };
  }

  AnswerKeyEntry copyWith({
    String? tenantId,
    String? keyVersionId,
    String? setCode,
    String? questionId,
    String? correctOptionsJson,
    Value<int?> correctInteger = const Value.absent(),
    KeyEntryState? state,
    Value<String?> scoringRuleId = const Value.absent(),
  }) => AnswerKeyEntry(
    tenantId: tenantId ?? this.tenantId,
    keyVersionId: keyVersionId ?? this.keyVersionId,
    setCode: setCode ?? this.setCode,
    questionId: questionId ?? this.questionId,
    correctOptionsJson: correctOptionsJson ?? this.correctOptionsJson,
    correctInteger: correctInteger.present
        ? correctInteger.value
        : this.correctInteger,
    state: state ?? this.state,
    scoringRuleId: scoringRuleId.present
        ? scoringRuleId.value
        : this.scoringRuleId,
  );
  AnswerKeyEntry copyWithCompanion(AnswerKeyEntriesCompanion data) {
    return AnswerKeyEntry(
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      keyVersionId: data.keyVersionId.present
          ? data.keyVersionId.value
          : this.keyVersionId,
      setCode: data.setCode.present ? data.setCode.value : this.setCode,
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
      correctOptionsJson: data.correctOptionsJson.present
          ? data.correctOptionsJson.value
          : this.correctOptionsJson,
      correctInteger: data.correctInteger.present
          ? data.correctInteger.value
          : this.correctInteger,
      state: data.state.present ? data.state.value : this.state,
      scoringRuleId: data.scoringRuleId.present
          ? data.scoringRuleId.value
          : this.scoringRuleId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnswerKeyEntry(')
          ..write('tenantId: $tenantId, ')
          ..write('keyVersionId: $keyVersionId, ')
          ..write('setCode: $setCode, ')
          ..write('questionId: $questionId, ')
          ..write('correctOptionsJson: $correctOptionsJson, ')
          ..write('correctInteger: $correctInteger, ')
          ..write('state: $state, ')
          ..write('scoringRuleId: $scoringRuleId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    tenantId,
    keyVersionId,
    setCode,
    questionId,
    correctOptionsJson,
    correctInteger,
    state,
    scoringRuleId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnswerKeyEntry &&
          other.tenantId == this.tenantId &&
          other.keyVersionId == this.keyVersionId &&
          other.setCode == this.setCode &&
          other.questionId == this.questionId &&
          other.correctOptionsJson == this.correctOptionsJson &&
          other.correctInteger == this.correctInteger &&
          other.state == this.state &&
          other.scoringRuleId == this.scoringRuleId);
}

class AnswerKeyEntriesCompanion extends UpdateCompanion<AnswerKeyEntry> {
  final Value<String> tenantId;
  final Value<String> keyVersionId;
  final Value<String> setCode;
  final Value<String> questionId;
  final Value<String> correctOptionsJson;
  final Value<int?> correctInteger;
  final Value<KeyEntryState> state;
  final Value<String?> scoringRuleId;
  final Value<int> rowid;
  const AnswerKeyEntriesCompanion({
    this.tenantId = const Value.absent(),
    this.keyVersionId = const Value.absent(),
    this.setCode = const Value.absent(),
    this.questionId = const Value.absent(),
    this.correctOptionsJson = const Value.absent(),
    this.correctInteger = const Value.absent(),
    this.state = const Value.absent(),
    this.scoringRuleId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AnswerKeyEntriesCompanion.insert({
    required String tenantId,
    required String keyVersionId,
    required String setCode,
    required String questionId,
    this.correctOptionsJson = const Value.absent(),
    this.correctInteger = const Value.absent(),
    this.state = const Value.absent(),
    this.scoringRuleId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       keyVersionId = Value(keyVersionId),
       setCode = Value(setCode),
       questionId = Value(questionId);
  static Insertable<AnswerKeyEntry> custom({
    Expression<String>? tenantId,
    Expression<String>? keyVersionId,
    Expression<String>? setCode,
    Expression<String>? questionId,
    Expression<String>? correctOptionsJson,
    Expression<int>? correctInteger,
    Expression<String>? state,
    Expression<String>? scoringRuleId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tenantId != null) 'tenant_id': tenantId,
      if (keyVersionId != null) 'key_version_id': keyVersionId,
      if (setCode != null) 'set_code': setCode,
      if (questionId != null) 'question_id': questionId,
      if (correctOptionsJson != null)
        'correct_options_json': correctOptionsJson,
      if (correctInteger != null) 'correct_integer': correctInteger,
      if (state != null) 'state': state,
      if (scoringRuleId != null) 'scoring_rule_id': scoringRuleId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AnswerKeyEntriesCompanion copyWith({
    Value<String>? tenantId,
    Value<String>? keyVersionId,
    Value<String>? setCode,
    Value<String>? questionId,
    Value<String>? correctOptionsJson,
    Value<int?>? correctInteger,
    Value<KeyEntryState>? state,
    Value<String?>? scoringRuleId,
    Value<int>? rowid,
  }) {
    return AnswerKeyEntriesCompanion(
      tenantId: tenantId ?? this.tenantId,
      keyVersionId: keyVersionId ?? this.keyVersionId,
      setCode: setCode ?? this.setCode,
      questionId: questionId ?? this.questionId,
      correctOptionsJson: correctOptionsJson ?? this.correctOptionsJson,
      correctInteger: correctInteger ?? this.correctInteger,
      state: state ?? this.state,
      scoringRuleId: scoringRuleId ?? this.scoringRuleId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (keyVersionId.present) {
      map['key_version_id'] = Variable<String>(keyVersionId.value);
    }
    if (setCode.present) {
      map['set_code'] = Variable<String>(setCode.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (correctOptionsJson.present) {
      map['correct_options_json'] = Variable<String>(correctOptionsJson.value);
    }
    if (correctInteger.present) {
      map['correct_integer'] = Variable<int>(correctInteger.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(
        $AnswerKeyEntriesTable.$converterstate.toSql(state.value),
      );
    }
    if (scoringRuleId.present) {
      map['scoring_rule_id'] = Variable<String>(scoringRuleId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnswerKeyEntriesCompanion(')
          ..write('tenantId: $tenantId, ')
          ..write('keyVersionId: $keyVersionId, ')
          ..write('setCode: $setCode, ')
          ..write('questionId: $questionId, ')
          ..write('correctOptionsJson: $correctOptionsJson, ')
          ..write('correctInteger: $correctInteger, ')
          ..write('state: $state, ')
          ..write('scoringRuleId: $scoringRuleId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ScansTable extends Scans with TableInfo<$ScansTable, Scan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _examIdMeta = const VerificationMeta('examId');
  @override
  late final GeneratedColumn<String> examId = GeneratedColumn<String>(
    'exam_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exams (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _studentIdMeta = const VerificationMeta(
    'studentId',
  );
  @override
  late final GeneratedColumn<String> studentId = GeneratedColumn<String>(
    'student_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES students (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _rollNoReadMeta = const VerificationMeta(
    'rollNoRead',
  );
  @override
  late final GeneratedColumn<String> rollNoRead = GeneratedColumn<String>(
    'roll_no_read',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rollConfidenceMeta = const VerificationMeta(
    'rollConfidence',
  );
  @override
  late final GeneratedColumn<double> rollConfidence = GeneratedColumn<double>(
    'roll_confidence',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _setCodeReadMeta = const VerificationMeta(
    'setCodeRead',
  );
  @override
  late final GeneratedColumn<String> setCodeRead = GeneratedColumn<String>(
    'set_code_read',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _layoutVersionMeta = const VerificationMeta(
    'layoutVersion',
  );
  @override
  late final GeneratedColumn<int> layoutVersion = GeneratedColumn<int>(
    'layout_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thresholdConfigIdMeta = const VerificationMeta(
    'thresholdConfigId',
  );
  @override
  late final GeneratedColumn<String> thresholdConfigId =
      GeneratedColumn<String>(
        'threshold_config_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> capturedAt =
      GeneratedColumn<String>(
        'captured_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        clientDefault: nowIsoUtc,
      ).withConverter<DateTime>($ScansTable.$convertercapturedAt);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _warpedImagePathMeta = const VerificationMeta(
    'warpedImagePath',
  );
  @override
  late final GeneratedColumn<String> warpedImagePath = GeneratedColumn<String>(
    'warped_image_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thumbPathMeta = const VerificationMeta(
    'thumbPath',
  );
  @override
  late final GeneratedColumn<String> thumbPath = GeneratedColumn<String>(
    'thumb_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _annotatedPathMeta = const VerificationMeta(
    'annotatedPath',
  );
  @override
  late final GeneratedColumn<String> annotatedPath = GeneratedColumn<String>(
    'annotated_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalPathMeta = const VerificationMeta(
    'originalPath',
  );
  @override
  late final GeneratedColumn<String> originalPath = GeneratedColumn<String>(
    'original_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sheetConfidenceMeta = const VerificationMeta(
    'sheetConfidence',
  );
  @override
  late final GeneratedColumn<double> sheetConfidence = GeneratedColumn<double>(
    'sheet_confidence',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gateReportJsonMeta = const VerificationMeta(
    'gateReportJson',
  );
  @override
  late final GeneratedColumn<String> gateReportJson = GeneratedColumn<String>(
    'gate_report_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _curlFlagMeta = const VerificationMeta(
    'curlFlag',
  );
  @override
  late final GeneratedColumn<bool> curlFlag = GeneratedColumn<bool>(
    'curl_flag',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("curl_flag" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<ScanStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('needsReview'),
      ).withConverter<ScanStatus>($ScansTable.$converterstatus);
  @override
  late final GeneratedColumnWithTypeConverter<SyncState, String> syncState =
      GeneratedColumn<String>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('pending'),
      ).withConverter<SyncState>($ScansTable.$convertersyncState);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tenantId,
    examId,
    studentId,
    rollNoRead,
    rollConfidence,
    setCodeRead,
    layoutVersion,
    thresholdConfigId,
    capturedAt,
    deviceId,
    warpedImagePath,
    thumbPath,
    annotatedPath,
    originalPath,
    sheetConfidence,
    gateReportJson,
    curlFlag,
    status,
    syncState,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scans';
  @override
  VerificationContext validateIntegrity(
    Insertable<Scan> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('exam_id')) {
      context.handle(
        _examIdMeta,
        examId.isAcceptableOrUnknown(data['exam_id']!, _examIdMeta),
      );
    } else if (isInserting) {
      context.missing(_examIdMeta);
    }
    if (data.containsKey('student_id')) {
      context.handle(
        _studentIdMeta,
        studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta),
      );
    }
    if (data.containsKey('roll_no_read')) {
      context.handle(
        _rollNoReadMeta,
        rollNoRead.isAcceptableOrUnknown(
          data['roll_no_read']!,
          _rollNoReadMeta,
        ),
      );
    }
    if (data.containsKey('roll_confidence')) {
      context.handle(
        _rollConfidenceMeta,
        rollConfidence.isAcceptableOrUnknown(
          data['roll_confidence']!,
          _rollConfidenceMeta,
        ),
      );
    }
    if (data.containsKey('set_code_read')) {
      context.handle(
        _setCodeReadMeta,
        setCodeRead.isAcceptableOrUnknown(
          data['set_code_read']!,
          _setCodeReadMeta,
        ),
      );
    }
    if (data.containsKey('layout_version')) {
      context.handle(
        _layoutVersionMeta,
        layoutVersion.isAcceptableOrUnknown(
          data['layout_version']!,
          _layoutVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_layoutVersionMeta);
    }
    if (data.containsKey('threshold_config_id')) {
      context.handle(
        _thresholdConfigIdMeta,
        thresholdConfigId.isAcceptableOrUnknown(
          data['threshold_config_id']!,
          _thresholdConfigIdMeta,
        ),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('warped_image_path')) {
      context.handle(
        _warpedImagePathMeta,
        warpedImagePath.isAcceptableOrUnknown(
          data['warped_image_path']!,
          _warpedImagePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_warpedImagePathMeta);
    }
    if (data.containsKey('thumb_path')) {
      context.handle(
        _thumbPathMeta,
        thumbPath.isAcceptableOrUnknown(data['thumb_path']!, _thumbPathMeta),
      );
    } else if (isInserting) {
      context.missing(_thumbPathMeta);
    }
    if (data.containsKey('annotated_path')) {
      context.handle(
        _annotatedPathMeta,
        annotatedPath.isAcceptableOrUnknown(
          data['annotated_path']!,
          _annotatedPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_annotatedPathMeta);
    }
    if (data.containsKey('original_path')) {
      context.handle(
        _originalPathMeta,
        originalPath.isAcceptableOrUnknown(
          data['original_path']!,
          _originalPathMeta,
        ),
      );
    }
    if (data.containsKey('sheet_confidence')) {
      context.handle(
        _sheetConfidenceMeta,
        sheetConfidence.isAcceptableOrUnknown(
          data['sheet_confidence']!,
          _sheetConfidenceMeta,
        ),
      );
    }
    if (data.containsKey('gate_report_json')) {
      context.handle(
        _gateReportJsonMeta,
        gateReportJson.isAcceptableOrUnknown(
          data['gate_report_json']!,
          _gateReportJsonMeta,
        ),
      );
    }
    if (data.containsKey('curl_flag')) {
      context.handle(
        _curlFlagMeta,
        curlFlag.isAcceptableOrUnknown(data['curl_flag']!, _curlFlagMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Scan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Scan(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      examId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exam_id'],
      )!,
      studentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}student_id'],
      ),
      rollNoRead: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}roll_no_read'],
      ),
      rollConfidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}roll_confidence'],
      ),
      setCodeRead: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}set_code_read'],
      ),
      layoutVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}layout_version'],
      )!,
      thresholdConfigId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}threshold_config_id'],
      ),
      capturedAt: $ScansTable.$convertercapturedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}captured_at'],
        )!,
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
      warpedImagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}warped_image_path'],
      )!,
      thumbPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumb_path'],
      )!,
      annotatedPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}annotated_path'],
      )!,
      originalPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_path'],
      ),
      sheetConfidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sheet_confidence'],
      ),
      gateReportJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gate_report_json'],
      )!,
      curlFlag: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}curl_flag'],
      )!,
      status: $ScansTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      syncState: $ScansTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
    );
  }

  @override
  $ScansTable createAlias(String alias) {
    return $ScansTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, String> $convertercapturedAt =
      const IsoDateTimeConverter();
  static JsonTypeConverter2<ScanStatus, String, String> $converterstatus =
      const EnumNameConverter<ScanStatus>(ScanStatus.values);
  static JsonTypeConverter2<SyncState, String, String> $convertersyncState =
      const EnumNameConverter<SyncState>(SyncState.values);
}

class Scan extends DataClass implements Insertable<Scan> {
  final String id;
  final String tenantId;

  /// Exams with scans are never silently deleted.
  final String examId;

  /// Resolved roster match; NULL until roll+roster agree or a human confirms.
  /// SET NULL: the sheet evidence (roll read, images) outlives the roster row.
  final String? studentId;

  /// Raw decoded roll digits — kept even after resolution, as evidence.
  final String? rollNoRead;
  final double? rollConfidence;

  /// Bubbled set code ('A'..'D'); blank/multi route to mandatory review.
  final String? setCodeRead;

  /// The layout version this sheet was read against (from the QR).
  final int layoutVersion;

  /// Threshold-config id (omr_detect); TEXT id, no FK — the thresholds table
  /// belongs to the detection package, not this schema.
  final String? thresholdConfigId;
  final DateTime capturedAt;
  final String? deviceId;

  /// Retained image set (plan risk #9): warped grayscale + annotated thumb
  /// always; the 12MP original only during the retention grace window.
  final String warpedImagePath;
  final String thumbPath;
  final String annotatedPath;
  final String? originalPath;

  /// Per-sheet confidence from the aggregator (plan §3 stage 10).
  final double? sheetConfidence;

  /// JSON: the five capture-gate scores at shutter time.
  final String gateReportJson;

  /// Timing-track curvature residual exceeded tolerance (plan §3 stage 4).
  final bool curlFlag;

  /// Safe-by-default: an unrouted scan is a review candidate, never a mark.
  final ScanStatus status;
  final SyncState syncState;
  const Scan({
    required this.id,
    required this.tenantId,
    required this.examId,
    this.studentId,
    this.rollNoRead,
    this.rollConfidence,
    this.setCodeRead,
    required this.layoutVersion,
    this.thresholdConfigId,
    required this.capturedAt,
    this.deviceId,
    required this.warpedImagePath,
    required this.thumbPath,
    required this.annotatedPath,
    this.originalPath,
    this.sheetConfidence,
    required this.gateReportJson,
    required this.curlFlag,
    required this.status,
    required this.syncState,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    map['exam_id'] = Variable<String>(examId);
    if (!nullToAbsent || studentId != null) {
      map['student_id'] = Variable<String>(studentId);
    }
    if (!nullToAbsent || rollNoRead != null) {
      map['roll_no_read'] = Variable<String>(rollNoRead);
    }
    if (!nullToAbsent || rollConfidence != null) {
      map['roll_confidence'] = Variable<double>(rollConfidence);
    }
    if (!nullToAbsent || setCodeRead != null) {
      map['set_code_read'] = Variable<String>(setCodeRead);
    }
    map['layout_version'] = Variable<int>(layoutVersion);
    if (!nullToAbsent || thresholdConfigId != null) {
      map['threshold_config_id'] = Variable<String>(thresholdConfigId);
    }
    {
      map['captured_at'] = Variable<String>(
        $ScansTable.$convertercapturedAt.toSql(capturedAt),
      );
    }
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    map['warped_image_path'] = Variable<String>(warpedImagePath);
    map['thumb_path'] = Variable<String>(thumbPath);
    map['annotated_path'] = Variable<String>(annotatedPath);
    if (!nullToAbsent || originalPath != null) {
      map['original_path'] = Variable<String>(originalPath);
    }
    if (!nullToAbsent || sheetConfidence != null) {
      map['sheet_confidence'] = Variable<double>(sheetConfidence);
    }
    map['gate_report_json'] = Variable<String>(gateReportJson);
    map['curl_flag'] = Variable<bool>(curlFlag);
    {
      map['status'] = Variable<String>(
        $ScansTable.$converterstatus.toSql(status),
      );
    }
    {
      map['sync_state'] = Variable<String>(
        $ScansTable.$convertersyncState.toSql(syncState),
      );
    }
    return map;
  }

  ScansCompanion toCompanion(bool nullToAbsent) {
    return ScansCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      examId: Value(examId),
      studentId: studentId == null && nullToAbsent
          ? const Value.absent()
          : Value(studentId),
      rollNoRead: rollNoRead == null && nullToAbsent
          ? const Value.absent()
          : Value(rollNoRead),
      rollConfidence: rollConfidence == null && nullToAbsent
          ? const Value.absent()
          : Value(rollConfidence),
      setCodeRead: setCodeRead == null && nullToAbsent
          ? const Value.absent()
          : Value(setCodeRead),
      layoutVersion: Value(layoutVersion),
      thresholdConfigId: thresholdConfigId == null && nullToAbsent
          ? const Value.absent()
          : Value(thresholdConfigId),
      capturedAt: Value(capturedAt),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      warpedImagePath: Value(warpedImagePath),
      thumbPath: Value(thumbPath),
      annotatedPath: Value(annotatedPath),
      originalPath: originalPath == null && nullToAbsent
          ? const Value.absent()
          : Value(originalPath),
      sheetConfidence: sheetConfidence == null && nullToAbsent
          ? const Value.absent()
          : Value(sheetConfidence),
      gateReportJson: Value(gateReportJson),
      curlFlag: Value(curlFlag),
      status: Value(status),
      syncState: Value(syncState),
    );
  }

  factory Scan.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Scan(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      examId: serializer.fromJson<String>(json['examId']),
      studentId: serializer.fromJson<String?>(json['studentId']),
      rollNoRead: serializer.fromJson<String?>(json['rollNoRead']),
      rollConfidence: serializer.fromJson<double?>(json['rollConfidence']),
      setCodeRead: serializer.fromJson<String?>(json['setCodeRead']),
      layoutVersion: serializer.fromJson<int>(json['layoutVersion']),
      thresholdConfigId: serializer.fromJson<String?>(
        json['thresholdConfigId'],
      ),
      capturedAt: serializer.fromJson<DateTime>(json['capturedAt']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      warpedImagePath: serializer.fromJson<String>(json['warpedImagePath']),
      thumbPath: serializer.fromJson<String>(json['thumbPath']),
      annotatedPath: serializer.fromJson<String>(json['annotatedPath']),
      originalPath: serializer.fromJson<String?>(json['originalPath']),
      sheetConfidence: serializer.fromJson<double?>(json['sheetConfidence']),
      gateReportJson: serializer.fromJson<String>(json['gateReportJson']),
      curlFlag: serializer.fromJson<bool>(json['curlFlag']),
      status: $ScansTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      syncState: $ScansTable.$convertersyncState.fromJson(
        serializer.fromJson<String>(json['syncState']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'examId': serializer.toJson<String>(examId),
      'studentId': serializer.toJson<String?>(studentId),
      'rollNoRead': serializer.toJson<String?>(rollNoRead),
      'rollConfidence': serializer.toJson<double?>(rollConfidence),
      'setCodeRead': serializer.toJson<String?>(setCodeRead),
      'layoutVersion': serializer.toJson<int>(layoutVersion),
      'thresholdConfigId': serializer.toJson<String?>(thresholdConfigId),
      'capturedAt': serializer.toJson<DateTime>(capturedAt),
      'deviceId': serializer.toJson<String?>(deviceId),
      'warpedImagePath': serializer.toJson<String>(warpedImagePath),
      'thumbPath': serializer.toJson<String>(thumbPath),
      'annotatedPath': serializer.toJson<String>(annotatedPath),
      'originalPath': serializer.toJson<String?>(originalPath),
      'sheetConfidence': serializer.toJson<double?>(sheetConfidence),
      'gateReportJson': serializer.toJson<String>(gateReportJson),
      'curlFlag': serializer.toJson<bool>(curlFlag),
      'status': serializer.toJson<String>(
        $ScansTable.$converterstatus.toJson(status),
      ),
      'syncState': serializer.toJson<String>(
        $ScansTable.$convertersyncState.toJson(syncState),
      ),
    };
  }

  Scan copyWith({
    String? id,
    String? tenantId,
    String? examId,
    Value<String?> studentId = const Value.absent(),
    Value<String?> rollNoRead = const Value.absent(),
    Value<double?> rollConfidence = const Value.absent(),
    Value<String?> setCodeRead = const Value.absent(),
    int? layoutVersion,
    Value<String?> thresholdConfigId = const Value.absent(),
    DateTime? capturedAt,
    Value<String?> deviceId = const Value.absent(),
    String? warpedImagePath,
    String? thumbPath,
    String? annotatedPath,
    Value<String?> originalPath = const Value.absent(),
    Value<double?> sheetConfidence = const Value.absent(),
    String? gateReportJson,
    bool? curlFlag,
    ScanStatus? status,
    SyncState? syncState,
  }) => Scan(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    examId: examId ?? this.examId,
    studentId: studentId.present ? studentId.value : this.studentId,
    rollNoRead: rollNoRead.present ? rollNoRead.value : this.rollNoRead,
    rollConfidence: rollConfidence.present
        ? rollConfidence.value
        : this.rollConfidence,
    setCodeRead: setCodeRead.present ? setCodeRead.value : this.setCodeRead,
    layoutVersion: layoutVersion ?? this.layoutVersion,
    thresholdConfigId: thresholdConfigId.present
        ? thresholdConfigId.value
        : this.thresholdConfigId,
    capturedAt: capturedAt ?? this.capturedAt,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
    warpedImagePath: warpedImagePath ?? this.warpedImagePath,
    thumbPath: thumbPath ?? this.thumbPath,
    annotatedPath: annotatedPath ?? this.annotatedPath,
    originalPath: originalPath.present ? originalPath.value : this.originalPath,
    sheetConfidence: sheetConfidence.present
        ? sheetConfidence.value
        : this.sheetConfidence,
    gateReportJson: gateReportJson ?? this.gateReportJson,
    curlFlag: curlFlag ?? this.curlFlag,
    status: status ?? this.status,
    syncState: syncState ?? this.syncState,
  );
  Scan copyWithCompanion(ScansCompanion data) {
    return Scan(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      examId: data.examId.present ? data.examId.value : this.examId,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      rollNoRead: data.rollNoRead.present
          ? data.rollNoRead.value
          : this.rollNoRead,
      rollConfidence: data.rollConfidence.present
          ? data.rollConfidence.value
          : this.rollConfidence,
      setCodeRead: data.setCodeRead.present
          ? data.setCodeRead.value
          : this.setCodeRead,
      layoutVersion: data.layoutVersion.present
          ? data.layoutVersion.value
          : this.layoutVersion,
      thresholdConfigId: data.thresholdConfigId.present
          ? data.thresholdConfigId.value
          : this.thresholdConfigId,
      capturedAt: data.capturedAt.present
          ? data.capturedAt.value
          : this.capturedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      warpedImagePath: data.warpedImagePath.present
          ? data.warpedImagePath.value
          : this.warpedImagePath,
      thumbPath: data.thumbPath.present ? data.thumbPath.value : this.thumbPath,
      annotatedPath: data.annotatedPath.present
          ? data.annotatedPath.value
          : this.annotatedPath,
      originalPath: data.originalPath.present
          ? data.originalPath.value
          : this.originalPath,
      sheetConfidence: data.sheetConfidence.present
          ? data.sheetConfidence.value
          : this.sheetConfidence,
      gateReportJson: data.gateReportJson.present
          ? data.gateReportJson.value
          : this.gateReportJson,
      curlFlag: data.curlFlag.present ? data.curlFlag.value : this.curlFlag,
      status: data.status.present ? data.status.value : this.status,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Scan(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('examId: $examId, ')
          ..write('studentId: $studentId, ')
          ..write('rollNoRead: $rollNoRead, ')
          ..write('rollConfidence: $rollConfidence, ')
          ..write('setCodeRead: $setCodeRead, ')
          ..write('layoutVersion: $layoutVersion, ')
          ..write('thresholdConfigId: $thresholdConfigId, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('warpedImagePath: $warpedImagePath, ')
          ..write('thumbPath: $thumbPath, ')
          ..write('annotatedPath: $annotatedPath, ')
          ..write('originalPath: $originalPath, ')
          ..write('sheetConfidence: $sheetConfidence, ')
          ..write('gateReportJson: $gateReportJson, ')
          ..write('curlFlag: $curlFlag, ')
          ..write('status: $status, ')
          ..write('syncState: $syncState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tenantId,
    examId,
    studentId,
    rollNoRead,
    rollConfidence,
    setCodeRead,
    layoutVersion,
    thresholdConfigId,
    capturedAt,
    deviceId,
    warpedImagePath,
    thumbPath,
    annotatedPath,
    originalPath,
    sheetConfidence,
    gateReportJson,
    curlFlag,
    status,
    syncState,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Scan &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.examId == this.examId &&
          other.studentId == this.studentId &&
          other.rollNoRead == this.rollNoRead &&
          other.rollConfidence == this.rollConfidence &&
          other.setCodeRead == this.setCodeRead &&
          other.layoutVersion == this.layoutVersion &&
          other.thresholdConfigId == this.thresholdConfigId &&
          other.capturedAt == this.capturedAt &&
          other.deviceId == this.deviceId &&
          other.warpedImagePath == this.warpedImagePath &&
          other.thumbPath == this.thumbPath &&
          other.annotatedPath == this.annotatedPath &&
          other.originalPath == this.originalPath &&
          other.sheetConfidence == this.sheetConfidence &&
          other.gateReportJson == this.gateReportJson &&
          other.curlFlag == this.curlFlag &&
          other.status == this.status &&
          other.syncState == this.syncState);
}

class ScansCompanion extends UpdateCompanion<Scan> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String> examId;
  final Value<String?> studentId;
  final Value<String?> rollNoRead;
  final Value<double?> rollConfidence;
  final Value<String?> setCodeRead;
  final Value<int> layoutVersion;
  final Value<String?> thresholdConfigId;
  final Value<DateTime> capturedAt;
  final Value<String?> deviceId;
  final Value<String> warpedImagePath;
  final Value<String> thumbPath;
  final Value<String> annotatedPath;
  final Value<String?> originalPath;
  final Value<double?> sheetConfidence;
  final Value<String> gateReportJson;
  final Value<bool> curlFlag;
  final Value<ScanStatus> status;
  final Value<SyncState> syncState;
  final Value<int> rowid;
  const ScansCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.examId = const Value.absent(),
    this.studentId = const Value.absent(),
    this.rollNoRead = const Value.absent(),
    this.rollConfidence = const Value.absent(),
    this.setCodeRead = const Value.absent(),
    this.layoutVersion = const Value.absent(),
    this.thresholdConfigId = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.warpedImagePath = const Value.absent(),
    this.thumbPath = const Value.absent(),
    this.annotatedPath = const Value.absent(),
    this.originalPath = const Value.absent(),
    this.sheetConfidence = const Value.absent(),
    this.gateReportJson = const Value.absent(),
    this.curlFlag = const Value.absent(),
    this.status = const Value.absent(),
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScansCompanion.insert({
    this.id = const Value.absent(),
    required String tenantId,
    required String examId,
    this.studentId = const Value.absent(),
    this.rollNoRead = const Value.absent(),
    this.rollConfidence = const Value.absent(),
    this.setCodeRead = const Value.absent(),
    required int layoutVersion,
    this.thresholdConfigId = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    required String warpedImagePath,
    required String thumbPath,
    required String annotatedPath,
    this.originalPath = const Value.absent(),
    this.sheetConfidence = const Value.absent(),
    this.gateReportJson = const Value.absent(),
    this.curlFlag = const Value.absent(),
    this.status = const Value.absent(),
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       examId = Value(examId),
       layoutVersion = Value(layoutVersion),
       warpedImagePath = Value(warpedImagePath),
       thumbPath = Value(thumbPath),
       annotatedPath = Value(annotatedPath);
  static Insertable<Scan> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? examId,
    Expression<String>? studentId,
    Expression<String>? rollNoRead,
    Expression<double>? rollConfidence,
    Expression<String>? setCodeRead,
    Expression<int>? layoutVersion,
    Expression<String>? thresholdConfigId,
    Expression<String>? capturedAt,
    Expression<String>? deviceId,
    Expression<String>? warpedImagePath,
    Expression<String>? thumbPath,
    Expression<String>? annotatedPath,
    Expression<String>? originalPath,
    Expression<double>? sheetConfidence,
    Expression<String>? gateReportJson,
    Expression<bool>? curlFlag,
    Expression<String>? status,
    Expression<String>? syncState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (examId != null) 'exam_id': examId,
      if (studentId != null) 'student_id': studentId,
      if (rollNoRead != null) 'roll_no_read': rollNoRead,
      if (rollConfidence != null) 'roll_confidence': rollConfidence,
      if (setCodeRead != null) 'set_code_read': setCodeRead,
      if (layoutVersion != null) 'layout_version': layoutVersion,
      if (thresholdConfigId != null) 'threshold_config_id': thresholdConfigId,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (warpedImagePath != null) 'warped_image_path': warpedImagePath,
      if (thumbPath != null) 'thumb_path': thumbPath,
      if (annotatedPath != null) 'annotated_path': annotatedPath,
      if (originalPath != null) 'original_path': originalPath,
      if (sheetConfidence != null) 'sheet_confidence': sheetConfidence,
      if (gateReportJson != null) 'gate_report_json': gateReportJson,
      if (curlFlag != null) 'curl_flag': curlFlag,
      if (status != null) 'status': status,
      if (syncState != null) 'sync_state': syncState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScansCompanion copyWith({
    Value<String>? id,
    Value<String>? tenantId,
    Value<String>? examId,
    Value<String?>? studentId,
    Value<String?>? rollNoRead,
    Value<double?>? rollConfidence,
    Value<String?>? setCodeRead,
    Value<int>? layoutVersion,
    Value<String?>? thresholdConfigId,
    Value<DateTime>? capturedAt,
    Value<String?>? deviceId,
    Value<String>? warpedImagePath,
    Value<String>? thumbPath,
    Value<String>? annotatedPath,
    Value<String?>? originalPath,
    Value<double?>? sheetConfidence,
    Value<String>? gateReportJson,
    Value<bool>? curlFlag,
    Value<ScanStatus>? status,
    Value<SyncState>? syncState,
    Value<int>? rowid,
  }) {
    return ScansCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      examId: examId ?? this.examId,
      studentId: studentId ?? this.studentId,
      rollNoRead: rollNoRead ?? this.rollNoRead,
      rollConfidence: rollConfidence ?? this.rollConfidence,
      setCodeRead: setCodeRead ?? this.setCodeRead,
      layoutVersion: layoutVersion ?? this.layoutVersion,
      thresholdConfigId: thresholdConfigId ?? this.thresholdConfigId,
      capturedAt: capturedAt ?? this.capturedAt,
      deviceId: deviceId ?? this.deviceId,
      warpedImagePath: warpedImagePath ?? this.warpedImagePath,
      thumbPath: thumbPath ?? this.thumbPath,
      annotatedPath: annotatedPath ?? this.annotatedPath,
      originalPath: originalPath ?? this.originalPath,
      sheetConfidence: sheetConfidence ?? this.sheetConfidence,
      gateReportJson: gateReportJson ?? this.gateReportJson,
      curlFlag: curlFlag ?? this.curlFlag,
      status: status ?? this.status,
      syncState: syncState ?? this.syncState,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (examId.present) {
      map['exam_id'] = Variable<String>(examId.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<String>(studentId.value);
    }
    if (rollNoRead.present) {
      map['roll_no_read'] = Variable<String>(rollNoRead.value);
    }
    if (rollConfidence.present) {
      map['roll_confidence'] = Variable<double>(rollConfidence.value);
    }
    if (setCodeRead.present) {
      map['set_code_read'] = Variable<String>(setCodeRead.value);
    }
    if (layoutVersion.present) {
      map['layout_version'] = Variable<int>(layoutVersion.value);
    }
    if (thresholdConfigId.present) {
      map['threshold_config_id'] = Variable<String>(thresholdConfigId.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<String>(
        $ScansTable.$convertercapturedAt.toSql(capturedAt.value),
      );
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (warpedImagePath.present) {
      map['warped_image_path'] = Variable<String>(warpedImagePath.value);
    }
    if (thumbPath.present) {
      map['thumb_path'] = Variable<String>(thumbPath.value);
    }
    if (annotatedPath.present) {
      map['annotated_path'] = Variable<String>(annotatedPath.value);
    }
    if (originalPath.present) {
      map['original_path'] = Variable<String>(originalPath.value);
    }
    if (sheetConfidence.present) {
      map['sheet_confidence'] = Variable<double>(sheetConfidence.value);
    }
    if (gateReportJson.present) {
      map['gate_report_json'] = Variable<String>(gateReportJson.value);
    }
    if (curlFlag.present) {
      map['curl_flag'] = Variable<bool>(curlFlag.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $ScansTable.$converterstatus.toSql(status.value),
      );
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(
        $ScansTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScansCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('examId: $examId, ')
          ..write('studentId: $studentId, ')
          ..write('rollNoRead: $rollNoRead, ')
          ..write('rollConfidence: $rollConfidence, ')
          ..write('setCodeRead: $setCodeRead, ')
          ..write('layoutVersion: $layoutVersion, ')
          ..write('thresholdConfigId: $thresholdConfigId, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('warpedImagePath: $warpedImagePath, ')
          ..write('thumbPath: $thumbPath, ')
          ..write('annotatedPath: $annotatedPath, ')
          ..write('originalPath: $originalPath, ')
          ..write('sheetConfidence: $sheetConfidence, ')
          ..write('gateReportJson: $gateReportJson, ')
          ..write('curlFlag: $curlFlag, ')
          ..write('status: $status, ')
          ..write('syncState: $syncState, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BubbleReadsTable extends BubbleReads
    with TableInfo<$BubbleReadsTable, BubbleRead> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BubbleReadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scanIdMeta = const VerificationMeta('scanId');
  @override
  late final GeneratedColumn<String> scanId = GeneratedColumn<String>(
    'scan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES scans (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _fieldKeyMeta = const VerificationMeta(
    'fieldKey',
  );
  @override
  late final GeneratedColumn<String> fieldKey = GeneratedColumn<String>(
    'field_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _optionIndexMeta = const VerificationMeta(
    'optionIndex',
  );
  @override
  late final GeneratedColumn<int> optionIndex = GeneratedColumn<int>(
    'option_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _meanIntensityMeta = const VerificationMeta(
    'meanIntensity',
  );
  @override
  late final GeneratedColumn<double> meanIntensity = GeneratedColumn<double>(
    'mean_intensity',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fillRatioMeta = const VerificationMeta(
    'fillRatio',
  );
  @override
  late final GeneratedColumn<double> fillRatio = GeneratedColumn<double>(
    'fill_ratio',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MarkClass, String> markClass =
      GeneratedColumn<String>(
        'mark_class',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<MarkClass>($BubbleReadsTable.$convertermarkClass);
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thresholdUsedMeta = const VerificationMeta(
    'thresholdUsed',
  );
  @override
  late final GeneratedColumn<double> thresholdUsed = GeneratedColumn<double>(
    'threshold_used',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isHumanCorrectionMeta = const VerificationMeta(
    'isHumanCorrection',
  );
  @override
  late final GeneratedColumn<bool> isHumanCorrection = GeneratedColumn<bool>(
    'is_human_correction',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_human_correction" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    tenantId,
    scanId,
    fieldKey,
    optionIndex,
    meanIntensity,
    fillRatio,
    markClass,
    confidence,
    thresholdUsed,
    isHumanCorrection,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bubble_reads';
  @override
  VerificationContext validateIntegrity(
    Insertable<BubbleRead> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('scan_id')) {
      context.handle(
        _scanIdMeta,
        scanId.isAcceptableOrUnknown(data['scan_id']!, _scanIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scanIdMeta);
    }
    if (data.containsKey('field_key')) {
      context.handle(
        _fieldKeyMeta,
        fieldKey.isAcceptableOrUnknown(data['field_key']!, _fieldKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldKeyMeta);
    }
    if (data.containsKey('option_index')) {
      context.handle(
        _optionIndexMeta,
        optionIndex.isAcceptableOrUnknown(
          data['option_index']!,
          _optionIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_optionIndexMeta);
    }
    if (data.containsKey('mean_intensity')) {
      context.handle(
        _meanIntensityMeta,
        meanIntensity.isAcceptableOrUnknown(
          data['mean_intensity']!,
          _meanIntensityMeta,
        ),
      );
    }
    if (data.containsKey('fill_ratio')) {
      context.handle(
        _fillRatioMeta,
        fillRatio.isAcceptableOrUnknown(data['fill_ratio']!, _fillRatioMeta),
      );
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    }
    if (data.containsKey('threshold_used')) {
      context.handle(
        _thresholdUsedMeta,
        thresholdUsed.isAcceptableOrUnknown(
          data['threshold_used']!,
          _thresholdUsedMeta,
        ),
      );
    }
    if (data.containsKey('is_human_correction')) {
      context.handle(
        _isHumanCorrectionMeta,
        isHumanCorrection.isAcceptableOrUnknown(
          data['is_human_correction']!,
          _isHumanCorrectionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {scanId, fieldKey, optionIndex};
  @override
  BubbleRead map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BubbleRead(
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      scanId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scan_id'],
      )!,
      fieldKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_key'],
      )!,
      optionIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}option_index'],
      )!,
      meanIntensity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}mean_intensity'],
      ),
      fillRatio: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fill_ratio'],
      ),
      markClass: $BubbleReadsTable.$convertermarkClass.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}mark_class'],
        )!,
      ),
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      ),
      thresholdUsed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}threshold_used'],
      ),
      isHumanCorrection: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_human_correction'],
      )!,
    );
  }

  @override
  $BubbleReadsTable createAlias(String alias) {
    return $BubbleReadsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MarkClass, String, String> $convertermarkClass =
      const EnumNameConverter<MarkClass>(MarkClass.values);
}

class BubbleRead extends DataClass implements Insertable<BubbleRead> {
  final String tenantId;

  /// Reads die with their scan.
  final String scanId;

  /// 'q17' | 'roll3' | 'set' — the globally unique field key from the spec.
  final String fieldKey;
  final int optionIndex;
  final double? meanIntensity;
  final double? fillRatio;
  final MarkClass markClass;
  final double? confidence;
  final double? thresholdUsed;

  /// 1 when a review operator set this value — supersedes the raw read on
  /// every subsequent re-grade, deterministically.
  final bool isHumanCorrection;
  const BubbleRead({
    required this.tenantId,
    required this.scanId,
    required this.fieldKey,
    required this.optionIndex,
    this.meanIntensity,
    this.fillRatio,
    required this.markClass,
    this.confidence,
    this.thresholdUsed,
    required this.isHumanCorrection,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tenant_id'] = Variable<String>(tenantId);
    map['scan_id'] = Variable<String>(scanId);
    map['field_key'] = Variable<String>(fieldKey);
    map['option_index'] = Variable<int>(optionIndex);
    if (!nullToAbsent || meanIntensity != null) {
      map['mean_intensity'] = Variable<double>(meanIntensity);
    }
    if (!nullToAbsent || fillRatio != null) {
      map['fill_ratio'] = Variable<double>(fillRatio);
    }
    {
      map['mark_class'] = Variable<String>(
        $BubbleReadsTable.$convertermarkClass.toSql(markClass),
      );
    }
    if (!nullToAbsent || confidence != null) {
      map['confidence'] = Variable<double>(confidence);
    }
    if (!nullToAbsent || thresholdUsed != null) {
      map['threshold_used'] = Variable<double>(thresholdUsed);
    }
    map['is_human_correction'] = Variable<bool>(isHumanCorrection);
    return map;
  }

  BubbleReadsCompanion toCompanion(bool nullToAbsent) {
    return BubbleReadsCompanion(
      tenantId: Value(tenantId),
      scanId: Value(scanId),
      fieldKey: Value(fieldKey),
      optionIndex: Value(optionIndex),
      meanIntensity: meanIntensity == null && nullToAbsent
          ? const Value.absent()
          : Value(meanIntensity),
      fillRatio: fillRatio == null && nullToAbsent
          ? const Value.absent()
          : Value(fillRatio),
      markClass: Value(markClass),
      confidence: confidence == null && nullToAbsent
          ? const Value.absent()
          : Value(confidence),
      thresholdUsed: thresholdUsed == null && nullToAbsent
          ? const Value.absent()
          : Value(thresholdUsed),
      isHumanCorrection: Value(isHumanCorrection),
    );
  }

  factory BubbleRead.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BubbleRead(
      tenantId: serializer.fromJson<String>(json['tenantId']),
      scanId: serializer.fromJson<String>(json['scanId']),
      fieldKey: serializer.fromJson<String>(json['fieldKey']),
      optionIndex: serializer.fromJson<int>(json['optionIndex']),
      meanIntensity: serializer.fromJson<double?>(json['meanIntensity']),
      fillRatio: serializer.fromJson<double?>(json['fillRatio']),
      markClass: $BubbleReadsTable.$convertermarkClass.fromJson(
        serializer.fromJson<String>(json['markClass']),
      ),
      confidence: serializer.fromJson<double?>(json['confidence']),
      thresholdUsed: serializer.fromJson<double?>(json['thresholdUsed']),
      isHumanCorrection: serializer.fromJson<bool>(json['isHumanCorrection']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tenantId': serializer.toJson<String>(tenantId),
      'scanId': serializer.toJson<String>(scanId),
      'fieldKey': serializer.toJson<String>(fieldKey),
      'optionIndex': serializer.toJson<int>(optionIndex),
      'meanIntensity': serializer.toJson<double?>(meanIntensity),
      'fillRatio': serializer.toJson<double?>(fillRatio),
      'markClass': serializer.toJson<String>(
        $BubbleReadsTable.$convertermarkClass.toJson(markClass),
      ),
      'confidence': serializer.toJson<double?>(confidence),
      'thresholdUsed': serializer.toJson<double?>(thresholdUsed),
      'isHumanCorrection': serializer.toJson<bool>(isHumanCorrection),
    };
  }

  BubbleRead copyWith({
    String? tenantId,
    String? scanId,
    String? fieldKey,
    int? optionIndex,
    Value<double?> meanIntensity = const Value.absent(),
    Value<double?> fillRatio = const Value.absent(),
    MarkClass? markClass,
    Value<double?> confidence = const Value.absent(),
    Value<double?> thresholdUsed = const Value.absent(),
    bool? isHumanCorrection,
  }) => BubbleRead(
    tenantId: tenantId ?? this.tenantId,
    scanId: scanId ?? this.scanId,
    fieldKey: fieldKey ?? this.fieldKey,
    optionIndex: optionIndex ?? this.optionIndex,
    meanIntensity: meanIntensity.present
        ? meanIntensity.value
        : this.meanIntensity,
    fillRatio: fillRatio.present ? fillRatio.value : this.fillRatio,
    markClass: markClass ?? this.markClass,
    confidence: confidence.present ? confidence.value : this.confidence,
    thresholdUsed: thresholdUsed.present
        ? thresholdUsed.value
        : this.thresholdUsed,
    isHumanCorrection: isHumanCorrection ?? this.isHumanCorrection,
  );
  BubbleRead copyWithCompanion(BubbleReadsCompanion data) {
    return BubbleRead(
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      scanId: data.scanId.present ? data.scanId.value : this.scanId,
      fieldKey: data.fieldKey.present ? data.fieldKey.value : this.fieldKey,
      optionIndex: data.optionIndex.present
          ? data.optionIndex.value
          : this.optionIndex,
      meanIntensity: data.meanIntensity.present
          ? data.meanIntensity.value
          : this.meanIntensity,
      fillRatio: data.fillRatio.present ? data.fillRatio.value : this.fillRatio,
      markClass: data.markClass.present ? data.markClass.value : this.markClass,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      thresholdUsed: data.thresholdUsed.present
          ? data.thresholdUsed.value
          : this.thresholdUsed,
      isHumanCorrection: data.isHumanCorrection.present
          ? data.isHumanCorrection.value
          : this.isHumanCorrection,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BubbleRead(')
          ..write('tenantId: $tenantId, ')
          ..write('scanId: $scanId, ')
          ..write('fieldKey: $fieldKey, ')
          ..write('optionIndex: $optionIndex, ')
          ..write('meanIntensity: $meanIntensity, ')
          ..write('fillRatio: $fillRatio, ')
          ..write('markClass: $markClass, ')
          ..write('confidence: $confidence, ')
          ..write('thresholdUsed: $thresholdUsed, ')
          ..write('isHumanCorrection: $isHumanCorrection')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    tenantId,
    scanId,
    fieldKey,
    optionIndex,
    meanIntensity,
    fillRatio,
    markClass,
    confidence,
    thresholdUsed,
    isHumanCorrection,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BubbleRead &&
          other.tenantId == this.tenantId &&
          other.scanId == this.scanId &&
          other.fieldKey == this.fieldKey &&
          other.optionIndex == this.optionIndex &&
          other.meanIntensity == this.meanIntensity &&
          other.fillRatio == this.fillRatio &&
          other.markClass == this.markClass &&
          other.confidence == this.confidence &&
          other.thresholdUsed == this.thresholdUsed &&
          other.isHumanCorrection == this.isHumanCorrection);
}

class BubbleReadsCompanion extends UpdateCompanion<BubbleRead> {
  final Value<String> tenantId;
  final Value<String> scanId;
  final Value<String> fieldKey;
  final Value<int> optionIndex;
  final Value<double?> meanIntensity;
  final Value<double?> fillRatio;
  final Value<MarkClass> markClass;
  final Value<double?> confidence;
  final Value<double?> thresholdUsed;
  final Value<bool> isHumanCorrection;
  final Value<int> rowid;
  const BubbleReadsCompanion({
    this.tenantId = const Value.absent(),
    this.scanId = const Value.absent(),
    this.fieldKey = const Value.absent(),
    this.optionIndex = const Value.absent(),
    this.meanIntensity = const Value.absent(),
    this.fillRatio = const Value.absent(),
    this.markClass = const Value.absent(),
    this.confidence = const Value.absent(),
    this.thresholdUsed = const Value.absent(),
    this.isHumanCorrection = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BubbleReadsCompanion.insert({
    required String tenantId,
    required String scanId,
    required String fieldKey,
    required int optionIndex,
    this.meanIntensity = const Value.absent(),
    this.fillRatio = const Value.absent(),
    required MarkClass markClass,
    this.confidence = const Value.absent(),
    this.thresholdUsed = const Value.absent(),
    this.isHumanCorrection = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       scanId = Value(scanId),
       fieldKey = Value(fieldKey),
       optionIndex = Value(optionIndex),
       markClass = Value(markClass);
  static Insertable<BubbleRead> custom({
    Expression<String>? tenantId,
    Expression<String>? scanId,
    Expression<String>? fieldKey,
    Expression<int>? optionIndex,
    Expression<double>? meanIntensity,
    Expression<double>? fillRatio,
    Expression<String>? markClass,
    Expression<double>? confidence,
    Expression<double>? thresholdUsed,
    Expression<bool>? isHumanCorrection,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tenantId != null) 'tenant_id': tenantId,
      if (scanId != null) 'scan_id': scanId,
      if (fieldKey != null) 'field_key': fieldKey,
      if (optionIndex != null) 'option_index': optionIndex,
      if (meanIntensity != null) 'mean_intensity': meanIntensity,
      if (fillRatio != null) 'fill_ratio': fillRatio,
      if (markClass != null) 'mark_class': markClass,
      if (confidence != null) 'confidence': confidence,
      if (thresholdUsed != null) 'threshold_used': thresholdUsed,
      if (isHumanCorrection != null) 'is_human_correction': isHumanCorrection,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BubbleReadsCompanion copyWith({
    Value<String>? tenantId,
    Value<String>? scanId,
    Value<String>? fieldKey,
    Value<int>? optionIndex,
    Value<double?>? meanIntensity,
    Value<double?>? fillRatio,
    Value<MarkClass>? markClass,
    Value<double?>? confidence,
    Value<double?>? thresholdUsed,
    Value<bool>? isHumanCorrection,
    Value<int>? rowid,
  }) {
    return BubbleReadsCompanion(
      tenantId: tenantId ?? this.tenantId,
      scanId: scanId ?? this.scanId,
      fieldKey: fieldKey ?? this.fieldKey,
      optionIndex: optionIndex ?? this.optionIndex,
      meanIntensity: meanIntensity ?? this.meanIntensity,
      fillRatio: fillRatio ?? this.fillRatio,
      markClass: markClass ?? this.markClass,
      confidence: confidence ?? this.confidence,
      thresholdUsed: thresholdUsed ?? this.thresholdUsed,
      isHumanCorrection: isHumanCorrection ?? this.isHumanCorrection,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (scanId.present) {
      map['scan_id'] = Variable<String>(scanId.value);
    }
    if (fieldKey.present) {
      map['field_key'] = Variable<String>(fieldKey.value);
    }
    if (optionIndex.present) {
      map['option_index'] = Variable<int>(optionIndex.value);
    }
    if (meanIntensity.present) {
      map['mean_intensity'] = Variable<double>(meanIntensity.value);
    }
    if (fillRatio.present) {
      map['fill_ratio'] = Variable<double>(fillRatio.value);
    }
    if (markClass.present) {
      map['mark_class'] = Variable<String>(
        $BubbleReadsTable.$convertermarkClass.toSql(markClass.value),
      );
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (thresholdUsed.present) {
      map['threshold_used'] = Variable<double>(thresholdUsed.value);
    }
    if (isHumanCorrection.present) {
      map['is_human_correction'] = Variable<bool>(isHumanCorrection.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BubbleReadsCompanion(')
          ..write('tenantId: $tenantId, ')
          ..write('scanId: $scanId, ')
          ..write('fieldKey: $fieldKey, ')
          ..write('optionIndex: $optionIndex, ')
          ..write('meanIntensity: $meanIntensity, ')
          ..write('fillRatio: $fillRatio, ')
          ..write('markClass: $markClass, ')
          ..write('confidence: $confidence, ')
          ..write('thresholdUsed: $thresholdUsed, ')
          ..write('isHumanCorrection: $isHumanCorrection, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ScoringRunsTable extends ScoringRuns
    with TableInfo<$ScoringRunsTable, ScoringRun> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScoringRunsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _examIdMeta = const VerificationMeta('examId');
  @override
  late final GeneratedColumn<String> examId = GeneratedColumn<String>(
    'exam_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exams (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _keyVersionIdMeta = const VerificationMeta(
    'keyVersionId',
  );
  @override
  late final GeneratedColumn<String> keyVersionId = GeneratedColumn<String>(
    'key_version_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES answer_key_versions (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _scoringRuleSnapshotJsonMeta =
      const VerificationMeta('scoringRuleSnapshotJson');
  @override
  late final GeneratedColumn<String> scoringRuleSnapshotJson =
      GeneratedColumn<String>(
        'scoring_rule_snapshot_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _sheetLayoutVersionMeta =
      const VerificationMeta('sheetLayoutVersion');
  @override
  late final GeneratedColumn<int> sheetLayoutVersion = GeneratedColumn<int>(
    'sheet_layout_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thresholdConfigIdMeta = const VerificationMeta(
    'thresholdConfigId',
  );
  @override
  late final GeneratedColumn<String> thresholdConfigId =
      GeneratedColumn<String>(
        'threshold_config_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> startedAt =
      GeneratedColumn<String>(
        'started_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        clientDefault: nowIsoUtc,
      ).withConverter<DateTime>($ScoringRunsTable.$converterstartedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> finishedAt =
      GeneratedColumn<String>(
        'finished_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($ScoringRunsTable.$converterfinishedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tenantId,
    examId,
    keyVersionId,
    scoringRuleSnapshotJson,
    sheetLayoutVersion,
    thresholdConfigId,
    startedAt,
    finishedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scoring_runs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScoringRun> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('exam_id')) {
      context.handle(
        _examIdMeta,
        examId.isAcceptableOrUnknown(data['exam_id']!, _examIdMeta),
      );
    } else if (isInserting) {
      context.missing(_examIdMeta);
    }
    if (data.containsKey('key_version_id')) {
      context.handle(
        _keyVersionIdMeta,
        keyVersionId.isAcceptableOrUnknown(
          data['key_version_id']!,
          _keyVersionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_keyVersionIdMeta);
    }
    if (data.containsKey('scoring_rule_snapshot_json')) {
      context.handle(
        _scoringRuleSnapshotJsonMeta,
        scoringRuleSnapshotJson.isAcceptableOrUnknown(
          data['scoring_rule_snapshot_json']!,
          _scoringRuleSnapshotJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scoringRuleSnapshotJsonMeta);
    }
    if (data.containsKey('sheet_layout_version')) {
      context.handle(
        _sheetLayoutVersionMeta,
        sheetLayoutVersion.isAcceptableOrUnknown(
          data['sheet_layout_version']!,
          _sheetLayoutVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sheetLayoutVersionMeta);
    }
    if (data.containsKey('threshold_config_id')) {
      context.handle(
        _thresholdConfigIdMeta,
        thresholdConfigId.isAcceptableOrUnknown(
          data['threshold_config_id']!,
          _thresholdConfigIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScoringRun map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScoringRun(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      examId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exam_id'],
      )!,
      keyVersionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key_version_id'],
      )!,
      scoringRuleSnapshotJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scoring_rule_snapshot_json'],
      )!,
      sheetLayoutVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sheet_layout_version'],
      )!,
      thresholdConfigId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}threshold_config_id'],
      ),
      startedAt: $ScoringRunsTable.$converterstartedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}started_at'],
        )!,
      ),
      finishedAt: $ScoringRunsTable.$converterfinishedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}finished_at'],
        ),
      ),
    );
  }

  @override
  $ScoringRunsTable createAlias(String alias) {
    return $ScoringRunsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, String> $converterstartedAt =
      const IsoDateTimeConverter();
  static TypeConverter<DateTime?, String?> $converterfinishedAt =
      nullableIsoDate;
}

class ScoringRun extends DataClass implements Insertable<ScoringRun> {
  final String id;
  final String tenantId;

  /// Audit history: RESTRICT — never delete an exam or key version that has
  /// scoring runs under it.
  final String examId;
  final String keyVersionId;

  /// JSON: the scoring-rule rows used, verbatim.
  final String scoringRuleSnapshotJson;
  final int sheetLayoutVersion;
  final String? thresholdConfigId;
  final DateTime startedAt;

  /// NULL while the run is in flight; stamped by `finishScoringRun`.
  final DateTime? finishedAt;
  const ScoringRun({
    required this.id,
    required this.tenantId,
    required this.examId,
    required this.keyVersionId,
    required this.scoringRuleSnapshotJson,
    required this.sheetLayoutVersion,
    this.thresholdConfigId,
    required this.startedAt,
    this.finishedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    map['exam_id'] = Variable<String>(examId);
    map['key_version_id'] = Variable<String>(keyVersionId);
    map['scoring_rule_snapshot_json'] = Variable<String>(
      scoringRuleSnapshotJson,
    );
    map['sheet_layout_version'] = Variable<int>(sheetLayoutVersion);
    if (!nullToAbsent || thresholdConfigId != null) {
      map['threshold_config_id'] = Variable<String>(thresholdConfigId);
    }
    {
      map['started_at'] = Variable<String>(
        $ScoringRunsTable.$converterstartedAt.toSql(startedAt),
      );
    }
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<String>(
        $ScoringRunsTable.$converterfinishedAt.toSql(finishedAt),
      );
    }
    return map;
  }

  ScoringRunsCompanion toCompanion(bool nullToAbsent) {
    return ScoringRunsCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      examId: Value(examId),
      keyVersionId: Value(keyVersionId),
      scoringRuleSnapshotJson: Value(scoringRuleSnapshotJson),
      sheetLayoutVersion: Value(sheetLayoutVersion),
      thresholdConfigId: thresholdConfigId == null && nullToAbsent
          ? const Value.absent()
          : Value(thresholdConfigId),
      startedAt: Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
    );
  }

  factory ScoringRun.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScoringRun(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      examId: serializer.fromJson<String>(json['examId']),
      keyVersionId: serializer.fromJson<String>(json['keyVersionId']),
      scoringRuleSnapshotJson: serializer.fromJson<String>(
        json['scoringRuleSnapshotJson'],
      ),
      sheetLayoutVersion: serializer.fromJson<int>(json['sheetLayoutVersion']),
      thresholdConfigId: serializer.fromJson<String?>(
        json['thresholdConfigId'],
      ),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      finishedAt: serializer.fromJson<DateTime?>(json['finishedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'examId': serializer.toJson<String>(examId),
      'keyVersionId': serializer.toJson<String>(keyVersionId),
      'scoringRuleSnapshotJson': serializer.toJson<String>(
        scoringRuleSnapshotJson,
      ),
      'sheetLayoutVersion': serializer.toJson<int>(sheetLayoutVersion),
      'thresholdConfigId': serializer.toJson<String?>(thresholdConfigId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'finishedAt': serializer.toJson<DateTime?>(finishedAt),
    };
  }

  ScoringRun copyWith({
    String? id,
    String? tenantId,
    String? examId,
    String? keyVersionId,
    String? scoringRuleSnapshotJson,
    int? sheetLayoutVersion,
    Value<String?> thresholdConfigId = const Value.absent(),
    DateTime? startedAt,
    Value<DateTime?> finishedAt = const Value.absent(),
  }) => ScoringRun(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    examId: examId ?? this.examId,
    keyVersionId: keyVersionId ?? this.keyVersionId,
    scoringRuleSnapshotJson:
        scoringRuleSnapshotJson ?? this.scoringRuleSnapshotJson,
    sheetLayoutVersion: sheetLayoutVersion ?? this.sheetLayoutVersion,
    thresholdConfigId: thresholdConfigId.present
        ? thresholdConfigId.value
        : this.thresholdConfigId,
    startedAt: startedAt ?? this.startedAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
  );
  ScoringRun copyWithCompanion(ScoringRunsCompanion data) {
    return ScoringRun(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      examId: data.examId.present ? data.examId.value : this.examId,
      keyVersionId: data.keyVersionId.present
          ? data.keyVersionId.value
          : this.keyVersionId,
      scoringRuleSnapshotJson: data.scoringRuleSnapshotJson.present
          ? data.scoringRuleSnapshotJson.value
          : this.scoringRuleSnapshotJson,
      sheetLayoutVersion: data.sheetLayoutVersion.present
          ? data.sheetLayoutVersion.value
          : this.sheetLayoutVersion,
      thresholdConfigId: data.thresholdConfigId.present
          ? data.thresholdConfigId.value
          : this.thresholdConfigId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScoringRun(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('examId: $examId, ')
          ..write('keyVersionId: $keyVersionId, ')
          ..write('scoringRuleSnapshotJson: $scoringRuleSnapshotJson, ')
          ..write('sheetLayoutVersion: $sheetLayoutVersion, ')
          ..write('thresholdConfigId: $thresholdConfigId, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tenantId,
    examId,
    keyVersionId,
    scoringRuleSnapshotJson,
    sheetLayoutVersion,
    thresholdConfigId,
    startedAt,
    finishedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScoringRun &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.examId == this.examId &&
          other.keyVersionId == this.keyVersionId &&
          other.scoringRuleSnapshotJson == this.scoringRuleSnapshotJson &&
          other.sheetLayoutVersion == this.sheetLayoutVersion &&
          other.thresholdConfigId == this.thresholdConfigId &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt);
}

class ScoringRunsCompanion extends UpdateCompanion<ScoringRun> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String> examId;
  final Value<String> keyVersionId;
  final Value<String> scoringRuleSnapshotJson;
  final Value<int> sheetLayoutVersion;
  final Value<String?> thresholdConfigId;
  final Value<DateTime> startedAt;
  final Value<DateTime?> finishedAt;
  final Value<int> rowid;
  const ScoringRunsCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.examId = const Value.absent(),
    this.keyVersionId = const Value.absent(),
    this.scoringRuleSnapshotJson = const Value.absent(),
    this.sheetLayoutVersion = const Value.absent(),
    this.thresholdConfigId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScoringRunsCompanion.insert({
    this.id = const Value.absent(),
    required String tenantId,
    required String examId,
    required String keyVersionId,
    required String scoringRuleSnapshotJson,
    required int sheetLayoutVersion,
    this.thresholdConfigId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       examId = Value(examId),
       keyVersionId = Value(keyVersionId),
       scoringRuleSnapshotJson = Value(scoringRuleSnapshotJson),
       sheetLayoutVersion = Value(sheetLayoutVersion);
  static Insertable<ScoringRun> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? examId,
    Expression<String>? keyVersionId,
    Expression<String>? scoringRuleSnapshotJson,
    Expression<int>? sheetLayoutVersion,
    Expression<String>? thresholdConfigId,
    Expression<String>? startedAt,
    Expression<String>? finishedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (examId != null) 'exam_id': examId,
      if (keyVersionId != null) 'key_version_id': keyVersionId,
      if (scoringRuleSnapshotJson != null)
        'scoring_rule_snapshot_json': scoringRuleSnapshotJson,
      if (sheetLayoutVersion != null)
        'sheet_layout_version': sheetLayoutVersion,
      if (thresholdConfigId != null) 'threshold_config_id': thresholdConfigId,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScoringRunsCompanion copyWith({
    Value<String>? id,
    Value<String>? tenantId,
    Value<String>? examId,
    Value<String>? keyVersionId,
    Value<String>? scoringRuleSnapshotJson,
    Value<int>? sheetLayoutVersion,
    Value<String?>? thresholdConfigId,
    Value<DateTime>? startedAt,
    Value<DateTime?>? finishedAt,
    Value<int>? rowid,
  }) {
    return ScoringRunsCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      examId: examId ?? this.examId,
      keyVersionId: keyVersionId ?? this.keyVersionId,
      scoringRuleSnapshotJson:
          scoringRuleSnapshotJson ?? this.scoringRuleSnapshotJson,
      sheetLayoutVersion: sheetLayoutVersion ?? this.sheetLayoutVersion,
      thresholdConfigId: thresholdConfigId ?? this.thresholdConfigId,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (examId.present) {
      map['exam_id'] = Variable<String>(examId.value);
    }
    if (keyVersionId.present) {
      map['key_version_id'] = Variable<String>(keyVersionId.value);
    }
    if (scoringRuleSnapshotJson.present) {
      map['scoring_rule_snapshot_json'] = Variable<String>(
        scoringRuleSnapshotJson.value,
      );
    }
    if (sheetLayoutVersion.present) {
      map['sheet_layout_version'] = Variable<int>(sheetLayoutVersion.value);
    }
    if (thresholdConfigId.present) {
      map['threshold_config_id'] = Variable<String>(thresholdConfigId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<String>(
        $ScoringRunsTable.$converterstartedAt.toSql(startedAt.value),
      );
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<String>(
        $ScoringRunsTable.$converterfinishedAt.toSql(finishedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScoringRunsCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('examId: $examId, ')
          ..write('keyVersionId: $keyVersionId, ')
          ..write('scoringRuleSnapshotJson: $scoringRuleSnapshotJson, ')
          ..write('sheetLayoutVersion: $sheetLayoutVersion, ')
          ..write('thresholdConfigId: $thresholdConfigId, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ResultsTable extends Results with TableInfo<$ResultsTable, Result> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ResultsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scanIdMeta = const VerificationMeta('scanId');
  @override
  late final GeneratedColumn<String> scanId = GeneratedColumn<String>(
    'scan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES scans (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _examIdMeta = const VerificationMeta('examId');
  @override
  late final GeneratedColumn<String> examId = GeneratedColumn<String>(
    'exam_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exams (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _studentIdMeta = const VerificationMeta(
    'studentId',
  );
  @override
  late final GeneratedColumn<String> studentId = GeneratedColumn<String>(
    'student_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES students (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _keyVersionIdMeta = const VerificationMeta(
    'keyVersionId',
  );
  @override
  late final GeneratedColumn<String> keyVersionId = GeneratedColumn<String>(
    'key_version_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES answer_key_versions (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _scoringRunIdMeta = const VerificationMeta(
    'scoringRunId',
  );
  @override
  late final GeneratedColumn<String> scoringRunId = GeneratedColumn<String>(
    'scoring_run_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES scoring_runs (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<double> total = GeneratedColumn<double>(
    'total',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _correctMeta = const VerificationMeta(
    'correct',
  );
  @override
  late final GeneratedColumn<int> correct = GeneratedColumn<int>(
    'correct',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _wrongMeta = const VerificationMeta('wrong');
  @override
  late final GeneratedColumn<int> wrong = GeneratedColumn<int>(
    'wrong',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _unattemptedMeta = const VerificationMeta(
    'unattempted',
  );
  @override
  late final GeneratedColumn<int> unattempted = GeneratedColumn<int>(
    'unattempted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _subjectTotalsJsonMeta = const VerificationMeta(
    'subjectTotalsJson',
  );
  @override
  late final GeneratedColumn<String> subjectTotalsJson =
      GeneratedColumn<String>(
        'subject_totals_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('{}'),
      );
  static const VerificationMeta _rankMeta = const VerificationMeta('rank');
  @override
  late final GeneratedColumn<int> rank = GeneratedColumn<int>(
    'rank',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ResultStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('ok'),
      ).withConverter<ResultStatus>($ResultsTable.$converterstatus);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> gradedAt =
      GeneratedColumn<String>(
        'graded_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        clientDefault: nowIsoUtc,
      ).withConverter<DateTime>($ResultsTable.$convertergradedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tenantId,
    scanId,
    examId,
    studentId,
    keyVersionId,
    scoringRunId,
    total,
    correct,
    wrong,
    unattempted,
    subjectTotalsJson,
    rank,
    status,
    gradedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'results';
  @override
  VerificationContext validateIntegrity(
    Insertable<Result> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('scan_id')) {
      context.handle(
        _scanIdMeta,
        scanId.isAcceptableOrUnknown(data['scan_id']!, _scanIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scanIdMeta);
    }
    if (data.containsKey('exam_id')) {
      context.handle(
        _examIdMeta,
        examId.isAcceptableOrUnknown(data['exam_id']!, _examIdMeta),
      );
    } else if (isInserting) {
      context.missing(_examIdMeta);
    }
    if (data.containsKey('student_id')) {
      context.handle(
        _studentIdMeta,
        studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_studentIdMeta);
    }
    if (data.containsKey('key_version_id')) {
      context.handle(
        _keyVersionIdMeta,
        keyVersionId.isAcceptableOrUnknown(
          data['key_version_id']!,
          _keyVersionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_keyVersionIdMeta);
    }
    if (data.containsKey('scoring_run_id')) {
      context.handle(
        _scoringRunIdMeta,
        scoringRunId.isAcceptableOrUnknown(
          data['scoring_run_id']!,
          _scoringRunIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scoringRunIdMeta);
    }
    if (data.containsKey('total')) {
      context.handle(
        _totalMeta,
        total.isAcceptableOrUnknown(data['total']!, _totalMeta),
      );
    } else if (isInserting) {
      context.missing(_totalMeta);
    }
    if (data.containsKey('correct')) {
      context.handle(
        _correctMeta,
        correct.isAcceptableOrUnknown(data['correct']!, _correctMeta),
      );
    }
    if (data.containsKey('wrong')) {
      context.handle(
        _wrongMeta,
        wrong.isAcceptableOrUnknown(data['wrong']!, _wrongMeta),
      );
    }
    if (data.containsKey('unattempted')) {
      context.handle(
        _unattemptedMeta,
        unattempted.isAcceptableOrUnknown(
          data['unattempted']!,
          _unattemptedMeta,
        ),
      );
    }
    if (data.containsKey('subject_totals_json')) {
      context.handle(
        _subjectTotalsJsonMeta,
        subjectTotalsJson.isAcceptableOrUnknown(
          data['subject_totals_json']!,
          _subjectTotalsJsonMeta,
        ),
      );
    }
    if (data.containsKey('rank')) {
      context.handle(
        _rankMeta,
        rank.isAcceptableOrUnknown(data['rank']!, _rankMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Result map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Result(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      scanId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scan_id'],
      )!,
      examId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exam_id'],
      )!,
      studentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}student_id'],
      )!,
      keyVersionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key_version_id'],
      )!,
      scoringRunId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scoring_run_id'],
      )!,
      total: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total'],
      )!,
      correct: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct'],
      )!,
      wrong: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wrong'],
      )!,
      unattempted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unattempted'],
      )!,
      subjectTotalsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_totals_json'],
      )!,
      rank: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rank'],
      ),
      status: $ResultsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      gradedAt: $ResultsTable.$convertergradedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}graded_at'],
        )!,
      ),
    );
  }

  @override
  $ResultsTable createAlias(String alias) {
    return $ResultsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ResultStatus, String, String> $converterstatus =
      const EnumNameConverter<ResultStatus>(ResultStatus.values);
  static TypeConverter<DateTime, String> $convertergradedAt =
      const IsoDateTimeConverter();
}

class Result extends DataClass implements Insertable<Result> {
  final String id;
  final String tenantId;
  final String scanId;
  final String examId;
  final String studentId;
  final String keyVersionId;
  final String scoringRunId;

  /// Final score after negative marking, corrections and overrides.
  final double total;
  final int correct;
  final int wrong;
  final int unattempted;

  /// JSON: subject/section → marks, consumed by AnalyticsDao via JSON1.
  final String subjectTotalsJson;

  /// 1-based exam rank; NULL until `recomputeRanks` runs. RANK semantics —
  /// ties share a rank and the next rank skips.
  final int? rank;
  final ResultStatus status;
  final DateTime gradedAt;
  const Result({
    required this.id,
    required this.tenantId,
    required this.scanId,
    required this.examId,
    required this.studentId,
    required this.keyVersionId,
    required this.scoringRunId,
    required this.total,
    required this.correct,
    required this.wrong,
    required this.unattempted,
    required this.subjectTotalsJson,
    this.rank,
    required this.status,
    required this.gradedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    map['scan_id'] = Variable<String>(scanId);
    map['exam_id'] = Variable<String>(examId);
    map['student_id'] = Variable<String>(studentId);
    map['key_version_id'] = Variable<String>(keyVersionId);
    map['scoring_run_id'] = Variable<String>(scoringRunId);
    map['total'] = Variable<double>(total);
    map['correct'] = Variable<int>(correct);
    map['wrong'] = Variable<int>(wrong);
    map['unattempted'] = Variable<int>(unattempted);
    map['subject_totals_json'] = Variable<String>(subjectTotalsJson);
    if (!nullToAbsent || rank != null) {
      map['rank'] = Variable<int>(rank);
    }
    {
      map['status'] = Variable<String>(
        $ResultsTable.$converterstatus.toSql(status),
      );
    }
    {
      map['graded_at'] = Variable<String>(
        $ResultsTable.$convertergradedAt.toSql(gradedAt),
      );
    }
    return map;
  }

  ResultsCompanion toCompanion(bool nullToAbsent) {
    return ResultsCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      scanId: Value(scanId),
      examId: Value(examId),
      studentId: Value(studentId),
      keyVersionId: Value(keyVersionId),
      scoringRunId: Value(scoringRunId),
      total: Value(total),
      correct: Value(correct),
      wrong: Value(wrong),
      unattempted: Value(unattempted),
      subjectTotalsJson: Value(subjectTotalsJson),
      rank: rank == null && nullToAbsent ? const Value.absent() : Value(rank),
      status: Value(status),
      gradedAt: Value(gradedAt),
    );
  }

  factory Result.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Result(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      scanId: serializer.fromJson<String>(json['scanId']),
      examId: serializer.fromJson<String>(json['examId']),
      studentId: serializer.fromJson<String>(json['studentId']),
      keyVersionId: serializer.fromJson<String>(json['keyVersionId']),
      scoringRunId: serializer.fromJson<String>(json['scoringRunId']),
      total: serializer.fromJson<double>(json['total']),
      correct: serializer.fromJson<int>(json['correct']),
      wrong: serializer.fromJson<int>(json['wrong']),
      unattempted: serializer.fromJson<int>(json['unattempted']),
      subjectTotalsJson: serializer.fromJson<String>(json['subjectTotalsJson']),
      rank: serializer.fromJson<int?>(json['rank']),
      status: $ResultsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      gradedAt: serializer.fromJson<DateTime>(json['gradedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'scanId': serializer.toJson<String>(scanId),
      'examId': serializer.toJson<String>(examId),
      'studentId': serializer.toJson<String>(studentId),
      'keyVersionId': serializer.toJson<String>(keyVersionId),
      'scoringRunId': serializer.toJson<String>(scoringRunId),
      'total': serializer.toJson<double>(total),
      'correct': serializer.toJson<int>(correct),
      'wrong': serializer.toJson<int>(wrong),
      'unattempted': serializer.toJson<int>(unattempted),
      'subjectTotalsJson': serializer.toJson<String>(subjectTotalsJson),
      'rank': serializer.toJson<int?>(rank),
      'status': serializer.toJson<String>(
        $ResultsTable.$converterstatus.toJson(status),
      ),
      'gradedAt': serializer.toJson<DateTime>(gradedAt),
    };
  }

  Result copyWith({
    String? id,
    String? tenantId,
    String? scanId,
    String? examId,
    String? studentId,
    String? keyVersionId,
    String? scoringRunId,
    double? total,
    int? correct,
    int? wrong,
    int? unattempted,
    String? subjectTotalsJson,
    Value<int?> rank = const Value.absent(),
    ResultStatus? status,
    DateTime? gradedAt,
  }) => Result(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    scanId: scanId ?? this.scanId,
    examId: examId ?? this.examId,
    studentId: studentId ?? this.studentId,
    keyVersionId: keyVersionId ?? this.keyVersionId,
    scoringRunId: scoringRunId ?? this.scoringRunId,
    total: total ?? this.total,
    correct: correct ?? this.correct,
    wrong: wrong ?? this.wrong,
    unattempted: unattempted ?? this.unattempted,
    subjectTotalsJson: subjectTotalsJson ?? this.subjectTotalsJson,
    rank: rank.present ? rank.value : this.rank,
    status: status ?? this.status,
    gradedAt: gradedAt ?? this.gradedAt,
  );
  Result copyWithCompanion(ResultsCompanion data) {
    return Result(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      scanId: data.scanId.present ? data.scanId.value : this.scanId,
      examId: data.examId.present ? data.examId.value : this.examId,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      keyVersionId: data.keyVersionId.present
          ? data.keyVersionId.value
          : this.keyVersionId,
      scoringRunId: data.scoringRunId.present
          ? data.scoringRunId.value
          : this.scoringRunId,
      total: data.total.present ? data.total.value : this.total,
      correct: data.correct.present ? data.correct.value : this.correct,
      wrong: data.wrong.present ? data.wrong.value : this.wrong,
      unattempted: data.unattempted.present
          ? data.unattempted.value
          : this.unattempted,
      subjectTotalsJson: data.subjectTotalsJson.present
          ? data.subjectTotalsJson.value
          : this.subjectTotalsJson,
      rank: data.rank.present ? data.rank.value : this.rank,
      status: data.status.present ? data.status.value : this.status,
      gradedAt: data.gradedAt.present ? data.gradedAt.value : this.gradedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Result(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('scanId: $scanId, ')
          ..write('examId: $examId, ')
          ..write('studentId: $studentId, ')
          ..write('keyVersionId: $keyVersionId, ')
          ..write('scoringRunId: $scoringRunId, ')
          ..write('total: $total, ')
          ..write('correct: $correct, ')
          ..write('wrong: $wrong, ')
          ..write('unattempted: $unattempted, ')
          ..write('subjectTotalsJson: $subjectTotalsJson, ')
          ..write('rank: $rank, ')
          ..write('status: $status, ')
          ..write('gradedAt: $gradedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tenantId,
    scanId,
    examId,
    studentId,
    keyVersionId,
    scoringRunId,
    total,
    correct,
    wrong,
    unattempted,
    subjectTotalsJson,
    rank,
    status,
    gradedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Result &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.scanId == this.scanId &&
          other.examId == this.examId &&
          other.studentId == this.studentId &&
          other.keyVersionId == this.keyVersionId &&
          other.scoringRunId == this.scoringRunId &&
          other.total == this.total &&
          other.correct == this.correct &&
          other.wrong == this.wrong &&
          other.unattempted == this.unattempted &&
          other.subjectTotalsJson == this.subjectTotalsJson &&
          other.rank == this.rank &&
          other.status == this.status &&
          other.gradedAt == this.gradedAt);
}

class ResultsCompanion extends UpdateCompanion<Result> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String> scanId;
  final Value<String> examId;
  final Value<String> studentId;
  final Value<String> keyVersionId;
  final Value<String> scoringRunId;
  final Value<double> total;
  final Value<int> correct;
  final Value<int> wrong;
  final Value<int> unattempted;
  final Value<String> subjectTotalsJson;
  final Value<int?> rank;
  final Value<ResultStatus> status;
  final Value<DateTime> gradedAt;
  final Value<int> rowid;
  const ResultsCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.scanId = const Value.absent(),
    this.examId = const Value.absent(),
    this.studentId = const Value.absent(),
    this.keyVersionId = const Value.absent(),
    this.scoringRunId = const Value.absent(),
    this.total = const Value.absent(),
    this.correct = const Value.absent(),
    this.wrong = const Value.absent(),
    this.unattempted = const Value.absent(),
    this.subjectTotalsJson = const Value.absent(),
    this.rank = const Value.absent(),
    this.status = const Value.absent(),
    this.gradedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ResultsCompanion.insert({
    this.id = const Value.absent(),
    required String tenantId,
    required String scanId,
    required String examId,
    required String studentId,
    required String keyVersionId,
    required String scoringRunId,
    required double total,
    this.correct = const Value.absent(),
    this.wrong = const Value.absent(),
    this.unattempted = const Value.absent(),
    this.subjectTotalsJson = const Value.absent(),
    this.rank = const Value.absent(),
    this.status = const Value.absent(),
    this.gradedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       scanId = Value(scanId),
       examId = Value(examId),
       studentId = Value(studentId),
       keyVersionId = Value(keyVersionId),
       scoringRunId = Value(scoringRunId),
       total = Value(total);
  static Insertable<Result> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? scanId,
    Expression<String>? examId,
    Expression<String>? studentId,
    Expression<String>? keyVersionId,
    Expression<String>? scoringRunId,
    Expression<double>? total,
    Expression<int>? correct,
    Expression<int>? wrong,
    Expression<int>? unattempted,
    Expression<String>? subjectTotalsJson,
    Expression<int>? rank,
    Expression<String>? status,
    Expression<String>? gradedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (scanId != null) 'scan_id': scanId,
      if (examId != null) 'exam_id': examId,
      if (studentId != null) 'student_id': studentId,
      if (keyVersionId != null) 'key_version_id': keyVersionId,
      if (scoringRunId != null) 'scoring_run_id': scoringRunId,
      if (total != null) 'total': total,
      if (correct != null) 'correct': correct,
      if (wrong != null) 'wrong': wrong,
      if (unattempted != null) 'unattempted': unattempted,
      if (subjectTotalsJson != null) 'subject_totals_json': subjectTotalsJson,
      if (rank != null) 'rank': rank,
      if (status != null) 'status': status,
      if (gradedAt != null) 'graded_at': gradedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ResultsCompanion copyWith({
    Value<String>? id,
    Value<String>? tenantId,
    Value<String>? scanId,
    Value<String>? examId,
    Value<String>? studentId,
    Value<String>? keyVersionId,
    Value<String>? scoringRunId,
    Value<double>? total,
    Value<int>? correct,
    Value<int>? wrong,
    Value<int>? unattempted,
    Value<String>? subjectTotalsJson,
    Value<int?>? rank,
    Value<ResultStatus>? status,
    Value<DateTime>? gradedAt,
    Value<int>? rowid,
  }) {
    return ResultsCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      scanId: scanId ?? this.scanId,
      examId: examId ?? this.examId,
      studentId: studentId ?? this.studentId,
      keyVersionId: keyVersionId ?? this.keyVersionId,
      scoringRunId: scoringRunId ?? this.scoringRunId,
      total: total ?? this.total,
      correct: correct ?? this.correct,
      wrong: wrong ?? this.wrong,
      unattempted: unattempted ?? this.unattempted,
      subjectTotalsJson: subjectTotalsJson ?? this.subjectTotalsJson,
      rank: rank ?? this.rank,
      status: status ?? this.status,
      gradedAt: gradedAt ?? this.gradedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (scanId.present) {
      map['scan_id'] = Variable<String>(scanId.value);
    }
    if (examId.present) {
      map['exam_id'] = Variable<String>(examId.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<String>(studentId.value);
    }
    if (keyVersionId.present) {
      map['key_version_id'] = Variable<String>(keyVersionId.value);
    }
    if (scoringRunId.present) {
      map['scoring_run_id'] = Variable<String>(scoringRunId.value);
    }
    if (total.present) {
      map['total'] = Variable<double>(total.value);
    }
    if (correct.present) {
      map['correct'] = Variable<int>(correct.value);
    }
    if (wrong.present) {
      map['wrong'] = Variable<int>(wrong.value);
    }
    if (unattempted.present) {
      map['unattempted'] = Variable<int>(unattempted.value);
    }
    if (subjectTotalsJson.present) {
      map['subject_totals_json'] = Variable<String>(subjectTotalsJson.value);
    }
    if (rank.present) {
      map['rank'] = Variable<int>(rank.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $ResultsTable.$converterstatus.toSql(status.value),
      );
    }
    if (gradedAt.present) {
      map['graded_at'] = Variable<String>(
        $ResultsTable.$convertergradedAt.toSql(gradedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ResultsCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('scanId: $scanId, ')
          ..write('examId: $examId, ')
          ..write('studentId: $studentId, ')
          ..write('keyVersionId: $keyVersionId, ')
          ..write('scoringRunId: $scoringRunId, ')
          ..write('total: $total, ')
          ..write('correct: $correct, ')
          ..write('wrong: $wrong, ')
          ..write('unattempted: $unattempted, ')
          ..write('subjectTotalsJson: $subjectTotalsJson, ')
          ..write('rank: $rank, ')
          ..write('status: $status, ')
          ..write('gradedAt: $gradedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReviewQueueTable extends ReviewQueue
    with TableInfo<$ReviewQueueTable, ReviewQueueItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scanIdMeta = const VerificationMeta('scanId');
  @override
  late final GeneratedColumn<String> scanId = GeneratedColumn<String>(
    'scan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES scans (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _reasonCodeMeta = const VerificationMeta(
    'reasonCode',
  );
  @override
  late final GeneratedColumn<String> reasonCode = GeneratedColumn<String>(
    'reason_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fieldRefsJsonMeta = const VerificationMeta(
    'fieldRefsJson',
  );
  @override
  late final GeneratedColumn<String> fieldRefsJson = GeneratedColumn<String>(
    'field_refs_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<ReviewSeverity, String> severity =
      GeneratedColumn<String>(
        'severity',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ReviewSeverity>($ReviewQueueTable.$converterseverity);
  static const VerificationMeta _resolvedByMeta = const VerificationMeta(
    'resolvedBy',
  );
  @override
  late final GeneratedColumn<String> resolvedBy = GeneratedColumn<String>(
    'resolved_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> resolvedAt =
      GeneratedColumn<String>(
        'resolved_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($ReviewQueueTable.$converterresolvedAt);
  static const VerificationMeta _correctionJsonMeta = const VerificationMeta(
    'correctionJson',
  );
  @override
  late final GeneratedColumn<String> correctionJson = GeneratedColumn<String>(
    'correction_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ReviewOutcome, String> outcome =
      GeneratedColumn<String>(
        'outcome',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('open'),
      ).withConverter<ReviewOutcome>($ReviewQueueTable.$converteroutcome);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tenantId,
    scanId,
    reasonCode,
    fieldRefsJson,
    severity,
    resolvedBy,
    resolvedAt,
    correctionJson,
    outcome,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReviewQueueItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('scan_id')) {
      context.handle(
        _scanIdMeta,
        scanId.isAcceptableOrUnknown(data['scan_id']!, _scanIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scanIdMeta);
    }
    if (data.containsKey('reason_code')) {
      context.handle(
        _reasonCodeMeta,
        reasonCode.isAcceptableOrUnknown(data['reason_code']!, _reasonCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonCodeMeta);
    }
    if (data.containsKey('field_refs_json')) {
      context.handle(
        _fieldRefsJsonMeta,
        fieldRefsJson.isAcceptableOrUnknown(
          data['field_refs_json']!,
          _fieldRefsJsonMeta,
        ),
      );
    }
    if (data.containsKey('resolved_by')) {
      context.handle(
        _resolvedByMeta,
        resolvedBy.isAcceptableOrUnknown(data['resolved_by']!, _resolvedByMeta),
      );
    }
    if (data.containsKey('correction_json')) {
      context.handle(
        _correctionJsonMeta,
        correctionJson.isAcceptableOrUnknown(
          data['correction_json']!,
          _correctionJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReviewQueueItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewQueueItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      scanId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scan_id'],
      )!,
      reasonCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason_code'],
      )!,
      fieldRefsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_refs_json'],
      )!,
      severity: $ReviewQueueTable.$converterseverity.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}severity'],
        )!,
      ),
      resolvedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resolved_by'],
      ),
      resolvedAt: $ReviewQueueTable.$converterresolvedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}resolved_at'],
        ),
      ),
      correctionJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}correction_json'],
      ),
      outcome: $ReviewQueueTable.$converteroutcome.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}outcome'],
        )!,
      ),
    );
  }

  @override
  $ReviewQueueTable createAlias(String alias) {
    return $ReviewQueueTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ReviewSeverity, String, String> $converterseverity =
      const EnumNameConverter<ReviewSeverity>(ReviewSeverity.values);
  static TypeConverter<DateTime?, String?> $converterresolvedAt =
      nullableIsoDate;
  static JsonTypeConverter2<ReviewOutcome, String, String> $converteroutcome =
      const EnumNameConverter<ReviewOutcome>(ReviewOutcome.values);
}

class ReviewQueueItem extends DataClass implements Insertable<ReviewQueueItem> {
  final String id;
  final String tenantId;

  /// Queue items die with their scan.
  final String scanId;

  /// e.g. ROLL_CHECKSUM_MISMATCH, ROLL_NOT_ON_ROSTER, SET_CODE_INVALID,
  /// MULTI_BUBBLE_WARN, PROBABLE_BUBBLE, LOW_SHEET_CONFIDENCE, CURL_FLAGGED,
  /// NO_MARKER_ERR (plan §3).
  final String reasonCode;

  /// JSON array of field keys the reason refers to, e.g. '["q17","q18"]'.
  final String fieldRefsJson;
  final ReviewSeverity severity;
  final String? resolvedBy;
  final DateTime? resolvedAt;

  /// JSON array of applied corrections (see ReviewDao.resolve).
  final String? correctionJson;
  final ReviewOutcome outcome;
  const ReviewQueueItem({
    required this.id,
    required this.tenantId,
    required this.scanId,
    required this.reasonCode,
    required this.fieldRefsJson,
    required this.severity,
    this.resolvedBy,
    this.resolvedAt,
    this.correctionJson,
    required this.outcome,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    map['scan_id'] = Variable<String>(scanId);
    map['reason_code'] = Variable<String>(reasonCode);
    map['field_refs_json'] = Variable<String>(fieldRefsJson);
    {
      map['severity'] = Variable<String>(
        $ReviewQueueTable.$converterseverity.toSql(severity),
      );
    }
    if (!nullToAbsent || resolvedBy != null) {
      map['resolved_by'] = Variable<String>(resolvedBy);
    }
    if (!nullToAbsent || resolvedAt != null) {
      map['resolved_at'] = Variable<String>(
        $ReviewQueueTable.$converterresolvedAt.toSql(resolvedAt),
      );
    }
    if (!nullToAbsent || correctionJson != null) {
      map['correction_json'] = Variable<String>(correctionJson);
    }
    {
      map['outcome'] = Variable<String>(
        $ReviewQueueTable.$converteroutcome.toSql(outcome),
      );
    }
    return map;
  }

  ReviewQueueCompanion toCompanion(bool nullToAbsent) {
    return ReviewQueueCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      scanId: Value(scanId),
      reasonCode: Value(reasonCode),
      fieldRefsJson: Value(fieldRefsJson),
      severity: Value(severity),
      resolvedBy: resolvedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedBy),
      resolvedAt: resolvedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedAt),
      correctionJson: correctionJson == null && nullToAbsent
          ? const Value.absent()
          : Value(correctionJson),
      outcome: Value(outcome),
    );
  }

  factory ReviewQueueItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewQueueItem(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      scanId: serializer.fromJson<String>(json['scanId']),
      reasonCode: serializer.fromJson<String>(json['reasonCode']),
      fieldRefsJson: serializer.fromJson<String>(json['fieldRefsJson']),
      severity: $ReviewQueueTable.$converterseverity.fromJson(
        serializer.fromJson<String>(json['severity']),
      ),
      resolvedBy: serializer.fromJson<String?>(json['resolvedBy']),
      resolvedAt: serializer.fromJson<DateTime?>(json['resolvedAt']),
      correctionJson: serializer.fromJson<String?>(json['correctionJson']),
      outcome: $ReviewQueueTable.$converteroutcome.fromJson(
        serializer.fromJson<String>(json['outcome']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'scanId': serializer.toJson<String>(scanId),
      'reasonCode': serializer.toJson<String>(reasonCode),
      'fieldRefsJson': serializer.toJson<String>(fieldRefsJson),
      'severity': serializer.toJson<String>(
        $ReviewQueueTable.$converterseverity.toJson(severity),
      ),
      'resolvedBy': serializer.toJson<String?>(resolvedBy),
      'resolvedAt': serializer.toJson<DateTime?>(resolvedAt),
      'correctionJson': serializer.toJson<String?>(correctionJson),
      'outcome': serializer.toJson<String>(
        $ReviewQueueTable.$converteroutcome.toJson(outcome),
      ),
    };
  }

  ReviewQueueItem copyWith({
    String? id,
    String? tenantId,
    String? scanId,
    String? reasonCode,
    String? fieldRefsJson,
    ReviewSeverity? severity,
    Value<String?> resolvedBy = const Value.absent(),
    Value<DateTime?> resolvedAt = const Value.absent(),
    Value<String?> correctionJson = const Value.absent(),
    ReviewOutcome? outcome,
  }) => ReviewQueueItem(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    scanId: scanId ?? this.scanId,
    reasonCode: reasonCode ?? this.reasonCode,
    fieldRefsJson: fieldRefsJson ?? this.fieldRefsJson,
    severity: severity ?? this.severity,
    resolvedBy: resolvedBy.present ? resolvedBy.value : this.resolvedBy,
    resolvedAt: resolvedAt.present ? resolvedAt.value : this.resolvedAt,
    correctionJson: correctionJson.present
        ? correctionJson.value
        : this.correctionJson,
    outcome: outcome ?? this.outcome,
  );
  ReviewQueueItem copyWithCompanion(ReviewQueueCompanion data) {
    return ReviewQueueItem(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      scanId: data.scanId.present ? data.scanId.value : this.scanId,
      reasonCode: data.reasonCode.present
          ? data.reasonCode.value
          : this.reasonCode,
      fieldRefsJson: data.fieldRefsJson.present
          ? data.fieldRefsJson.value
          : this.fieldRefsJson,
      severity: data.severity.present ? data.severity.value : this.severity,
      resolvedBy: data.resolvedBy.present
          ? data.resolvedBy.value
          : this.resolvedBy,
      resolvedAt: data.resolvedAt.present
          ? data.resolvedAt.value
          : this.resolvedAt,
      correctionJson: data.correctionJson.present
          ? data.correctionJson.value
          : this.correctionJson,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewQueueItem(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('scanId: $scanId, ')
          ..write('reasonCode: $reasonCode, ')
          ..write('fieldRefsJson: $fieldRefsJson, ')
          ..write('severity: $severity, ')
          ..write('resolvedBy: $resolvedBy, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('correctionJson: $correctionJson, ')
          ..write('outcome: $outcome')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tenantId,
    scanId,
    reasonCode,
    fieldRefsJson,
    severity,
    resolvedBy,
    resolvedAt,
    correctionJson,
    outcome,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewQueueItem &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.scanId == this.scanId &&
          other.reasonCode == this.reasonCode &&
          other.fieldRefsJson == this.fieldRefsJson &&
          other.severity == this.severity &&
          other.resolvedBy == this.resolvedBy &&
          other.resolvedAt == this.resolvedAt &&
          other.correctionJson == this.correctionJson &&
          other.outcome == this.outcome);
}

class ReviewQueueCompanion extends UpdateCompanion<ReviewQueueItem> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String> scanId;
  final Value<String> reasonCode;
  final Value<String> fieldRefsJson;
  final Value<ReviewSeverity> severity;
  final Value<String?> resolvedBy;
  final Value<DateTime?> resolvedAt;
  final Value<String?> correctionJson;
  final Value<ReviewOutcome> outcome;
  final Value<int> rowid;
  const ReviewQueueCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.scanId = const Value.absent(),
    this.reasonCode = const Value.absent(),
    this.fieldRefsJson = const Value.absent(),
    this.severity = const Value.absent(),
    this.resolvedBy = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.correctionJson = const Value.absent(),
    this.outcome = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReviewQueueCompanion.insert({
    this.id = const Value.absent(),
    required String tenantId,
    required String scanId,
    required String reasonCode,
    this.fieldRefsJson = const Value.absent(),
    required ReviewSeverity severity,
    this.resolvedBy = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.correctionJson = const Value.absent(),
    this.outcome = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       scanId = Value(scanId),
       reasonCode = Value(reasonCode),
       severity = Value(severity);
  static Insertable<ReviewQueueItem> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? scanId,
    Expression<String>? reasonCode,
    Expression<String>? fieldRefsJson,
    Expression<String>? severity,
    Expression<String>? resolvedBy,
    Expression<String>? resolvedAt,
    Expression<String>? correctionJson,
    Expression<String>? outcome,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (scanId != null) 'scan_id': scanId,
      if (reasonCode != null) 'reason_code': reasonCode,
      if (fieldRefsJson != null) 'field_refs_json': fieldRefsJson,
      if (severity != null) 'severity': severity,
      if (resolvedBy != null) 'resolved_by': resolvedBy,
      if (resolvedAt != null) 'resolved_at': resolvedAt,
      if (correctionJson != null) 'correction_json': correctionJson,
      if (outcome != null) 'outcome': outcome,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReviewQueueCompanion copyWith({
    Value<String>? id,
    Value<String>? tenantId,
    Value<String>? scanId,
    Value<String>? reasonCode,
    Value<String>? fieldRefsJson,
    Value<ReviewSeverity>? severity,
    Value<String?>? resolvedBy,
    Value<DateTime?>? resolvedAt,
    Value<String?>? correctionJson,
    Value<ReviewOutcome>? outcome,
    Value<int>? rowid,
  }) {
    return ReviewQueueCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      scanId: scanId ?? this.scanId,
      reasonCode: reasonCode ?? this.reasonCode,
      fieldRefsJson: fieldRefsJson ?? this.fieldRefsJson,
      severity: severity ?? this.severity,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      correctionJson: correctionJson ?? this.correctionJson,
      outcome: outcome ?? this.outcome,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (scanId.present) {
      map['scan_id'] = Variable<String>(scanId.value);
    }
    if (reasonCode.present) {
      map['reason_code'] = Variable<String>(reasonCode.value);
    }
    if (fieldRefsJson.present) {
      map['field_refs_json'] = Variable<String>(fieldRefsJson.value);
    }
    if (severity.present) {
      map['severity'] = Variable<String>(
        $ReviewQueueTable.$converterseverity.toSql(severity.value),
      );
    }
    if (resolvedBy.present) {
      map['resolved_by'] = Variable<String>(resolvedBy.value);
    }
    if (resolvedAt.present) {
      map['resolved_at'] = Variable<String>(
        $ReviewQueueTable.$converterresolvedAt.toSql(resolvedAt.value),
      );
    }
    if (correctionJson.present) {
      map['correction_json'] = Variable<String>(correctionJson.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(
        $ReviewQueueTable.$converteroutcome.toSql(outcome.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewQueueCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('scanId: $scanId, ')
          ..write('reasonCode: $reasonCode, ')
          ..write('fieldRefsJson: $fieldRefsJson, ')
          ..write('severity: $severity, ')
          ..write('resolvedBy: $resolvedBy, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('correctionJson: $correctionJson, ')
          ..write('outcome: $outcome, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReportJobsTable extends ReportJobs
    with TableInfo<$ReportJobsTable, ReportJob> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReportJobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _examIdMeta = const VerificationMeta('examId');
  @override
  late final GeneratedColumn<String> examId = GeneratedColumn<String>(
    'exam_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exams (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<ReportJobType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ReportJobType>($ReportJobsTable.$convertertype);
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paramsJsonMeta = const VerificationMeta(
    'paramsJson',
  );
  @override
  late final GeneratedColumn<String> paramsJson = GeneratedColumn<String>(
    'params_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ReportJobStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('queued'),
      ).withConverter<ReportJobStatus>($ReportJobsTable.$converterstatus);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> generatedAt =
      GeneratedColumn<String>(
        'generated_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($ReportJobsTable.$convertergeneratedAt);
  static const VerificationMeta _errorTextMeta = const VerificationMeta(
    'errorText',
  );
  @override
  late final GeneratedColumn<String> errorText = GeneratedColumn<String>(
    'error_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tenantId,
    examId,
    type,
    format,
    paramsJson,
    filePath,
    status,
    generatedAt,
    errorText,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'report_jobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReportJob> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('exam_id')) {
      context.handle(
        _examIdMeta,
        examId.isAcceptableOrUnknown(data['exam_id']!, _examIdMeta),
      );
    } else if (isInserting) {
      context.missing(_examIdMeta);
    }
    if (data.containsKey('format')) {
      context.handle(
        _formatMeta,
        format.isAcceptableOrUnknown(data['format']!, _formatMeta),
      );
    } else if (isInserting) {
      context.missing(_formatMeta);
    }
    if (data.containsKey('params_json')) {
      context.handle(
        _paramsJsonMeta,
        paramsJson.isAcceptableOrUnknown(data['params_json']!, _paramsJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_paramsJsonMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    }
    if (data.containsKey('error_text')) {
      context.handle(
        _errorTextMeta,
        errorText.isAcceptableOrUnknown(data['error_text']!, _errorTextMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReportJob map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReportJob(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      examId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exam_id'],
      )!,
      type: $ReportJobsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      format: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}format'],
      )!,
      paramsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}params_json'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      ),
      status: $ReportJobsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      generatedAt: $ReportJobsTable.$convertergeneratedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}generated_at'],
        ),
      ),
      errorText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_text'],
      ),
    );
  }

  @override
  $ReportJobsTable createAlias(String alias) {
    return $ReportJobsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ReportJobType, String, String> $convertertype =
      const EnumNameConverter<ReportJobType>(ReportJobType.values);
  static JsonTypeConverter2<ReportJobStatus, String, String> $converterstatus =
      const EnumNameConverter<ReportJobStatus>(ReportJobStatus.values);
  static TypeConverter<DateTime?, String?> $convertergeneratedAt =
      nullableIsoDate;
}

class ReportJob extends DataClass implements Insertable<ReportJob> {
  final String id;
  final String tenantId;

  /// Report artifacts are regenerable — they die with the exam.
  final String examId;
  final ReportJobType type;
  final String format;
  final String paramsJson;
  final String? filePath;
  final ReportJobStatus status;
  final DateTime? generatedAt;
  final String? errorText;
  const ReportJob({
    required this.id,
    required this.tenantId,
    required this.examId,
    required this.type,
    required this.format,
    required this.paramsJson,
    this.filePath,
    required this.status,
    this.generatedAt,
    this.errorText,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    map['exam_id'] = Variable<String>(examId);
    {
      map['type'] = Variable<String>(
        $ReportJobsTable.$convertertype.toSql(type),
      );
    }
    map['format'] = Variable<String>(format);
    map['params_json'] = Variable<String>(paramsJson);
    if (!nullToAbsent || filePath != null) {
      map['file_path'] = Variable<String>(filePath);
    }
    {
      map['status'] = Variable<String>(
        $ReportJobsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || generatedAt != null) {
      map['generated_at'] = Variable<String>(
        $ReportJobsTable.$convertergeneratedAt.toSql(generatedAt),
      );
    }
    if (!nullToAbsent || errorText != null) {
      map['error_text'] = Variable<String>(errorText);
    }
    return map;
  }

  ReportJobsCompanion toCompanion(bool nullToAbsent) {
    return ReportJobsCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      examId: Value(examId),
      type: Value(type),
      format: Value(format),
      paramsJson: Value(paramsJson),
      filePath: filePath == null && nullToAbsent
          ? const Value.absent()
          : Value(filePath),
      status: Value(status),
      generatedAt: generatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(generatedAt),
      errorText: errorText == null && nullToAbsent
          ? const Value.absent()
          : Value(errorText),
    );
  }

  factory ReportJob.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReportJob(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      examId: serializer.fromJson<String>(json['examId']),
      type: $ReportJobsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      format: serializer.fromJson<String>(json['format']),
      paramsJson: serializer.fromJson<String>(json['paramsJson']),
      filePath: serializer.fromJson<String?>(json['filePath']),
      status: $ReportJobsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      generatedAt: serializer.fromJson<DateTime?>(json['generatedAt']),
      errorText: serializer.fromJson<String?>(json['errorText']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'examId': serializer.toJson<String>(examId),
      'type': serializer.toJson<String>(
        $ReportJobsTable.$convertertype.toJson(type),
      ),
      'format': serializer.toJson<String>(format),
      'paramsJson': serializer.toJson<String>(paramsJson),
      'filePath': serializer.toJson<String?>(filePath),
      'status': serializer.toJson<String>(
        $ReportJobsTable.$converterstatus.toJson(status),
      ),
      'generatedAt': serializer.toJson<DateTime?>(generatedAt),
      'errorText': serializer.toJson<String?>(errorText),
    };
  }

  ReportJob copyWith({
    String? id,
    String? tenantId,
    String? examId,
    ReportJobType? type,
    String? format,
    String? paramsJson,
    Value<String?> filePath = const Value.absent(),
    ReportJobStatus? status,
    Value<DateTime?> generatedAt = const Value.absent(),
    Value<String?> errorText = const Value.absent(),
  }) => ReportJob(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    examId: examId ?? this.examId,
    type: type ?? this.type,
    format: format ?? this.format,
    paramsJson: paramsJson ?? this.paramsJson,
    filePath: filePath.present ? filePath.value : this.filePath,
    status: status ?? this.status,
    generatedAt: generatedAt.present ? generatedAt.value : this.generatedAt,
    errorText: errorText.present ? errorText.value : this.errorText,
  );
  ReportJob copyWithCompanion(ReportJobsCompanion data) {
    return ReportJob(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      examId: data.examId.present ? data.examId.value : this.examId,
      type: data.type.present ? data.type.value : this.type,
      format: data.format.present ? data.format.value : this.format,
      paramsJson: data.paramsJson.present
          ? data.paramsJson.value
          : this.paramsJson,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      status: data.status.present ? data.status.value : this.status,
      generatedAt: data.generatedAt.present
          ? data.generatedAt.value
          : this.generatedAt,
      errorText: data.errorText.present ? data.errorText.value : this.errorText,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReportJob(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('examId: $examId, ')
          ..write('type: $type, ')
          ..write('format: $format, ')
          ..write('paramsJson: $paramsJson, ')
          ..write('filePath: $filePath, ')
          ..write('status: $status, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('errorText: $errorText')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tenantId,
    examId,
    type,
    format,
    paramsJson,
    filePath,
    status,
    generatedAt,
    errorText,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReportJob &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.examId == this.examId &&
          other.type == this.type &&
          other.format == this.format &&
          other.paramsJson == this.paramsJson &&
          other.filePath == this.filePath &&
          other.status == this.status &&
          other.generatedAt == this.generatedAt &&
          other.errorText == this.errorText);
}

class ReportJobsCompanion extends UpdateCompanion<ReportJob> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String> examId;
  final Value<ReportJobType> type;
  final Value<String> format;
  final Value<String> paramsJson;
  final Value<String?> filePath;
  final Value<ReportJobStatus> status;
  final Value<DateTime?> generatedAt;
  final Value<String?> errorText;
  final Value<int> rowid;
  const ReportJobsCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.examId = const Value.absent(),
    this.type = const Value.absent(),
    this.format = const Value.absent(),
    this.paramsJson = const Value.absent(),
    this.filePath = const Value.absent(),
    this.status = const Value.absent(),
    this.generatedAt = const Value.absent(),
    this.errorText = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReportJobsCompanion.insert({
    this.id = const Value.absent(),
    required String tenantId,
    required String examId,
    required ReportJobType type,
    required String format,
    required String paramsJson,
    this.filePath = const Value.absent(),
    this.status = const Value.absent(),
    this.generatedAt = const Value.absent(),
    this.errorText = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       examId = Value(examId),
       type = Value(type),
       format = Value(format),
       paramsJson = Value(paramsJson);
  static Insertable<ReportJob> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? examId,
    Expression<String>? type,
    Expression<String>? format,
    Expression<String>? paramsJson,
    Expression<String>? filePath,
    Expression<String>? status,
    Expression<String>? generatedAt,
    Expression<String>? errorText,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (examId != null) 'exam_id': examId,
      if (type != null) 'type': type,
      if (format != null) 'format': format,
      if (paramsJson != null) 'params_json': paramsJson,
      if (filePath != null) 'file_path': filePath,
      if (status != null) 'status': status,
      if (generatedAt != null) 'generated_at': generatedAt,
      if (errorText != null) 'error_text': errorText,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReportJobsCompanion copyWith({
    Value<String>? id,
    Value<String>? tenantId,
    Value<String>? examId,
    Value<ReportJobType>? type,
    Value<String>? format,
    Value<String>? paramsJson,
    Value<String?>? filePath,
    Value<ReportJobStatus>? status,
    Value<DateTime?>? generatedAt,
    Value<String?>? errorText,
    Value<int>? rowid,
  }) {
    return ReportJobsCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      examId: examId ?? this.examId,
      type: type ?? this.type,
      format: format ?? this.format,
      paramsJson: paramsJson ?? this.paramsJson,
      filePath: filePath ?? this.filePath,
      status: status ?? this.status,
      generatedAt: generatedAt ?? this.generatedAt,
      errorText: errorText ?? this.errorText,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (examId.present) {
      map['exam_id'] = Variable<String>(examId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $ReportJobsTable.$convertertype.toSql(type.value),
      );
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (paramsJson.present) {
      map['params_json'] = Variable<String>(paramsJson.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $ReportJobsTable.$converterstatus.toSql(status.value),
      );
    }
    if (generatedAt.present) {
      map['generated_at'] = Variable<String>(
        $ReportJobsTable.$convertergeneratedAt.toSql(generatedAt.value),
      );
    }
    if (errorText.present) {
      map['error_text'] = Variable<String>(errorText.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReportJobsCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('examId: $examId, ')
          ..write('type: $type, ')
          ..write('format: $format, ')
          ..write('paramsJson: $paramsJson, ')
          ..write('filePath: $filePath, ')
          ..write('status: $status, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('errorText: $errorText, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AuditLogTable extends AuditLog
    with TableInfo<$AuditLogTable, AuditLogEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _beforeJsonMeta = const VerificationMeta(
    'beforeJson',
  );
  @override
  late final GeneratedColumn<String> beforeJson = GeneratedColumn<String>(
    'before_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _afterJsonMeta = const VerificationMeta(
    'afterJson',
  );
  @override
  late final GeneratedColumn<String> afterJson = GeneratedColumn<String>(
    'after_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, String> at =
      GeneratedColumn<String>(
        'at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        clientDefault: nowIsoUtc,
      ).withConverter<DateTime>($AuditLogTable.$converterat);
  static const VerificationMeta _byUserMeta = const VerificationMeta('byUser');
  @override
  late final GeneratedColumn<String> byUser = GeneratedColumn<String>(
    'by_user',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tenantId,
    entity,
    entityId,
    action,
    beforeJson,
    afterJson,
    at,
    byUser,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<AuditLogEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
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
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('before_json')) {
      context.handle(
        _beforeJsonMeta,
        beforeJson.isAcceptableOrUnknown(data['before_json']!, _beforeJsonMeta),
      );
    }
    if (data.containsKey('after_json')) {
      context.handle(
        _afterJsonMeta,
        afterJson.isAcceptableOrUnknown(data['after_json']!, _afterJsonMeta),
      );
    }
    if (data.containsKey('by_user')) {
      context.handle(
        _byUserMeta,
        byUser.isAcceptableOrUnknown(data['by_user']!, _byUserMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuditLogEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditLogEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      beforeJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}before_json'],
      ),
      afterJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}after_json'],
      ),
      at: $AuditLogTable.$converterat.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}at'],
        )!,
      ),
      byUser: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}by_user'],
      ),
    );
  }

  @override
  $AuditLogTable createAlias(String alias) {
    return $AuditLogTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, String> $converterat =
      const IsoDateTimeConverter();
}

class AuditLogEntry extends DataClass implements Insertable<AuditLogEntry> {
  final String id;
  final String tenantId;
  final String entity;
  final String entityId;
  final String action;
  final String? beforeJson;
  final String? afterJson;
  final DateTime at;
  final String? byUser;
  const AuditLogEntry({
    required this.id,
    required this.tenantId,
    required this.entity,
    required this.entityId,
    required this.action,
    this.beforeJson,
    this.afterJson,
    required this.at,
    this.byUser,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    map['entity'] = Variable<String>(entity);
    map['entity_id'] = Variable<String>(entityId);
    map['action'] = Variable<String>(action);
    if (!nullToAbsent || beforeJson != null) {
      map['before_json'] = Variable<String>(beforeJson);
    }
    if (!nullToAbsent || afterJson != null) {
      map['after_json'] = Variable<String>(afterJson);
    }
    {
      map['at'] = Variable<String>($AuditLogTable.$converterat.toSql(at));
    }
    if (!nullToAbsent || byUser != null) {
      map['by_user'] = Variable<String>(byUser);
    }
    return map;
  }

  AuditLogCompanion toCompanion(bool nullToAbsent) {
    return AuditLogCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      entity: Value(entity),
      entityId: Value(entityId),
      action: Value(action),
      beforeJson: beforeJson == null && nullToAbsent
          ? const Value.absent()
          : Value(beforeJson),
      afterJson: afterJson == null && nullToAbsent
          ? const Value.absent()
          : Value(afterJson),
      at: Value(at),
      byUser: byUser == null && nullToAbsent
          ? const Value.absent()
          : Value(byUser),
    );
  }

  factory AuditLogEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditLogEntry(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      entity: serializer.fromJson<String>(json['entity']),
      entityId: serializer.fromJson<String>(json['entityId']),
      action: serializer.fromJson<String>(json['action']),
      beforeJson: serializer.fromJson<String?>(json['beforeJson']),
      afterJson: serializer.fromJson<String?>(json['afterJson']),
      at: serializer.fromJson<DateTime>(json['at']),
      byUser: serializer.fromJson<String?>(json['byUser']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'entity': serializer.toJson<String>(entity),
      'entityId': serializer.toJson<String>(entityId),
      'action': serializer.toJson<String>(action),
      'beforeJson': serializer.toJson<String?>(beforeJson),
      'afterJson': serializer.toJson<String?>(afterJson),
      'at': serializer.toJson<DateTime>(at),
      'byUser': serializer.toJson<String?>(byUser),
    };
  }

  AuditLogEntry copyWith({
    String? id,
    String? tenantId,
    String? entity,
    String? entityId,
    String? action,
    Value<String?> beforeJson = const Value.absent(),
    Value<String?> afterJson = const Value.absent(),
    DateTime? at,
    Value<String?> byUser = const Value.absent(),
  }) => AuditLogEntry(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    entity: entity ?? this.entity,
    entityId: entityId ?? this.entityId,
    action: action ?? this.action,
    beforeJson: beforeJson.present ? beforeJson.value : this.beforeJson,
    afterJson: afterJson.present ? afterJson.value : this.afterJson,
    at: at ?? this.at,
    byUser: byUser.present ? byUser.value : this.byUser,
  );
  AuditLogEntry copyWithCompanion(AuditLogCompanion data) {
    return AuditLogEntry(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      entity: data.entity.present ? data.entity.value : this.entity,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      action: data.action.present ? data.action.value : this.action,
      beforeJson: data.beforeJson.present
          ? data.beforeJson.value
          : this.beforeJson,
      afterJson: data.afterJson.present ? data.afterJson.value : this.afterJson,
      at: data.at.present ? data.at.value : this.at,
      byUser: data.byUser.present ? data.byUser.value : this.byUser,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogEntry(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('action: $action, ')
          ..write('beforeJson: $beforeJson, ')
          ..write('afterJson: $afterJson, ')
          ..write('at: $at, ')
          ..write('byUser: $byUser')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tenantId,
    entity,
    entityId,
    action,
    beforeJson,
    afterJson,
    at,
    byUser,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditLogEntry &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.entity == this.entity &&
          other.entityId == this.entityId &&
          other.action == this.action &&
          other.beforeJson == this.beforeJson &&
          other.afterJson == this.afterJson &&
          other.at == this.at &&
          other.byUser == this.byUser);
}

class AuditLogCompanion extends UpdateCompanion<AuditLogEntry> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String> entity;
  final Value<String> entityId;
  final Value<String> action;
  final Value<String?> beforeJson;
  final Value<String?> afterJson;
  final Value<DateTime> at;
  final Value<String?> byUser;
  final Value<int> rowid;
  const AuditLogCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.entity = const Value.absent(),
    this.entityId = const Value.absent(),
    this.action = const Value.absent(),
    this.beforeJson = const Value.absent(),
    this.afterJson = const Value.absent(),
    this.at = const Value.absent(),
    this.byUser = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AuditLogCompanion.insert({
    this.id = const Value.absent(),
    required String tenantId,
    required String entity,
    required String entityId,
    required String action,
    this.beforeJson = const Value.absent(),
    this.afterJson = const Value.absent(),
    this.at = const Value.absent(),
    this.byUser = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       entity = Value(entity),
       entityId = Value(entityId),
       action = Value(action);
  static Insertable<AuditLogEntry> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? entity,
    Expression<String>? entityId,
    Expression<String>? action,
    Expression<String>? beforeJson,
    Expression<String>? afterJson,
    Expression<String>? at,
    Expression<String>? byUser,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (entity != null) 'entity': entity,
      if (entityId != null) 'entity_id': entityId,
      if (action != null) 'action': action,
      if (beforeJson != null) 'before_json': beforeJson,
      if (afterJson != null) 'after_json': afterJson,
      if (at != null) 'at': at,
      if (byUser != null) 'by_user': byUser,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AuditLogCompanion copyWith({
    Value<String>? id,
    Value<String>? tenantId,
    Value<String>? entity,
    Value<String>? entityId,
    Value<String>? action,
    Value<String?>? beforeJson,
    Value<String?>? afterJson,
    Value<DateTime>? at,
    Value<String?>? byUser,
    Value<int>? rowid,
  }) {
    return AuditLogCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      entity: entity ?? this.entity,
      entityId: entityId ?? this.entityId,
      action: action ?? this.action,
      beforeJson: beforeJson ?? this.beforeJson,
      afterJson: afterJson ?? this.afterJson,
      at: at ?? this.at,
      byUser: byUser ?? this.byUser,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (beforeJson.present) {
      map['before_json'] = Variable<String>(beforeJson.value);
    }
    if (afterJson.present) {
      map['after_json'] = Variable<String>(afterJson.value);
    }
    if (at.present) {
      map['at'] = Variable<String>($AuditLogTable.$converterat.toSql(at.value));
    }
    if (byUser.present) {
      map['by_user'] = Variable<String>(byUser.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('action: $action, ')
          ..write('beforeJson: $beforeJson, ')
          ..write('afterJson: $afterJson, ')
          ..write('at: $at, ')
          ..write('byUser: $byUser, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncOutboxTable extends SyncOutbox
    with TableInfo<$SyncOutboxTable, SyncOutboxEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncOutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetTableMeta = const VerificationMeta(
    'targetTable',
  );
  @override
  late final GeneratedColumn<String> targetTable = GeneratedColumn<String>(
    'table_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<String> rowId = GeneratedColumn<String>(
    'row_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncOp, String> op =
      GeneratedColumn<String>(
        'op',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SyncOp>($SyncOutboxTable.$converterop);
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, String> lastAttemptAt =
      GeneratedColumn<String>(
        'last_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($SyncOutboxTable.$converterlastAttemptAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tenantId,
    targetTable,
    rowId,
    op,
    payloadJson,
    attempts,
    lastAttemptAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncOutboxEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('table_name')) {
      context.handle(
        _targetTableMeta,
        targetTable.isAcceptableOrUnknown(
          data['table_name']!,
          _targetTableMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetTableMeta);
    }
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    } else if (isInserting) {
      context.missing(_rowIdMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncOutboxEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncOutboxEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      targetTable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_name'],
      )!,
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}row_id'],
      )!,
      op: $SyncOutboxTable.$converterop.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}op'],
        )!,
      ),
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastAttemptAt: $SyncOutboxTable.$converterlastAttemptAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}last_attempt_at'],
        ),
      ),
    );
  }

  @override
  $SyncOutboxTable createAlias(String alias) {
    return $SyncOutboxTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncOp, String, String> $converterop =
      const EnumNameConverter<SyncOp>(SyncOp.values);
  static TypeConverter<DateTime?, String?> $converterlastAttemptAt =
      nullableIsoDate;
}

class SyncOutboxEntry extends DataClass implements Insertable<SyncOutboxEntry> {
  final String id;
  final String tenantId;

  /// SQL name pinned to `table_name` — the Dart getter can't be `tableName`
  /// because [Table.tableName] already owns that member.
  final String targetTable;
  final String rowId;
  final SyncOp op;
  final String payloadJson;
  final int attempts;
  final DateTime? lastAttemptAt;
  const SyncOutboxEntry({
    required this.id,
    required this.tenantId,
    required this.targetTable,
    required this.rowId,
    required this.op,
    required this.payloadJson,
    required this.attempts,
    this.lastAttemptAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tenant_id'] = Variable<String>(tenantId);
    map['table_name'] = Variable<String>(targetTable);
    map['row_id'] = Variable<String>(rowId);
    {
      map['op'] = Variable<String>($SyncOutboxTable.$converterop.toSql(op));
    }
    map['payload_json'] = Variable<String>(payloadJson);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<String>(
        $SyncOutboxTable.$converterlastAttemptAt.toSql(lastAttemptAt),
      );
    }
    return map;
  }

  SyncOutboxCompanion toCompanion(bool nullToAbsent) {
    return SyncOutboxCompanion(
      id: Value(id),
      tenantId: Value(tenantId),
      targetTable: Value(targetTable),
      rowId: Value(rowId),
      op: Value(op),
      payloadJson: Value(payloadJson),
      attempts: Value(attempts),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
    );
  }

  factory SyncOutboxEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncOutboxEntry(
      id: serializer.fromJson<String>(json['id']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      targetTable: serializer.fromJson<String>(json['targetTable']),
      rowId: serializer.fromJson<String>(json['rowId']),
      op: $SyncOutboxTable.$converterop.fromJson(
        serializer.fromJson<String>(json['op']),
      ),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tenantId': serializer.toJson<String>(tenantId),
      'targetTable': serializer.toJson<String>(targetTable),
      'rowId': serializer.toJson<String>(rowId),
      'op': serializer.toJson<String>($SyncOutboxTable.$converterop.toJson(op)),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'attempts': serializer.toJson<int>(attempts),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
    };
  }

  SyncOutboxEntry copyWith({
    String? id,
    String? tenantId,
    String? targetTable,
    String? rowId,
    SyncOp? op,
    String? payloadJson,
    int? attempts,
    Value<DateTime?> lastAttemptAt = const Value.absent(),
  }) => SyncOutboxEntry(
    id: id ?? this.id,
    tenantId: tenantId ?? this.tenantId,
    targetTable: targetTable ?? this.targetTable,
    rowId: rowId ?? this.rowId,
    op: op ?? this.op,
    payloadJson: payloadJson ?? this.payloadJson,
    attempts: attempts ?? this.attempts,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
  );
  SyncOutboxEntry copyWithCompanion(SyncOutboxCompanion data) {
    return SyncOutboxEntry(
      id: data.id.present ? data.id.value : this.id,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      targetTable: data.targetTable.present
          ? data.targetTable.value
          : this.targetTable,
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      op: data.op.present ? data.op.value : this.op,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxEntry(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('targetTable: $targetTable, ')
          ..write('rowId: $rowId, ')
          ..write('op: $op, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('attempts: $attempts, ')
          ..write('lastAttemptAt: $lastAttemptAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tenantId,
    targetTable,
    rowId,
    op,
    payloadJson,
    attempts,
    lastAttemptAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncOutboxEntry &&
          other.id == this.id &&
          other.tenantId == this.tenantId &&
          other.targetTable == this.targetTable &&
          other.rowId == this.rowId &&
          other.op == this.op &&
          other.payloadJson == this.payloadJson &&
          other.attempts == this.attempts &&
          other.lastAttemptAt == this.lastAttemptAt);
}

class SyncOutboxCompanion extends UpdateCompanion<SyncOutboxEntry> {
  final Value<String> id;
  final Value<String> tenantId;
  final Value<String> targetTable;
  final Value<String> rowId;
  final Value<SyncOp> op;
  final Value<String> payloadJson;
  final Value<int> attempts;
  final Value<DateTime?> lastAttemptAt;
  final Value<int> rowid;
  const SyncOutboxCompanion({
    this.id = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.targetTable = const Value.absent(),
    this.rowId = const Value.absent(),
    this.op = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncOutboxCompanion.insert({
    this.id = const Value.absent(),
    required String tenantId,
    required String targetTable,
    required String rowId,
    required SyncOp op,
    this.payloadJson = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : tenantId = Value(tenantId),
       targetTable = Value(targetTable),
       rowId = Value(rowId),
       op = Value(op);
  static Insertable<SyncOutboxEntry> custom({
    Expression<String>? id,
    Expression<String>? tenantId,
    Expression<String>? targetTable,
    Expression<String>? rowId,
    Expression<String>? op,
    Expression<String>? payloadJson,
    Expression<int>? attempts,
    Expression<String>? lastAttemptAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (targetTable != null) 'table_name': targetTable,
      if (rowId != null) 'row_id': rowId,
      if (op != null) 'op': op,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (attempts != null) 'attempts': attempts,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncOutboxCompanion copyWith({
    Value<String>? id,
    Value<String>? tenantId,
    Value<String>? targetTable,
    Value<String>? rowId,
    Value<SyncOp>? op,
    Value<String>? payloadJson,
    Value<int>? attempts,
    Value<DateTime?>? lastAttemptAt,
    Value<int>? rowid,
  }) {
    return SyncOutboxCompanion(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      targetTable: targetTable ?? this.targetTable,
      rowId: rowId ?? this.rowId,
      op: op ?? this.op,
      payloadJson: payloadJson ?? this.payloadJson,
      attempts: attempts ?? this.attempts,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (targetTable.present) {
      map['table_name'] = Variable<String>(targetTable.value);
    }
    if (rowId.present) {
      map['row_id'] = Variable<String>(rowId.value);
    }
    if (op.present) {
      map['op'] = Variable<String>(
        $SyncOutboxTable.$converterop.toSql(op.value),
      );
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<String>(
        $SyncOutboxTable.$converterlastAttemptAt.toSql(lastAttemptAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxCompanion(')
          ..write('id: $id, ')
          ..write('tenantId: $tenantId, ')
          ..write('targetTable: $targetTable, ')
          ..write('rowId: $rowId, ')
          ..write('op: $op, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('attempts: $attempts, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDb extends GeneratedDatabase {
  _$AppDb(QueryExecutor e) : super(e);
  $AppDbManager get managers => $AppDbManager(this);
  late final $TenantsTable tenants = $TenantsTable(this);
  late final $InstitutesTable institutes = $InstitutesTable(this);
  late final $StudentsTable students = $StudentsTable(this);
  late final $SheetLayoutsTable sheetLayouts = $SheetLayoutsTable(this);
  late final $ExamsTable exams = $ExamsTable(this);
  late final $QuestionSetsTable questionSets = $QuestionSetsTable(this);
  late final $ScoringRulesTable scoringRules = $ScoringRulesTable(this);
  late final $AnswerKeyVersionsTable answerKeyVersions =
      $AnswerKeyVersionsTable(this);
  late final $AnswerKeyEntriesTable answerKeyEntries = $AnswerKeyEntriesTable(
    this,
  );
  late final $ScansTable scans = $ScansTable(this);
  late final $BubbleReadsTable bubbleReads = $BubbleReadsTable(this);
  late final $ScoringRunsTable scoringRuns = $ScoringRunsTable(this);
  late final $ResultsTable results = $ResultsTable(this);
  late final $ReviewQueueTable reviewQueue = $ReviewQueueTable(this);
  late final $ReportJobsTable reportJobs = $ReportJobsTable(this);
  late final $AuditLogTable auditLog = $AuditLogTable(this);
  late final $SyncOutboxTable syncOutbox = $SyncOutboxTable(this);
  late final ScansDao scansDao = ScansDao(this as AppDb);
  late final ResultsDao resultsDao = ResultsDao(this as AppDb);
  late final ReviewDao reviewDao = ReviewDao(this as AppDb);
  late final AnalyticsDao analyticsDao = AnalyticsDao(this as AppDb);
  late final LayoutsDao layoutsDao = LayoutsDao(this as AppDb);
  late final ExamsDao examsDao = ExamsDao(this as AppDb);
  late final KeysDao keysDao = KeysDao(this as AppDb);
  late final SyncOutboxDao syncOutboxDao = SyncOutboxDao(this as AppDb);
  late final ReportJobsDao reportJobsDao = ReportJobsDao(this as AppDb);
  late final StudentsDao studentsDao = StudentsDao(this as AppDb);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    tenants,
    institutes,
    students,
    sheetLayouts,
    exams,
    questionSets,
    scoringRules,
    answerKeyVersions,
    answerKeyEntries,
    scans,
    bubbleReads,
    scoringRuns,
    results,
    reviewQueue,
    reportJobs,
    auditLog,
    syncOutbox,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'institutes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('students', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'exams',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('question_sets', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'exams',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('answer_key_versions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'answer_key_versions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('answer_key_versions', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'answer_key_versions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('answer_key_entries', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'scoring_rules',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('answer_key_entries', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'students',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('scans', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'scans',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('bubble_reads', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'scans',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('review_queue', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'exams',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('report_jobs', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$TenantsTableCreateCompanionBuilder =
    TenantsCompanion Function({
      required String id,
      required String name,
      required String plan,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$TenantsTableUpdateCompanionBuilder =
    TenantsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> plan,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$TenantsTableFilterComposer extends Composer<_$AppDb, $TenantsTable> {
  $$TenantsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plan => $composableBuilder(
    column: $table.plan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$TenantsTableOrderingComposer extends Composer<_$AppDb, $TenantsTable> {
  $$TenantsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plan => $composableBuilder(
    column: $table.plan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TenantsTableAnnotationComposer
    extends Composer<_$AppDb, $TenantsTable> {
  $$TenantsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get plan =>
      $composableBuilder(column: $table.plan, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$TenantsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $TenantsTable,
          Tenant,
          $$TenantsTableFilterComposer,
          $$TenantsTableOrderingComposer,
          $$TenantsTableAnnotationComposer,
          $$TenantsTableCreateCompanionBuilder,
          $$TenantsTableUpdateCompanionBuilder,
          (Tenant, BaseReferences<_$AppDb, $TenantsTable, Tenant>),
          Tenant,
          PrefetchHooks Function()
        > {
  $$TenantsTableTableManager(_$AppDb db, $TenantsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TenantsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TenantsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TenantsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> plan = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TenantsCompanion(
                id: id,
                name: name,
                plan: plan,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String plan,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TenantsCompanion.insert(
                id: id,
                name: name,
                plan: plan,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TenantsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $TenantsTable,
      Tenant,
      $$TenantsTableFilterComposer,
      $$TenantsTableOrderingComposer,
      $$TenantsTableAnnotationComposer,
      $$TenantsTableCreateCompanionBuilder,
      $$TenantsTableUpdateCompanionBuilder,
      (Tenant, BaseReferences<_$AppDb, $TenantsTable, Tenant>),
      Tenant,
      PrefetchHooks Function()
    >;
typedef $$InstitutesTableCreateCompanionBuilder =
    InstitutesCompanion Function({
      Value<String> id,
      required String tenantId,
      required String name,
      required String code,
      Value<DateTime> createdAt,
      Value<SyncState> syncState,
      Value<int> rowid,
    });
typedef $$InstitutesTableUpdateCompanionBuilder =
    InstitutesCompanion Function({
      Value<String> id,
      Value<String> tenantId,
      Value<String> name,
      Value<String> code,
      Value<DateTime> createdAt,
      Value<SyncState> syncState,
      Value<int> rowid,
    });

final class $$InstitutesTableReferences
    extends BaseReferences<_$AppDb, $InstitutesTable, Institute> {
  $$InstitutesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$StudentsTable, List<Student>> _studentsRefsTable(
    _$AppDb db,
  ) => MultiTypedResultKey.fromTable(
    db.students,
    aliasName: 'institutes__id__students__institute_id',
  );

  $$StudentsTableProcessedTableManager get studentsRefs {
    final manager = $$StudentsTableTableManager(
      $_db,
      $_db.students,
    ).filter((f) => f.instituteId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_studentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExamsTable, List<Exam>> _examsRefsTable(
    _$AppDb db,
  ) => MultiTypedResultKey.fromTable(
    db.exams,
    aliasName: 'institutes__id__exams__institute_id',
  );

  $$ExamsTableProcessedTableManager get examsRefs {
    final manager = $$ExamsTableTableManager(
      $_db,
      $_db.exams,
    ).filter((f) => f.instituteId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_examsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$InstitutesTableFilterComposer
    extends Composer<_$AppDb, $InstitutesTable> {
  $$InstitutesTableFilterComposer({
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

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<SyncState, SyncState, String> get syncState =>
      $composableBuilder(
        column: $table.syncState,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  Expression<bool> studentsRefs(
    Expression<bool> Function($$StudentsTableFilterComposer f) f,
  ) {
    final $$StudentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.students,
      getReferencedColumn: (t) => t.instituteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableFilterComposer(
            $db: $db,
            $table: $db.students,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> examsRefs(
    Expression<bool> Function($$ExamsTableFilterComposer f) f,
  ) {
    final $$ExamsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exams,
      getReferencedColumn: (t) => t.instituteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamsTableFilterComposer(
            $db: $db,
            $table: $db.exams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$InstitutesTableOrderingComposer
    extends Composer<_$AppDb, $InstitutesTable> {
  $$InstitutesTableOrderingComposer({
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

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InstitutesTableAnnotationComposer
    extends Composer<_$AppDb, $InstitutesTable> {
  $$InstitutesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncState, String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  Expression<T> studentsRefs<T extends Object>(
    Expression<T> Function($$StudentsTableAnnotationComposer a) f,
  ) {
    final $$StudentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.students,
      getReferencedColumn: (t) => t.instituteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableAnnotationComposer(
            $db: $db,
            $table: $db.students,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> examsRefs<T extends Object>(
    Expression<T> Function($$ExamsTableAnnotationComposer a) f,
  ) {
    final $$ExamsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exams,
      getReferencedColumn: (t) => t.instituteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamsTableAnnotationComposer(
            $db: $db,
            $table: $db.exams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$InstitutesTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $InstitutesTable,
          Institute,
          $$InstitutesTableFilterComposer,
          $$InstitutesTableOrderingComposer,
          $$InstitutesTableAnnotationComposer,
          $$InstitutesTableCreateCompanionBuilder,
          $$InstitutesTableUpdateCompanionBuilder,
          (Institute, $$InstitutesTableReferences),
          Institute,
          PrefetchHooks Function({bool studentsRefs, bool examsRefs})
        > {
  $$InstitutesTableTableManager(_$AppDb db, $InstitutesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InstitutesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InstitutesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InstitutesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InstitutesCompanion(
                id: id,
                tenantId: tenantId,
                name: name,
                code: code,
                createdAt: createdAt,
                syncState: syncState,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String tenantId,
                required String name,
                required String code,
                Value<DateTime> createdAt = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InstitutesCompanion.insert(
                id: id,
                tenantId: tenantId,
                name: name,
                code: code,
                createdAt: createdAt,
                syncState: syncState,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$InstitutesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({studentsRefs = false, examsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (studentsRefs) db.students,
                if (examsRefs) db.exams,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (studentsRefs)
                    await $_getPrefetchedData<
                      Institute,
                      $InstitutesTable,
                      Student
                    >(
                      currentTable: table,
                      referencedTable: $$InstitutesTableReferences
                          ._studentsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$InstitutesTableReferences(
                            db,
                            table,
                            p0,
                          ).studentsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.instituteId == item.id,
                          ),
                      typedResults: items,
                    ),
                  if (examsRefs)
                    await $_getPrefetchedData<
                      Institute,
                      $InstitutesTable,
                      Exam
                    >(
                      currentTable: table,
                      referencedTable: $$InstitutesTableReferences
                          ._examsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$InstitutesTableReferences(db, table, p0).examsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.instituteId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$InstitutesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $InstitutesTable,
      Institute,
      $$InstitutesTableFilterComposer,
      $$InstitutesTableOrderingComposer,
      $$InstitutesTableAnnotationComposer,
      $$InstitutesTableCreateCompanionBuilder,
      $$InstitutesTableUpdateCompanionBuilder,
      (Institute, $$InstitutesTableReferences),
      Institute,
      PrefetchHooks Function({bool studentsRefs, bool examsRefs})
    >;
typedef $$StudentsTableCreateCompanionBuilder =
    StudentsCompanion Function({
      Value<String> id,
      required String tenantId,
      required String instituteId,
      required String rollNo,
      Value<String?> name,
      Value<String?> batch,
      Value<DateTime> createdAt,
      Value<SyncState> syncState,
      Value<int> rowid,
    });
typedef $$StudentsTableUpdateCompanionBuilder =
    StudentsCompanion Function({
      Value<String> id,
      Value<String> tenantId,
      Value<String> instituteId,
      Value<String> rollNo,
      Value<String?> name,
      Value<String?> batch,
      Value<DateTime> createdAt,
      Value<SyncState> syncState,
      Value<int> rowid,
    });

final class $$StudentsTableReferences
    extends BaseReferences<_$AppDb, $StudentsTable, Student> {
  $$StudentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $InstitutesTable _instituteIdTable(_$AppDb db) =>
      db.institutes.createAlias('students__institute_id__institutes__id');

  $$InstitutesTableProcessedTableManager get instituteId {
    final $_column = $_itemColumn<String>('institute_id')!;

    final manager = $$InstitutesTableTableManager(
      $_db,
      $_db.institutes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_instituteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ScansTable, List<Scan>> _scansRefsTable(
    _$AppDb db,
  ) => MultiTypedResultKey.fromTable(
    db.scans,
    aliasName: 'students__id__scans__student_id',
  );

  $$ScansTableProcessedTableManager get scansRefs {
    final manager = $$ScansTableTableManager(
      $_db,
      $_db.scans,
    ).filter((f) => f.studentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_scansRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ResultsTable, List<Result>> _resultsRefsTable(
    _$AppDb db,
  ) => MultiTypedResultKey.fromTable(
    db.results,
    aliasName: 'students__id__results__student_id',
  );

  $$ResultsTableProcessedTableManager get resultsRefs {
    final manager = $$ResultsTableTableManager(
      $_db,
      $_db.results,
    ).filter((f) => f.studentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_resultsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$StudentsTableFilterComposer extends Composer<_$AppDb, $StudentsTable> {
  $$StudentsTableFilterComposer({
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

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rollNo => $composableBuilder(
    column: $table.rollNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get batch => $composableBuilder(
    column: $table.batch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<SyncState, SyncState, String> get syncState =>
      $composableBuilder(
        column: $table.syncState,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$InstitutesTableFilterComposer get instituteId {
    final $$InstitutesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.instituteId,
      referencedTable: $db.institutes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InstitutesTableFilterComposer(
            $db: $db,
            $table: $db.institutes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> scansRefs(
    Expression<bool> Function($$ScansTableFilterComposer f) f,
  ) {
    final $$ScansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scans,
      getReferencedColumn: (t) => t.studentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScansTableFilterComposer(
            $db: $db,
            $table: $db.scans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> resultsRefs(
    Expression<bool> Function($$ResultsTableFilterComposer f) f,
  ) {
    final $$ResultsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.results,
      getReferencedColumn: (t) => t.studentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ResultsTableFilterComposer(
            $db: $db,
            $table: $db.results,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StudentsTableOrderingComposer
    extends Composer<_$AppDb, $StudentsTable> {
  $$StudentsTableOrderingComposer({
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

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rollNo => $composableBuilder(
    column: $table.rollNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get batch => $composableBuilder(
    column: $table.batch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  $$InstitutesTableOrderingComposer get instituteId {
    final $$InstitutesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.instituteId,
      referencedTable: $db.institutes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InstitutesTableOrderingComposer(
            $db: $db,
            $table: $db.institutes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StudentsTableAnnotationComposer
    extends Composer<_$AppDb, $StudentsTable> {
  $$StudentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get rollNo =>
      $composableBuilder(column: $table.rollNo, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get batch =>
      $composableBuilder(column: $table.batch, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncState, String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  $$InstitutesTableAnnotationComposer get instituteId {
    final $$InstitutesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.instituteId,
      referencedTable: $db.institutes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InstitutesTableAnnotationComposer(
            $db: $db,
            $table: $db.institutes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> scansRefs<T extends Object>(
    Expression<T> Function($$ScansTableAnnotationComposer a) f,
  ) {
    final $$ScansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scans,
      getReferencedColumn: (t) => t.studentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScansTableAnnotationComposer(
            $db: $db,
            $table: $db.scans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> resultsRefs<T extends Object>(
    Expression<T> Function($$ResultsTableAnnotationComposer a) f,
  ) {
    final $$ResultsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.results,
      getReferencedColumn: (t) => t.studentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ResultsTableAnnotationComposer(
            $db: $db,
            $table: $db.results,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StudentsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $StudentsTable,
          Student,
          $$StudentsTableFilterComposer,
          $$StudentsTableOrderingComposer,
          $$StudentsTableAnnotationComposer,
          $$StudentsTableCreateCompanionBuilder,
          $$StudentsTableUpdateCompanionBuilder,
          (Student, $$StudentsTableReferences),
          Student,
          PrefetchHooks Function({
            bool instituteId,
            bool scansRefs,
            bool resultsRefs,
          })
        > {
  $$StudentsTableTableManager(_$AppDb db, $StudentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StudentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StudentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StudentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String> instituteId = const Value.absent(),
                Value<String> rollNo = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> batch = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StudentsCompanion(
                id: id,
                tenantId: tenantId,
                instituteId: instituteId,
                rollNo: rollNo,
                name: name,
                batch: batch,
                createdAt: createdAt,
                syncState: syncState,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String tenantId,
                required String instituteId,
                required String rollNo,
                Value<String?> name = const Value.absent(),
                Value<String?> batch = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StudentsCompanion.insert(
                id: id,
                tenantId: tenantId,
                instituteId: instituteId,
                rollNo: rollNo,
                name: name,
                batch: batch,
                createdAt: createdAt,
                syncState: syncState,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$StudentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({instituteId = false, scansRefs = false, resultsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (scansRefs) db.scans,
                    if (resultsRefs) db.results,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (instituteId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.instituteId,
                                    referencedTable: $$StudentsTableReferences
                                        ._instituteIdTable(db),
                                    referencedColumn: $$StudentsTableReferences
                                        ._instituteIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (scansRefs)
                        await $_getPrefetchedData<
                          Student,
                          $StudentsTable,
                          Scan
                        >(
                          currentTable: table,
                          referencedTable: $$StudentsTableReferences
                              ._scansRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StudentsTableReferences(
                                db,
                                table,
                                p0,
                              ).scansRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.studentId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (resultsRefs)
                        await $_getPrefetchedData<
                          Student,
                          $StudentsTable,
                          Result
                        >(
                          currentTable: table,
                          referencedTable: $$StudentsTableReferences
                              ._resultsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StudentsTableReferences(
                                db,
                                table,
                                p0,
                              ).resultsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.studentId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$StudentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $StudentsTable,
      Student,
      $$StudentsTableFilterComposer,
      $$StudentsTableOrderingComposer,
      $$StudentsTableAnnotationComposer,
      $$StudentsTableCreateCompanionBuilder,
      $$StudentsTableUpdateCompanionBuilder,
      (Student, $$StudentsTableReferences),
      Student,
      PrefetchHooks Function({
        bool instituteId,
        bool scansRefs,
        bool resultsRefs,
      })
    >;
typedef $$SheetLayoutsTableCreateCompanionBuilder =
    SheetLayoutsCompanion Function({
      Value<String> id,
      required String tenantId,
      required String layoutId,
      required int layoutVersion,
      required String specJson,
      required String specHash,
      Value<DateTime> createdAt,
      Value<bool> isActive,
      Value<int> rowid,
    });
typedef $$SheetLayoutsTableUpdateCompanionBuilder =
    SheetLayoutsCompanion Function({
      Value<String> id,
      Value<String> tenantId,
      Value<String> layoutId,
      Value<int> layoutVersion,
      Value<String> specJson,
      Value<String> specHash,
      Value<DateTime> createdAt,
      Value<bool> isActive,
      Value<int> rowid,
    });

final class $$SheetLayoutsTableReferences
    extends BaseReferences<_$AppDb, $SheetLayoutsTable, SheetLayout> {
  $$SheetLayoutsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ExamsTable, List<Exam>> _examsRefsTable(
    _$AppDb db,
  ) => MultiTypedResultKey.fromTable(
    db.exams,
    aliasName: 'sheet_layouts__id__exams__sheet_layout_id',
  );

  $$ExamsTableProcessedTableManager get examsRefs {
    final manager = $$ExamsTableTableManager(
      $_db,
      $_db.exams,
    ).filter((f) => f.sheetLayoutId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_examsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SheetLayoutsTableFilterComposer
    extends Composer<_$AppDb, $SheetLayoutsTable> {
  $$SheetLayoutsTableFilterComposer({
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

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get layoutId => $composableBuilder(
    column: $table.layoutId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get layoutVersion => $composableBuilder(
    column: $table.layoutVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get specJson => $composableBuilder(
    column: $table.specJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get specHash => $composableBuilder(
    column: $table.specHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> examsRefs(
    Expression<bool> Function($$ExamsTableFilterComposer f) f,
  ) {
    final $$ExamsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exams,
      getReferencedColumn: (t) => t.sheetLayoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamsTableFilterComposer(
            $db: $db,
            $table: $db.exams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SheetLayoutsTableOrderingComposer
    extends Composer<_$AppDb, $SheetLayoutsTable> {
  $$SheetLayoutsTableOrderingComposer({
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

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get layoutId => $composableBuilder(
    column: $table.layoutId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get layoutVersion => $composableBuilder(
    column: $table.layoutVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get specJson => $composableBuilder(
    column: $table.specJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get specHash => $composableBuilder(
    column: $table.specHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SheetLayoutsTableAnnotationComposer
    extends Composer<_$AppDb, $SheetLayoutsTable> {
  $$SheetLayoutsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get layoutId =>
      $composableBuilder(column: $table.layoutId, builder: (column) => column);

  GeneratedColumn<int> get layoutVersion => $composableBuilder(
    column: $table.layoutVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get specJson =>
      $composableBuilder(column: $table.specJson, builder: (column) => column);

  GeneratedColumn<String> get specHash =>
      $composableBuilder(column: $table.specHash, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  Expression<T> examsRefs<T extends Object>(
    Expression<T> Function($$ExamsTableAnnotationComposer a) f,
  ) {
    final $$ExamsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exams,
      getReferencedColumn: (t) => t.sheetLayoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamsTableAnnotationComposer(
            $db: $db,
            $table: $db.exams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SheetLayoutsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $SheetLayoutsTable,
          SheetLayout,
          $$SheetLayoutsTableFilterComposer,
          $$SheetLayoutsTableOrderingComposer,
          $$SheetLayoutsTableAnnotationComposer,
          $$SheetLayoutsTableCreateCompanionBuilder,
          $$SheetLayoutsTableUpdateCompanionBuilder,
          (SheetLayout, $$SheetLayoutsTableReferences),
          SheetLayout,
          PrefetchHooks Function({bool examsRefs})
        > {
  $$SheetLayoutsTableTableManager(_$AppDb db, $SheetLayoutsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SheetLayoutsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SheetLayoutsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SheetLayoutsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String> layoutId = const Value.absent(),
                Value<int> layoutVersion = const Value.absent(),
                Value<String> specJson = const Value.absent(),
                Value<String> specHash = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SheetLayoutsCompanion(
                id: id,
                tenantId: tenantId,
                layoutId: layoutId,
                layoutVersion: layoutVersion,
                specJson: specJson,
                specHash: specHash,
                createdAt: createdAt,
                isActive: isActive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String tenantId,
                required String layoutId,
                required int layoutVersion,
                required String specJson,
                required String specHash,
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SheetLayoutsCompanion.insert(
                id: id,
                tenantId: tenantId,
                layoutId: layoutId,
                layoutVersion: layoutVersion,
                specJson: specJson,
                specHash: specHash,
                createdAt: createdAt,
                isActive: isActive,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SheetLayoutsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({examsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (examsRefs) db.exams],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (examsRefs)
                    await $_getPrefetchedData<
                      SheetLayout,
                      $SheetLayoutsTable,
                      Exam
                    >(
                      currentTable: table,
                      referencedTable: $$SheetLayoutsTableReferences
                          ._examsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SheetLayoutsTableReferences(
                            db,
                            table,
                            p0,
                          ).examsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.sheetLayoutId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SheetLayoutsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $SheetLayoutsTable,
      SheetLayout,
      $$SheetLayoutsTableFilterComposer,
      $$SheetLayoutsTableOrderingComposer,
      $$SheetLayoutsTableAnnotationComposer,
      $$SheetLayoutsTableCreateCompanionBuilder,
      $$SheetLayoutsTableUpdateCompanionBuilder,
      (SheetLayout, $$SheetLayoutsTableReferences),
      SheetLayout,
      PrefetchHooks Function({bool examsRefs})
    >;
typedef $$ExamsTableCreateCompanionBuilder =
    ExamsCompanion Function({
      Value<String> id,
      required String tenantId,
      required String instituteId,
      required String name,
      Value<DateTime?> heldAt,
      required String sheetLayoutId,
      required int totalQuestions,
      Value<ExamStatus> status,
      Value<String> gradingConfigJson,
      Value<DateTime> createdAt,
      Value<SyncState> syncState,
      Value<int> rowid,
    });
typedef $$ExamsTableUpdateCompanionBuilder =
    ExamsCompanion Function({
      Value<String> id,
      Value<String> tenantId,
      Value<String> instituteId,
      Value<String> name,
      Value<DateTime?> heldAt,
      Value<String> sheetLayoutId,
      Value<int> totalQuestions,
      Value<ExamStatus> status,
      Value<String> gradingConfigJson,
      Value<DateTime> createdAt,
      Value<SyncState> syncState,
      Value<int> rowid,
    });

final class $$ExamsTableReferences
    extends BaseReferences<_$AppDb, $ExamsTable, Exam> {
  $$ExamsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $InstitutesTable _instituteIdTable(_$AppDb db) =>
      db.institutes.createAlias('exams__institute_id__institutes__id');

  $$InstitutesTableProcessedTableManager get instituteId {
    final $_column = $_itemColumn<String>('institute_id')!;

    final manager = $$InstitutesTableTableManager(
      $_db,
      $_db.institutes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_instituteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $SheetLayoutsTable _sheetLayoutIdTable(_$AppDb db) =>
      db.sheetLayouts.createAlias('exams__sheet_layout_id__sheet_layouts__id');

  $$SheetLayoutsTableProcessedTableManager get sheetLayoutId {
    final $_column = $_itemColumn<String>('sheet_layout_id')!;

    final manager = $$SheetLayoutsTableTableManager(
      $_db,
      $_db.sheetLayouts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sheetLayoutIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$QuestionSetsTable, List<QuestionSet>>
  _questionSetsRefsTable(_$AppDb db) => MultiTypedResultKey.fromTable(
    db.questionSets,
    aliasName: 'exams__id__question_sets__exam_id',
  );

  $$QuestionSetsTableProcessedTableManager get questionSetsRefs {
    final manager = $$QuestionSetsTableTableManager(
      $_db,
      $_db.questionSets,
    ).filter((f) => f.examId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_questionSetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AnswerKeyVersionsTable, List<AnswerKeyVersion>>
  _answerKeyVersionsRefsTable(_$AppDb db) => MultiTypedResultKey.fromTable(
    db.answerKeyVersions,
    aliasName: 'exams__id__answer_key_versions__exam_id',
  );

  $$AnswerKeyVersionsTableProcessedTableManager get answerKeyVersionsRefs {
    final manager = $$AnswerKeyVersionsTableTableManager(
      $_db,
      $_db.answerKeyVersions,
    ).filter((f) => f.examId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _answerKeyVersionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ScansTable, List<Scan>> _scansRefsTable(
    _$AppDb db,
  ) => MultiTypedResultKey.fromTable(
    db.scans,
    aliasName: 'exams__id__scans__exam_id',
  );

  $$ScansTableProcessedTableManager get scansRefs {
    final manager = $$ScansTableTableManager(
      $_db,
      $_db.scans,
    ).filter((f) => f.examId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_scansRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ScoringRunsTable, List<ScoringRun>>
  _scoringRunsRefsTable(_$AppDb db) => MultiTypedResultKey.fromTable(
    db.scoringRuns,
    aliasName: 'exams__id__scoring_runs__exam_id',
  );

  $$ScoringRunsTableProcessedTableManager get scoringRunsRefs {
    final manager = $$ScoringRunsTableTableManager(
      $_db,
      $_db.scoringRuns,
    ).filter((f) => f.examId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_scoringRunsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ResultsTable, List<Result>> _resultsRefsTable(
    _$AppDb db,
  ) => MultiTypedResultKey.fromTable(
    db.results,
    aliasName: 'exams__id__results__exam_id',
  );

  $$ResultsTableProcessedTableManager get resultsRefs {
    final manager = $$ResultsTableTableManager(
      $_db,
      $_db.results,
    ).filter((f) => f.examId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_resultsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ReportJobsTable, List<ReportJob>>
  _reportJobsRefsTable(_$AppDb db) => MultiTypedResultKey.fromTable(
    db.reportJobs,
    aliasName: 'exams__id__report_jobs__exam_id',
  );

  $$ReportJobsTableProcessedTableManager get reportJobsRefs {
    final manager = $$ReportJobsTableTableManager(
      $_db,
      $_db.reportJobs,
    ).filter((f) => f.examId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_reportJobsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ExamsTableFilterComposer extends Composer<_$AppDb, $ExamsTable> {
  $$ExamsTableFilterComposer({
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

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get heldAt =>
      $composableBuilder(
        column: $table.heldAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get totalQuestions => $composableBuilder(
    column: $table.totalQuestions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ExamStatus, ExamStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get gradingConfigJson => $composableBuilder(
    column: $table.gradingConfigJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<SyncState, SyncState, String> get syncState =>
      $composableBuilder(
        column: $table.syncState,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$InstitutesTableFilterComposer get instituteId {
    final $$InstitutesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.instituteId,
      referencedTable: $db.institutes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InstitutesTableFilterComposer(
            $db: $db,
            $table: $db.institutes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SheetLayoutsTableFilterComposer get sheetLayoutId {
    final $$SheetLayoutsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sheetLayoutId,
      referencedTable: $db.sheetLayouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SheetLayoutsTableFilterComposer(
            $db: $db,
            $table: $db.sheetLayouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> questionSetsRefs(
    Expression<bool> Function($$QuestionSetsTableFilterComposer f) f,
  ) {
    final $$QuestionSetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.questionSets,
      getReferencedColumn: (t) => t.examId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionSetsTableFilterComposer(
            $db: $db,
            $table: $db.questionSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> answerKeyVersionsRefs(
    Expression<bool> Function($$AnswerKeyVersionsTableFilterComposer f) f,
  ) {
    final $$AnswerKeyVersionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.answerKeyVersions,
      getReferencedColumn: (t) => t.examId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnswerKeyVersionsTableFilterComposer(
            $db: $db,
            $table: $db.answerKeyVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> scansRefs(
    Expression<bool> Function($$ScansTableFilterComposer f) f,
  ) {
    final $$ScansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scans,
      getReferencedColumn: (t) => t.examId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScansTableFilterComposer(
            $db: $db,
            $table: $db.scans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> scoringRunsRefs(
    Expression<bool> Function($$ScoringRunsTableFilterComposer f) f,
  ) {
    final $$ScoringRunsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scoringRuns,
      getReferencedColumn: (t) => t.examId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoringRunsTableFilterComposer(
            $db: $db,
            $table: $db.scoringRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> resultsRefs(
    Expression<bool> Function($$ResultsTableFilterComposer f) f,
  ) {
    final $$ResultsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.results,
      getReferencedColumn: (t) => t.examId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ResultsTableFilterComposer(
            $db: $db,
            $table: $db.results,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> reportJobsRefs(
    Expression<bool> Function($$ReportJobsTableFilterComposer f) f,
  ) {
    final $$ReportJobsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reportJobs,
      getReferencedColumn: (t) => t.examId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReportJobsTableFilterComposer(
            $db: $db,
            $table: $db.reportJobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExamsTableOrderingComposer extends Composer<_$AppDb, $ExamsTable> {
  $$ExamsTableOrderingComposer({
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

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get heldAt => $composableBuilder(
    column: $table.heldAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalQuestions => $composableBuilder(
    column: $table.totalQuestions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gradingConfigJson => $composableBuilder(
    column: $table.gradingConfigJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  $$InstitutesTableOrderingComposer get instituteId {
    final $$InstitutesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.instituteId,
      referencedTable: $db.institutes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InstitutesTableOrderingComposer(
            $db: $db,
            $table: $db.institutes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SheetLayoutsTableOrderingComposer get sheetLayoutId {
    final $$SheetLayoutsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sheetLayoutId,
      referencedTable: $db.sheetLayouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SheetLayoutsTableOrderingComposer(
            $db: $db,
            $table: $db.sheetLayouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExamsTableAnnotationComposer extends Composer<_$AppDb, $ExamsTable> {
  $$ExamsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, String> get heldAt =>
      $composableBuilder(column: $table.heldAt, builder: (column) => column);

  GeneratedColumn<int> get totalQuestions => $composableBuilder(
    column: $table.totalQuestions,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ExamStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get gradingConfigJson => $composableBuilder(
    column: $table.gradingConfigJson,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncState, String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  $$InstitutesTableAnnotationComposer get instituteId {
    final $$InstitutesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.instituteId,
      referencedTable: $db.institutes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InstitutesTableAnnotationComposer(
            $db: $db,
            $table: $db.institutes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SheetLayoutsTableAnnotationComposer get sheetLayoutId {
    final $$SheetLayoutsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sheetLayoutId,
      referencedTable: $db.sheetLayouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SheetLayoutsTableAnnotationComposer(
            $db: $db,
            $table: $db.sheetLayouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> questionSetsRefs<T extends Object>(
    Expression<T> Function($$QuestionSetsTableAnnotationComposer a) f,
  ) {
    final $$QuestionSetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.questionSets,
      getReferencedColumn: (t) => t.examId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionSetsTableAnnotationComposer(
            $db: $db,
            $table: $db.questionSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> answerKeyVersionsRefs<T extends Object>(
    Expression<T> Function($$AnswerKeyVersionsTableAnnotationComposer a) f,
  ) {
    final $$AnswerKeyVersionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.answerKeyVersions,
          getReferencedColumn: (t) => t.examId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AnswerKeyVersionsTableAnnotationComposer(
                $db: $db,
                $table: $db.answerKeyVersions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> scansRefs<T extends Object>(
    Expression<T> Function($$ScansTableAnnotationComposer a) f,
  ) {
    final $$ScansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scans,
      getReferencedColumn: (t) => t.examId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScansTableAnnotationComposer(
            $db: $db,
            $table: $db.scans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> scoringRunsRefs<T extends Object>(
    Expression<T> Function($$ScoringRunsTableAnnotationComposer a) f,
  ) {
    final $$ScoringRunsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scoringRuns,
      getReferencedColumn: (t) => t.examId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoringRunsTableAnnotationComposer(
            $db: $db,
            $table: $db.scoringRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> resultsRefs<T extends Object>(
    Expression<T> Function($$ResultsTableAnnotationComposer a) f,
  ) {
    final $$ResultsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.results,
      getReferencedColumn: (t) => t.examId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ResultsTableAnnotationComposer(
            $db: $db,
            $table: $db.results,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> reportJobsRefs<T extends Object>(
    Expression<T> Function($$ReportJobsTableAnnotationComposer a) f,
  ) {
    final $$ReportJobsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reportJobs,
      getReferencedColumn: (t) => t.examId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReportJobsTableAnnotationComposer(
            $db: $db,
            $table: $db.reportJobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExamsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $ExamsTable,
          Exam,
          $$ExamsTableFilterComposer,
          $$ExamsTableOrderingComposer,
          $$ExamsTableAnnotationComposer,
          $$ExamsTableCreateCompanionBuilder,
          $$ExamsTableUpdateCompanionBuilder,
          (Exam, $$ExamsTableReferences),
          Exam,
          PrefetchHooks Function({
            bool instituteId,
            bool sheetLayoutId,
            bool questionSetsRefs,
            bool answerKeyVersionsRefs,
            bool scansRefs,
            bool scoringRunsRefs,
            bool resultsRefs,
            bool reportJobsRefs,
          })
        > {
  $$ExamsTableTableManager(_$AppDb db, $ExamsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExamsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExamsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExamsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String> instituteId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime?> heldAt = const Value.absent(),
                Value<String> sheetLayoutId = const Value.absent(),
                Value<int> totalQuestions = const Value.absent(),
                Value<ExamStatus> status = const Value.absent(),
                Value<String> gradingConfigJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExamsCompanion(
                id: id,
                tenantId: tenantId,
                instituteId: instituteId,
                name: name,
                heldAt: heldAt,
                sheetLayoutId: sheetLayoutId,
                totalQuestions: totalQuestions,
                status: status,
                gradingConfigJson: gradingConfigJson,
                createdAt: createdAt,
                syncState: syncState,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String tenantId,
                required String instituteId,
                required String name,
                Value<DateTime?> heldAt = const Value.absent(),
                required String sheetLayoutId,
                required int totalQuestions,
                Value<ExamStatus> status = const Value.absent(),
                Value<String> gradingConfigJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExamsCompanion.insert(
                id: id,
                tenantId: tenantId,
                instituteId: instituteId,
                name: name,
                heldAt: heldAt,
                sheetLayoutId: sheetLayoutId,
                totalQuestions: totalQuestions,
                status: status,
                gradingConfigJson: gradingConfigJson,
                createdAt: createdAt,
                syncState: syncState,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$ExamsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                instituteId = false,
                sheetLayoutId = false,
                questionSetsRefs = false,
                answerKeyVersionsRefs = false,
                scansRefs = false,
                scoringRunsRefs = false,
                resultsRefs = false,
                reportJobsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (questionSetsRefs) db.questionSets,
                    if (answerKeyVersionsRefs) db.answerKeyVersions,
                    if (scansRefs) db.scans,
                    if (scoringRunsRefs) db.scoringRuns,
                    if (resultsRefs) db.results,
                    if (reportJobsRefs) db.reportJobs,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (instituteId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.instituteId,
                                    referencedTable: $$ExamsTableReferences
                                        ._instituteIdTable(db),
                                    referencedColumn: $$ExamsTableReferences
                                        ._instituteIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (sheetLayoutId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.sheetLayoutId,
                                    referencedTable: $$ExamsTableReferences
                                        ._sheetLayoutIdTable(db),
                                    referencedColumn: $$ExamsTableReferences
                                        ._sheetLayoutIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (questionSetsRefs)
                        await $_getPrefetchedData<
                          Exam,
                          $ExamsTable,
                          QuestionSet
                        >(
                          currentTable: table,
                          referencedTable: $$ExamsTableReferences
                              ._questionSetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExamsTableReferences(
                                db,
                                table,
                                p0,
                              ).questionSetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.examId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (answerKeyVersionsRefs)
                        await $_getPrefetchedData<
                          Exam,
                          $ExamsTable,
                          AnswerKeyVersion
                        >(
                          currentTable: table,
                          referencedTable: $$ExamsTableReferences
                              ._answerKeyVersionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExamsTableReferences(
                                db,
                                table,
                                p0,
                              ).answerKeyVersionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.examId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (scansRefs)
                        await $_getPrefetchedData<Exam, $ExamsTable, Scan>(
                          currentTable: table,
                          referencedTable: $$ExamsTableReferences
                              ._scansRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExamsTableReferences(db, table, p0).scansRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.examId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (scoringRunsRefs)
                        await $_getPrefetchedData<
                          Exam,
                          $ExamsTable,
                          ScoringRun
                        >(
                          currentTable: table,
                          referencedTable: $$ExamsTableReferences
                              ._scoringRunsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExamsTableReferences(
                                db,
                                table,
                                p0,
                              ).scoringRunsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.examId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (resultsRefs)
                        await $_getPrefetchedData<Exam, $ExamsTable, Result>(
                          currentTable: table,
                          referencedTable: $$ExamsTableReferences
                              ._resultsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExamsTableReferences(db, table, p0).resultsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.examId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (reportJobsRefs)
                        await $_getPrefetchedData<Exam, $ExamsTable, ReportJob>(
                          currentTable: table,
                          referencedTable: $$ExamsTableReferences
                              ._reportJobsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExamsTableReferences(
                                db,
                                table,
                                p0,
                              ).reportJobsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.examId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ExamsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $ExamsTable,
      Exam,
      $$ExamsTableFilterComposer,
      $$ExamsTableOrderingComposer,
      $$ExamsTableAnnotationComposer,
      $$ExamsTableCreateCompanionBuilder,
      $$ExamsTableUpdateCompanionBuilder,
      (Exam, $$ExamsTableReferences),
      Exam,
      PrefetchHooks Function({
        bool instituteId,
        bool sheetLayoutId,
        bool questionSetsRefs,
        bool answerKeyVersionsRefs,
        bool scansRefs,
        bool scoringRunsRefs,
        bool resultsRefs,
        bool reportJobsRefs,
      })
    >;
typedef $$QuestionSetsTableCreateCompanionBuilder =
    QuestionSetsCompanion Function({
      required String tenantId,
      required String examId,
      required String setCode,
      required String questionMapJson,
      Value<int> rowid,
    });
typedef $$QuestionSetsTableUpdateCompanionBuilder =
    QuestionSetsCompanion Function({
      Value<String> tenantId,
      Value<String> examId,
      Value<String> setCode,
      Value<String> questionMapJson,
      Value<int> rowid,
    });

final class $$QuestionSetsTableReferences
    extends BaseReferences<_$AppDb, $QuestionSetsTable, QuestionSet> {
  $$QuestionSetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ExamsTable _examIdTable(_$AppDb db) =>
      db.exams.createAlias('question_sets__exam_id__exams__id');

  $$ExamsTableProcessedTableManager get examId {
    final $_column = $_itemColumn<String>('exam_id')!;

    final manager = $$ExamsTableTableManager(
      $_db,
      $_db.exams,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_examIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$QuestionSetsTableFilterComposer
    extends Composer<_$AppDb, $QuestionSetsTable> {
  $$QuestionSetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get setCode => $composableBuilder(
    column: $table.setCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionMapJson => $composableBuilder(
    column: $table.questionMapJson,
    builder: (column) => ColumnFilters(column),
  );

  $$ExamsTableFilterComposer get examId {
    final $$ExamsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.examId,
      referencedTable: $db.exams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamsTableFilterComposer(
            $db: $db,
            $table: $db.exams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuestionSetsTableOrderingComposer
    extends Composer<_$AppDb, $QuestionSetsTable> {
  $$QuestionSetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get setCode => $composableBuilder(
    column: $table.setCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionMapJson => $composableBuilder(
    column: $table.questionMapJson,
    builder: (column) => ColumnOrderings(column),
  );

  $$ExamsTableOrderingComposer get examId {
    final $$ExamsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.examId,
      referencedTable: $db.exams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamsTableOrderingComposer(
            $db: $db,
            $table: $db.exams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuestionSetsTableAnnotationComposer
    extends Composer<_$AppDb, $QuestionSetsTable> {
  $$QuestionSetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get setCode =>
      $composableBuilder(column: $table.setCode, builder: (column) => column);

  GeneratedColumn<String> get questionMapJson => $composableBuilder(
    column: $table.questionMapJson,
    builder: (column) => column,
  );

  $$ExamsTableAnnotationComposer get examId {
    final $$ExamsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.examId,
      referencedTable: $db.exams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamsTableAnnotationComposer(
            $db: $db,
            $table: $db.exams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuestionSetsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $QuestionSetsTable,
          QuestionSet,
          $$QuestionSetsTableFilterComposer,
          $$QuestionSetsTableOrderingComposer,
          $$QuestionSetsTableAnnotationComposer,
          $$QuestionSetsTableCreateCompanionBuilder,
          $$QuestionSetsTableUpdateCompanionBuilder,
          (QuestionSet, $$QuestionSetsTableReferences),
          QuestionSet,
          PrefetchHooks Function({bool examId})
        > {
  $$QuestionSetsTableTableManager(_$AppDb db, $QuestionSetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuestionSetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuestionSetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuestionSetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> tenantId = const Value.absent(),
                Value<String> examId = const Value.absent(),
                Value<String> setCode = const Value.absent(),
                Value<String> questionMapJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuestionSetsCompanion(
                tenantId: tenantId,
                examId: examId,
                setCode: setCode,
                questionMapJson: questionMapJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tenantId,
                required String examId,
                required String setCode,
                required String questionMapJson,
                Value<int> rowid = const Value.absent(),
              }) => QuestionSetsCompanion.insert(
                tenantId: tenantId,
                examId: examId,
                setCode: setCode,
                questionMapJson: questionMapJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$QuestionSetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({examId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (examId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.examId,
                                referencedTable: $$QuestionSetsTableReferences
                                    ._examIdTable(db),
                                referencedColumn: $$QuestionSetsTableReferences
                                    ._examIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$QuestionSetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $QuestionSetsTable,
      QuestionSet,
      $$QuestionSetsTableFilterComposer,
      $$QuestionSetsTableOrderingComposer,
      $$QuestionSetsTableAnnotationComposer,
      $$QuestionSetsTableCreateCompanionBuilder,
      $$QuestionSetsTableUpdateCompanionBuilder,
      (QuestionSet, $$QuestionSetsTableReferences),
      QuestionSet,
      PrefetchHooks Function({bool examId})
    >;
typedef $$ScoringRulesTableCreateCompanionBuilder =
    ScoringRulesCompanion Function({
      Value<String> id,
      required String tenantId,
      required String name,
      required ScoringStrategyKind strategy,
      required String paramsJson,
      Value<int> rowid,
    });
typedef $$ScoringRulesTableUpdateCompanionBuilder =
    ScoringRulesCompanion Function({
      Value<String> id,
      Value<String> tenantId,
      Value<String> name,
      Value<ScoringStrategyKind> strategy,
      Value<String> paramsJson,
      Value<int> rowid,
    });

final class $$ScoringRulesTableReferences
    extends BaseReferences<_$AppDb, $ScoringRulesTable, ScoringRule> {
  $$ScoringRulesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AnswerKeyEntriesTable, List<AnswerKeyEntry>>
  _answerKeyEntriesRefsTable(_$AppDb db) => MultiTypedResultKey.fromTable(
    db.answerKeyEntries,
    aliasName: 'scoring_rules__id__answer_key_entries__scoring_rule_id',
  );

  $$AnswerKeyEntriesTableProcessedTableManager get answerKeyEntriesRefs {
    final manager = $$AnswerKeyEntriesTableTableManager(
      $_db,
      $_db.answerKeyEntries,
    ).filter((f) => f.scoringRuleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _answerKeyEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ScoringRulesTableFilterComposer
    extends Composer<_$AppDb, $ScoringRulesTable> {
  $$ScoringRulesTableFilterComposer({
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

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    ScoringStrategyKind,
    ScoringStrategyKind,
    String
  >
  get strategy => $composableBuilder(
    column: $table.strategy,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get paramsJson => $composableBuilder(
    column: $table.paramsJson,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> answerKeyEntriesRefs(
    Expression<bool> Function($$AnswerKeyEntriesTableFilterComposer f) f,
  ) {
    final $$AnswerKeyEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.answerKeyEntries,
      getReferencedColumn: (t) => t.scoringRuleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnswerKeyEntriesTableFilterComposer(
            $db: $db,
            $table: $db.answerKeyEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ScoringRulesTableOrderingComposer
    extends Composer<_$AppDb, $ScoringRulesTable> {
  $$ScoringRulesTableOrderingComposer({
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

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get strategy => $composableBuilder(
    column: $table.strategy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paramsJson => $composableBuilder(
    column: $table.paramsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ScoringRulesTableAnnotationComposer
    extends Composer<_$AppDb, $ScoringRulesTable> {
  $$ScoringRulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ScoringStrategyKind, String> get strategy =>
      $composableBuilder(column: $table.strategy, builder: (column) => column);

  GeneratedColumn<String> get paramsJson => $composableBuilder(
    column: $table.paramsJson,
    builder: (column) => column,
  );

  Expression<T> answerKeyEntriesRefs<T extends Object>(
    Expression<T> Function($$AnswerKeyEntriesTableAnnotationComposer a) f,
  ) {
    final $$AnswerKeyEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.answerKeyEntries,
      getReferencedColumn: (t) => t.scoringRuleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnswerKeyEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.answerKeyEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ScoringRulesTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $ScoringRulesTable,
          ScoringRule,
          $$ScoringRulesTableFilterComposer,
          $$ScoringRulesTableOrderingComposer,
          $$ScoringRulesTableAnnotationComposer,
          $$ScoringRulesTableCreateCompanionBuilder,
          $$ScoringRulesTableUpdateCompanionBuilder,
          (ScoringRule, $$ScoringRulesTableReferences),
          ScoringRule,
          PrefetchHooks Function({bool answerKeyEntriesRefs})
        > {
  $$ScoringRulesTableTableManager(_$AppDb db, $ScoringRulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScoringRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScoringRulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScoringRulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<ScoringStrategyKind> strategy = const Value.absent(),
                Value<String> paramsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScoringRulesCompanion(
                id: id,
                tenantId: tenantId,
                name: name,
                strategy: strategy,
                paramsJson: paramsJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String tenantId,
                required String name,
                required ScoringStrategyKind strategy,
                required String paramsJson,
                Value<int> rowid = const Value.absent(),
              }) => ScoringRulesCompanion.insert(
                id: id,
                tenantId: tenantId,
                name: name,
                strategy: strategy,
                paramsJson: paramsJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ScoringRulesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({answerKeyEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (answerKeyEntriesRefs) db.answerKeyEntries,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (answerKeyEntriesRefs)
                    await $_getPrefetchedData<
                      ScoringRule,
                      $ScoringRulesTable,
                      AnswerKeyEntry
                    >(
                      currentTable: table,
                      referencedTable: $$ScoringRulesTableReferences
                          ._answerKeyEntriesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ScoringRulesTableReferences(
                            db,
                            table,
                            p0,
                          ).answerKeyEntriesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.scoringRuleId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ScoringRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $ScoringRulesTable,
      ScoringRule,
      $$ScoringRulesTableFilterComposer,
      $$ScoringRulesTableOrderingComposer,
      $$ScoringRulesTableAnnotationComposer,
      $$ScoringRulesTableCreateCompanionBuilder,
      $$ScoringRulesTableUpdateCompanionBuilder,
      (ScoringRule, $$ScoringRulesTableReferences),
      ScoringRule,
      PrefetchHooks Function({bool answerKeyEntriesRefs})
    >;
typedef $$AnswerKeyVersionsTableCreateCompanionBuilder =
    AnswerKeyVersionsCompanion Function({
      Value<String> id,
      required String tenantId,
      required String examId,
      required int version,
      Value<KeyVersionStatus> status,
      Value<String?> supersedesId,
      required String createdBy,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$AnswerKeyVersionsTableUpdateCompanionBuilder =
    AnswerKeyVersionsCompanion Function({
      Value<String> id,
      Value<String> tenantId,
      Value<String> examId,
      Value<int> version,
      Value<KeyVersionStatus> status,
      Value<String?> supersedesId,
      Value<String> createdBy,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$AnswerKeyVersionsTableReferences
    extends BaseReferences<_$AppDb, $AnswerKeyVersionsTable, AnswerKeyVersion> {
  $$AnswerKeyVersionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ExamsTable _examIdTable(_$AppDb db) =>
      db.exams.createAlias('answer_key_versions__exam_id__exams__id');

  $$ExamsTableProcessedTableManager get examId {
    final $_column = $_itemColumn<String>('exam_id')!;

    final manager = $$ExamsTableTableManager(
      $_db,
      $_db.exams,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_examIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AnswerKeyVersionsTable _supersedesIdTable(_$AppDb db) =>
      db.answerKeyVersions.createAlias(
        'answer_key_versions__supersedes_id__answer_key_versions__id',
      );

  $$AnswerKeyVersionsTableProcessedTableManager? get supersedesId {
    final $_column = $_itemColumn<String>('supersedes_id');
    if ($_column == null) return null;
    final manager = $$AnswerKeyVersionsTableTableManager(
      $_db,
      $_db.answerKeyVersions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_supersedesIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$AnswerKeyEntriesTable, List<AnswerKeyEntry>>
  _answerKeyEntriesRefsTable(_$AppDb db) => MultiTypedResultKey.fromTable(
    db.answerKeyEntries,
    aliasName: 'answer_key_versions__id__answer_key_entries__key_version_id',
  );

  $$AnswerKeyEntriesTableProcessedTableManager get answerKeyEntriesRefs {
    final manager = $$AnswerKeyEntriesTableTableManager(
      $_db,
      $_db.answerKeyEntries,
    ).filter((f) => f.keyVersionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _answerKeyEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ScoringRunsTable, List<ScoringRun>>
  _scoringRunsRefsTable(_$AppDb db) => MultiTypedResultKey.fromTable(
    db.scoringRuns,
    aliasName: 'answer_key_versions__id__scoring_runs__key_version_id',
  );

  $$ScoringRunsTableProcessedTableManager get scoringRunsRefs {
    final manager = $$ScoringRunsTableTableManager(
      $_db,
      $_db.scoringRuns,
    ).filter((f) => f.keyVersionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_scoringRunsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ResultsTable, List<Result>> _resultsRefsTable(
    _$AppDb db,
  ) => MultiTypedResultKey.fromTable(
    db.results,
    aliasName: 'answer_key_versions__id__results__key_version_id',
  );

  $$ResultsTableProcessedTableManager get resultsRefs {
    final manager = $$ResultsTableTableManager(
      $_db,
      $_db.results,
    ).filter((f) => f.keyVersionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_resultsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AnswerKeyVersionsTableFilterComposer
    extends Composer<_$AppDb, $AnswerKeyVersionsTable> {
  $$AnswerKeyVersionsTableFilterComposer({
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

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<KeyVersionStatus, KeyVersionStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$ExamsTableFilterComposer get examId {
    final $$ExamsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.examId,
      referencedTable: $db.exams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamsTableFilterComposer(
            $db: $db,
            $table: $db.exams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AnswerKeyVersionsTableFilterComposer get supersedesId {
    final $$AnswerKeyVersionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.supersedesId,
      referencedTable: $db.answerKeyVersions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnswerKeyVersionsTableFilterComposer(
            $db: $db,
            $table: $db.answerKeyVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> answerKeyEntriesRefs(
    Expression<bool> Function($$AnswerKeyEntriesTableFilterComposer f) f,
  ) {
    final $$AnswerKeyEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.answerKeyEntries,
      getReferencedColumn: (t) => t.keyVersionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnswerKeyEntriesTableFilterComposer(
            $db: $db,
            $table: $db.answerKeyEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> scoringRunsRefs(
    Expression<bool> Function($$ScoringRunsTableFilterComposer f) f,
  ) {
    final $$ScoringRunsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scoringRuns,
      getReferencedColumn: (t) => t.keyVersionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoringRunsTableFilterComposer(
            $db: $db,
            $table: $db.scoringRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> resultsRefs(
    Expression<bool> Function($$ResultsTableFilterComposer f) f,
  ) {
    final $$ResultsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.results,
      getReferencedColumn: (t) => t.keyVersionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ResultsTableFilterComposer(
            $db: $db,
            $table: $db.results,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AnswerKeyVersionsTableOrderingComposer
    extends Composer<_$AppDb, $AnswerKeyVersionsTable> {
  $$AnswerKeyVersionsTableOrderingComposer({
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

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ExamsTableOrderingComposer get examId {
    final $$ExamsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.examId,
      referencedTable: $db.exams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamsTableOrderingComposer(
            $db: $db,
            $table: $db.exams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AnswerKeyVersionsTableOrderingComposer get supersedesId {
    final $$AnswerKeyVersionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.supersedesId,
      referencedTable: $db.answerKeyVersions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnswerKeyVersionsTableOrderingComposer(
            $db: $db,
            $table: $db.answerKeyVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnswerKeyVersionsTableAnnotationComposer
    extends Composer<_$AppDb, $AnswerKeyVersionsTable> {
  $$AnswerKeyVersionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumnWithTypeConverter<KeyVersionStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ExamsTableAnnotationComposer get examId {
    final $$ExamsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.examId,
      referencedTable: $db.exams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamsTableAnnotationComposer(
            $db: $db,
            $table: $db.exams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AnswerKeyVersionsTableAnnotationComposer get supersedesId {
    final $$AnswerKeyVersionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.supersedesId,
          referencedTable: $db.answerKeyVersions,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AnswerKeyVersionsTableAnnotationComposer(
                $db: $db,
                $table: $db.answerKeyVersions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<T> answerKeyEntriesRefs<T extends Object>(
    Expression<T> Function($$AnswerKeyEntriesTableAnnotationComposer a) f,
  ) {
    final $$AnswerKeyEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.answerKeyEntries,
      getReferencedColumn: (t) => t.keyVersionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnswerKeyEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.answerKeyEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> scoringRunsRefs<T extends Object>(
    Expression<T> Function($$ScoringRunsTableAnnotationComposer a) f,
  ) {
    final $$ScoringRunsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scoringRuns,
      getReferencedColumn: (t) => t.keyVersionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoringRunsTableAnnotationComposer(
            $db: $db,
            $table: $db.scoringRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> resultsRefs<T extends Object>(
    Expression<T> Function($$ResultsTableAnnotationComposer a) f,
  ) {
    final $$ResultsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.results,
      getReferencedColumn: (t) => t.keyVersionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ResultsTableAnnotationComposer(
            $db: $db,
            $table: $db.results,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AnswerKeyVersionsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $AnswerKeyVersionsTable,
          AnswerKeyVersion,
          $$AnswerKeyVersionsTableFilterComposer,
          $$AnswerKeyVersionsTableOrderingComposer,
          $$AnswerKeyVersionsTableAnnotationComposer,
          $$AnswerKeyVersionsTableCreateCompanionBuilder,
          $$AnswerKeyVersionsTableUpdateCompanionBuilder,
          (AnswerKeyVersion, $$AnswerKeyVersionsTableReferences),
          AnswerKeyVersion,
          PrefetchHooks Function({
            bool examId,
            bool supersedesId,
            bool answerKeyEntriesRefs,
            bool scoringRunsRefs,
            bool resultsRefs,
          })
        > {
  $$AnswerKeyVersionsTableTableManager(
    _$AppDb db,
    $AnswerKeyVersionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnswerKeyVersionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnswerKeyVersionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnswerKeyVersionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String> examId = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<KeyVersionStatus> status = const Value.absent(),
                Value<String?> supersedesId = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AnswerKeyVersionsCompanion(
                id: id,
                tenantId: tenantId,
                examId: examId,
                version: version,
                status: status,
                supersedesId: supersedesId,
                createdBy: createdBy,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String tenantId,
                required String examId,
                required int version,
                Value<KeyVersionStatus> status = const Value.absent(),
                Value<String?> supersedesId = const Value.absent(),
                required String createdBy,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AnswerKeyVersionsCompanion.insert(
                id: id,
                tenantId: tenantId,
                examId: examId,
                version: version,
                status: status,
                supersedesId: supersedesId,
                createdBy: createdBy,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AnswerKeyVersionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                examId = false,
                supersedesId = false,
                answerKeyEntriesRefs = false,
                scoringRunsRefs = false,
                resultsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (answerKeyEntriesRefs) db.answerKeyEntries,
                    if (scoringRunsRefs) db.scoringRuns,
                    if (resultsRefs) db.results,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (examId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.examId,
                                    referencedTable:
                                        $$AnswerKeyVersionsTableReferences
                                            ._examIdTable(db),
                                    referencedColumn:
                                        $$AnswerKeyVersionsTableReferences
                                            ._examIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (supersedesId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.supersedesId,
                                    referencedTable:
                                        $$AnswerKeyVersionsTableReferences
                                            ._supersedesIdTable(db),
                                    referencedColumn:
                                        $$AnswerKeyVersionsTableReferences
                                            ._supersedesIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (answerKeyEntriesRefs)
                        await $_getPrefetchedData<
                          AnswerKeyVersion,
                          $AnswerKeyVersionsTable,
                          AnswerKeyEntry
                        >(
                          currentTable: table,
                          referencedTable: $$AnswerKeyVersionsTableReferences
                              ._answerKeyEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AnswerKeyVersionsTableReferences(
                                db,
                                table,
                                p0,
                              ).answerKeyEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.keyVersionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (scoringRunsRefs)
                        await $_getPrefetchedData<
                          AnswerKeyVersion,
                          $AnswerKeyVersionsTable,
                          ScoringRun
                        >(
                          currentTable: table,
                          referencedTable: $$AnswerKeyVersionsTableReferences
                              ._scoringRunsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AnswerKeyVersionsTableReferences(
                                db,
                                table,
                                p0,
                              ).scoringRunsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.keyVersionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (resultsRefs)
                        await $_getPrefetchedData<
                          AnswerKeyVersion,
                          $AnswerKeyVersionsTable,
                          Result
                        >(
                          currentTable: table,
                          referencedTable: $$AnswerKeyVersionsTableReferences
                              ._resultsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AnswerKeyVersionsTableReferences(
                                db,
                                table,
                                p0,
                              ).resultsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.keyVersionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AnswerKeyVersionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $AnswerKeyVersionsTable,
      AnswerKeyVersion,
      $$AnswerKeyVersionsTableFilterComposer,
      $$AnswerKeyVersionsTableOrderingComposer,
      $$AnswerKeyVersionsTableAnnotationComposer,
      $$AnswerKeyVersionsTableCreateCompanionBuilder,
      $$AnswerKeyVersionsTableUpdateCompanionBuilder,
      (AnswerKeyVersion, $$AnswerKeyVersionsTableReferences),
      AnswerKeyVersion,
      PrefetchHooks Function({
        bool examId,
        bool supersedesId,
        bool answerKeyEntriesRefs,
        bool scoringRunsRefs,
        bool resultsRefs,
      })
    >;
typedef $$AnswerKeyEntriesTableCreateCompanionBuilder =
    AnswerKeyEntriesCompanion Function({
      required String tenantId,
      required String keyVersionId,
      required String setCode,
      required String questionId,
      Value<String> correctOptionsJson,
      Value<int?> correctInteger,
      Value<KeyEntryState> state,
      Value<String?> scoringRuleId,
      Value<int> rowid,
    });
typedef $$AnswerKeyEntriesTableUpdateCompanionBuilder =
    AnswerKeyEntriesCompanion Function({
      Value<String> tenantId,
      Value<String> keyVersionId,
      Value<String> setCode,
      Value<String> questionId,
      Value<String> correctOptionsJson,
      Value<int?> correctInteger,
      Value<KeyEntryState> state,
      Value<String?> scoringRuleId,
      Value<int> rowid,
    });

final class $$AnswerKeyEntriesTableReferences
    extends BaseReferences<_$AppDb, $AnswerKeyEntriesTable, AnswerKeyEntry> {
  $$AnswerKeyEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AnswerKeyVersionsTable _keyVersionIdTable(_$AppDb db) =>
      db.answerKeyVersions.createAlias(
        'answer_key_entries__key_version_id__answer_key_versions__id',
      );

  $$AnswerKeyVersionsTableProcessedTableManager get keyVersionId {
    final $_column = $_itemColumn<String>('key_version_id')!;

    final manager = $$AnswerKeyVersionsTableTableManager(
      $_db,
      $_db.answerKeyVersions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_keyVersionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ScoringRulesTable _scoringRuleIdTable(_$AppDb db) => db.scoringRules
      .createAlias('answer_key_entries__scoring_rule_id__scoring_rules__id');

  $$ScoringRulesTableProcessedTableManager? get scoringRuleId {
    final $_column = $_itemColumn<String>('scoring_rule_id');
    if ($_column == null) return null;
    final manager = $$ScoringRulesTableTableManager(
      $_db,
      $_db.scoringRules,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_scoringRuleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AnswerKeyEntriesTableFilterComposer
    extends Composer<_$AppDb, $AnswerKeyEntriesTable> {
  $$AnswerKeyEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get setCode => $composableBuilder(
    column: $table.setCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get correctOptionsJson => $composableBuilder(
    column: $table.correctOptionsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correctInteger => $composableBuilder(
    column: $table.correctInteger,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<KeyEntryState, KeyEntryState, String>
  get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$AnswerKeyVersionsTableFilterComposer get keyVersionId {
    final $$AnswerKeyVersionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.keyVersionId,
      referencedTable: $db.answerKeyVersions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnswerKeyVersionsTableFilterComposer(
            $db: $db,
            $table: $db.answerKeyVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ScoringRulesTableFilterComposer get scoringRuleId {
    final $$ScoringRulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scoringRuleId,
      referencedTable: $db.scoringRules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoringRulesTableFilterComposer(
            $db: $db,
            $table: $db.scoringRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnswerKeyEntriesTableOrderingComposer
    extends Composer<_$AppDb, $AnswerKeyEntriesTable> {
  $$AnswerKeyEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get setCode => $composableBuilder(
    column: $table.setCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get correctOptionsJson => $composableBuilder(
    column: $table.correctOptionsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correctInteger => $composableBuilder(
    column: $table.correctInteger,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  $$AnswerKeyVersionsTableOrderingComposer get keyVersionId {
    final $$AnswerKeyVersionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.keyVersionId,
      referencedTable: $db.answerKeyVersions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnswerKeyVersionsTableOrderingComposer(
            $db: $db,
            $table: $db.answerKeyVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ScoringRulesTableOrderingComposer get scoringRuleId {
    final $$ScoringRulesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scoringRuleId,
      referencedTable: $db.scoringRules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoringRulesTableOrderingComposer(
            $db: $db,
            $table: $db.scoringRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnswerKeyEntriesTableAnnotationComposer
    extends Composer<_$AppDb, $AnswerKeyEntriesTable> {
  $$AnswerKeyEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get setCode =>
      $composableBuilder(column: $table.setCode, builder: (column) => column);

  GeneratedColumn<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get correctOptionsJson => $composableBuilder(
    column: $table.correctOptionsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get correctInteger => $composableBuilder(
    column: $table.correctInteger,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<KeyEntryState, String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  $$AnswerKeyVersionsTableAnnotationComposer get keyVersionId {
    final $$AnswerKeyVersionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.keyVersionId,
          referencedTable: $db.answerKeyVersions,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AnswerKeyVersionsTableAnnotationComposer(
                $db: $db,
                $table: $db.answerKeyVersions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$ScoringRulesTableAnnotationComposer get scoringRuleId {
    final $$ScoringRulesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scoringRuleId,
      referencedTable: $db.scoringRules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoringRulesTableAnnotationComposer(
            $db: $db,
            $table: $db.scoringRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnswerKeyEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $AnswerKeyEntriesTable,
          AnswerKeyEntry,
          $$AnswerKeyEntriesTableFilterComposer,
          $$AnswerKeyEntriesTableOrderingComposer,
          $$AnswerKeyEntriesTableAnnotationComposer,
          $$AnswerKeyEntriesTableCreateCompanionBuilder,
          $$AnswerKeyEntriesTableUpdateCompanionBuilder,
          (AnswerKeyEntry, $$AnswerKeyEntriesTableReferences),
          AnswerKeyEntry,
          PrefetchHooks Function({bool keyVersionId, bool scoringRuleId})
        > {
  $$AnswerKeyEntriesTableTableManager(_$AppDb db, $AnswerKeyEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnswerKeyEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnswerKeyEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnswerKeyEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> tenantId = const Value.absent(),
                Value<String> keyVersionId = const Value.absent(),
                Value<String> setCode = const Value.absent(),
                Value<String> questionId = const Value.absent(),
                Value<String> correctOptionsJson = const Value.absent(),
                Value<int?> correctInteger = const Value.absent(),
                Value<KeyEntryState> state = const Value.absent(),
                Value<String?> scoringRuleId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AnswerKeyEntriesCompanion(
                tenantId: tenantId,
                keyVersionId: keyVersionId,
                setCode: setCode,
                questionId: questionId,
                correctOptionsJson: correctOptionsJson,
                correctInteger: correctInteger,
                state: state,
                scoringRuleId: scoringRuleId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tenantId,
                required String keyVersionId,
                required String setCode,
                required String questionId,
                Value<String> correctOptionsJson = const Value.absent(),
                Value<int?> correctInteger = const Value.absent(),
                Value<KeyEntryState> state = const Value.absent(),
                Value<String?> scoringRuleId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AnswerKeyEntriesCompanion.insert(
                tenantId: tenantId,
                keyVersionId: keyVersionId,
                setCode: setCode,
                questionId: questionId,
                correctOptionsJson: correctOptionsJson,
                correctInteger: correctInteger,
                state: state,
                scoringRuleId: scoringRuleId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AnswerKeyEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({keyVersionId = false, scoringRuleId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (keyVersionId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.keyVersionId,
                                    referencedTable:
                                        $$AnswerKeyEntriesTableReferences
                                            ._keyVersionIdTable(db),
                                    referencedColumn:
                                        $$AnswerKeyEntriesTableReferences
                                            ._keyVersionIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (scoringRuleId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.scoringRuleId,
                                    referencedTable:
                                        $$AnswerKeyEntriesTableReferences
                                            ._scoringRuleIdTable(db),
                                    referencedColumn:
                                        $$AnswerKeyEntriesTableReferences
                                            ._scoringRuleIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$AnswerKeyEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $AnswerKeyEntriesTable,
      AnswerKeyEntry,
      $$AnswerKeyEntriesTableFilterComposer,
      $$AnswerKeyEntriesTableOrderingComposer,
      $$AnswerKeyEntriesTableAnnotationComposer,
      $$AnswerKeyEntriesTableCreateCompanionBuilder,
      $$AnswerKeyEntriesTableUpdateCompanionBuilder,
      (AnswerKeyEntry, $$AnswerKeyEntriesTableReferences),
      AnswerKeyEntry,
      PrefetchHooks Function({bool keyVersionId, bool scoringRuleId})
    >;
typedef $$ScansTableCreateCompanionBuilder =
    ScansCompanion Function({
      Value<String> id,
      required String tenantId,
      required String examId,
      Value<String?> studentId,
      Value<String?> rollNoRead,
      Value<double?> rollConfidence,
      Value<String?> setCodeRead,
      required int layoutVersion,
      Value<String?> thresholdConfigId,
      Value<DateTime> capturedAt,
      Value<String?> deviceId,
      required String warpedImagePath,
      required String thumbPath,
      required String annotatedPath,
      Value<String?> originalPath,
      Value<double?> sheetConfidence,
      Value<String> gateReportJson,
      Value<bool> curlFlag,
      Value<ScanStatus> status,
      Value<SyncState> syncState,
      Value<int> rowid,
    });
typedef $$ScansTableUpdateCompanionBuilder =
    ScansCompanion Function({
      Value<String> id,
      Value<String> tenantId,
      Value<String> examId,
      Value<String?> studentId,
      Value<String?> rollNoRead,
      Value<double?> rollConfidence,
      Value<String?> setCodeRead,
      Value<int> layoutVersion,
      Value<String?> thresholdConfigId,
      Value<DateTime> capturedAt,
      Value<String?> deviceId,
      Value<String> warpedImagePath,
      Value<String> thumbPath,
      Value<String> annotatedPath,
      Value<String?> originalPath,
      Value<double?> sheetConfidence,
      Value<String> gateReportJson,
      Value<bool> curlFlag,
      Value<ScanStatus> status,
      Value<SyncState> syncState,
      Value<int> rowid,
    });

final class $$ScansTableReferences
    extends BaseReferences<_$AppDb, $ScansTable, Scan> {
  $$ScansTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ExamsTable _examIdTable(_$AppDb db) =>
      db.exams.createAlias('scans__exam_id__exams__id');

  $$ExamsTableProcessedTableManager get examId {
    final $_column = $_itemColumn<String>('exam_id')!;

    final manager = $$ExamsTableTableManager(
      $_db,
      $_db.exams,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_examIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $StudentsTable _studentIdTable(_$AppDb db) =>
      db.students.createAlias('scans__student_id__students__id');

  $$StudentsTableProcessedTableManager? get studentId {
    final $_column = $_itemColumn<String>('student_id');
    if ($_column == null) return null;
    final manager = $$StudentsTableTableManager(
      $_db,
      $_db.students,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_studentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$BubbleReadsTable, List<BubbleRead>>
  _bubbleReadsRefsTable(_$AppDb db) => MultiTypedResultKey.fromTable(
    db.bubbleReads,
    aliasName: 'scans__id__bubble_reads__scan_id',
  );

  $$BubbleReadsTableProcessedTableManager get bubbleReadsRefs {
    final manager = $$BubbleReadsTableTableManager(
      $_db,
      $_db.bubbleReads,
    ).filter((f) => f.scanId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_bubbleReadsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ResultsTable, List<Result>> _resultsRefsTable(
    _$AppDb db,
  ) => MultiTypedResultKey.fromTable(
    db.results,
    aliasName: 'scans__id__results__scan_id',
  );

  $$ResultsTableProcessedTableManager get resultsRefs {
    final manager = $$ResultsTableTableManager(
      $_db,
      $_db.results,
    ).filter((f) => f.scanId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_resultsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ReviewQueueTable, List<ReviewQueueItem>>
  _reviewQueueRefsTable(_$AppDb db) => MultiTypedResultKey.fromTable(
    db.reviewQueue,
    aliasName: 'scans__id__review_queue__scan_id',
  );

  $$ReviewQueueTableProcessedTableManager get reviewQueueRefs {
    final manager = $$ReviewQueueTableTableManager(
      $_db,
      $_db.reviewQueue,
    ).filter((f) => f.scanId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_reviewQueueRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ScansTableFilterComposer extends Composer<_$AppDb, $ScansTable> {
  $$ScansTableFilterComposer({
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

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rollNoRead => $composableBuilder(
    column: $table.rollNoRead,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rollConfidence => $composableBuilder(
    column: $table.rollConfidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get setCodeRead => $composableBuilder(
    column: $table.setCodeRead,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get layoutVersion => $composableBuilder(
    column: $table.layoutVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thresholdConfigId => $composableBuilder(
    column: $table.thresholdConfigId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get capturedAt =>
      $composableBuilder(
        column: $table.capturedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get warpedImagePath => $composableBuilder(
    column: $table.warpedImagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbPath => $composableBuilder(
    column: $table.thumbPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get annotatedPath => $composableBuilder(
    column: $table.annotatedPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalPath => $composableBuilder(
    column: $table.originalPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sheetConfidence => $composableBuilder(
    column: $table.sheetConfidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gateReportJson => $composableBuilder(
    column: $table.gateReportJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get curlFlag => $composableBuilder(
    column: $table.curlFlag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ScanStatus, ScanStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<SyncState, SyncState, String> get syncState =>
      $composableBuilder(
        column: $table.syncState,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$ExamsTableFilterComposer get examId {
    final $$ExamsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.examId,
      referencedTable: $db.exams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamsTableFilterComposer(
            $db: $db,
            $table: $db.exams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StudentsTableFilterComposer get studentId {
    final $$StudentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.students,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableFilterComposer(
            $db: $db,
            $table: $db.students,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> bubbleReadsRefs(
    Expression<bool> Function($$BubbleReadsTableFilterComposer f) f,
  ) {
    final $$BubbleReadsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bubbleReads,
      getReferencedColumn: (t) => t.scanId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BubbleReadsTableFilterComposer(
            $db: $db,
            $table: $db.bubbleReads,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> resultsRefs(
    Expression<bool> Function($$ResultsTableFilterComposer f) f,
  ) {
    final $$ResultsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.results,
      getReferencedColumn: (t) => t.scanId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ResultsTableFilterComposer(
            $db: $db,
            $table: $db.results,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> reviewQueueRefs(
    Expression<bool> Function($$ReviewQueueTableFilterComposer f) f,
  ) {
    final $$ReviewQueueTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reviewQueue,
      getReferencedColumn: (t) => t.scanId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewQueueTableFilterComposer(
            $db: $db,
            $table: $db.reviewQueue,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ScansTableOrderingComposer extends Composer<_$AppDb, $ScansTable> {
  $$ScansTableOrderingComposer({
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

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rollNoRead => $composableBuilder(
    column: $table.rollNoRead,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rollConfidence => $composableBuilder(
    column: $table.rollConfidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get setCodeRead => $composableBuilder(
    column: $table.setCodeRead,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get layoutVersion => $composableBuilder(
    column: $table.layoutVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thresholdConfigId => $composableBuilder(
    column: $table.thresholdConfigId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get warpedImagePath => $composableBuilder(
    column: $table.warpedImagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbPath => $composableBuilder(
    column: $table.thumbPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get annotatedPath => $composableBuilder(
    column: $table.annotatedPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalPath => $composableBuilder(
    column: $table.originalPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sheetConfidence => $composableBuilder(
    column: $table.sheetConfidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gateReportJson => $composableBuilder(
    column: $table.gateReportJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get curlFlag => $composableBuilder(
    column: $table.curlFlag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  $$ExamsTableOrderingComposer get examId {
    final $$ExamsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.examId,
      referencedTable: $db.exams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamsTableOrderingComposer(
            $db: $db,
            $table: $db.exams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StudentsTableOrderingComposer get studentId {
    final $$StudentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.students,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableOrderingComposer(
            $db: $db,
            $table: $db.students,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScansTableAnnotationComposer extends Composer<_$AppDb, $ScansTable> {
  $$ScansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get rollNoRead => $composableBuilder(
    column: $table.rollNoRead,
    builder: (column) => column,
  );

  GeneratedColumn<double> get rollConfidence => $composableBuilder(
    column: $table.rollConfidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get setCodeRead => $composableBuilder(
    column: $table.setCodeRead,
    builder: (column) => column,
  );

  GeneratedColumn<int> get layoutVersion => $composableBuilder(
    column: $table.layoutVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get thresholdConfigId => $composableBuilder(
    column: $table.thresholdConfigId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, String> get capturedAt =>
      $composableBuilder(
        column: $table.capturedAt,
        builder: (column) => column,
      );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get warpedImagePath => $composableBuilder(
    column: $table.warpedImagePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get thumbPath =>
      $composableBuilder(column: $table.thumbPath, builder: (column) => column);

  GeneratedColumn<String> get annotatedPath => $composableBuilder(
    column: $table.annotatedPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originalPath => $composableBuilder(
    column: $table.originalPath,
    builder: (column) => column,
  );

  GeneratedColumn<double> get sheetConfidence => $composableBuilder(
    column: $table.sheetConfidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get gateReportJson => $composableBuilder(
    column: $table.gateReportJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get curlFlag =>
      $composableBuilder(column: $table.curlFlag, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ScanStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncState, String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  $$ExamsTableAnnotationComposer get examId {
    final $$ExamsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.examId,
      referencedTable: $db.exams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamsTableAnnotationComposer(
            $db: $db,
            $table: $db.exams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StudentsTableAnnotationComposer get studentId {
    final $$StudentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.students,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableAnnotationComposer(
            $db: $db,
            $table: $db.students,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> bubbleReadsRefs<T extends Object>(
    Expression<T> Function($$BubbleReadsTableAnnotationComposer a) f,
  ) {
    final $$BubbleReadsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bubbleReads,
      getReferencedColumn: (t) => t.scanId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BubbleReadsTableAnnotationComposer(
            $db: $db,
            $table: $db.bubbleReads,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> resultsRefs<T extends Object>(
    Expression<T> Function($$ResultsTableAnnotationComposer a) f,
  ) {
    final $$ResultsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.results,
      getReferencedColumn: (t) => t.scanId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ResultsTableAnnotationComposer(
            $db: $db,
            $table: $db.results,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> reviewQueueRefs<T extends Object>(
    Expression<T> Function($$ReviewQueueTableAnnotationComposer a) f,
  ) {
    final $$ReviewQueueTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reviewQueue,
      getReferencedColumn: (t) => t.scanId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewQueueTableAnnotationComposer(
            $db: $db,
            $table: $db.reviewQueue,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ScansTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $ScansTable,
          Scan,
          $$ScansTableFilterComposer,
          $$ScansTableOrderingComposer,
          $$ScansTableAnnotationComposer,
          $$ScansTableCreateCompanionBuilder,
          $$ScansTableUpdateCompanionBuilder,
          (Scan, $$ScansTableReferences),
          Scan,
          PrefetchHooks Function({
            bool examId,
            bool studentId,
            bool bubbleReadsRefs,
            bool resultsRefs,
            bool reviewQueueRefs,
          })
        > {
  $$ScansTableTableManager(_$AppDb db, $ScansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String> examId = const Value.absent(),
                Value<String?> studentId = const Value.absent(),
                Value<String?> rollNoRead = const Value.absent(),
                Value<double?> rollConfidence = const Value.absent(),
                Value<String?> setCodeRead = const Value.absent(),
                Value<int> layoutVersion = const Value.absent(),
                Value<String?> thresholdConfigId = const Value.absent(),
                Value<DateTime> capturedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String> warpedImagePath = const Value.absent(),
                Value<String> thumbPath = const Value.absent(),
                Value<String> annotatedPath = const Value.absent(),
                Value<String?> originalPath = const Value.absent(),
                Value<double?> sheetConfidence = const Value.absent(),
                Value<String> gateReportJson = const Value.absent(),
                Value<bool> curlFlag = const Value.absent(),
                Value<ScanStatus> status = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScansCompanion(
                id: id,
                tenantId: tenantId,
                examId: examId,
                studentId: studentId,
                rollNoRead: rollNoRead,
                rollConfidence: rollConfidence,
                setCodeRead: setCodeRead,
                layoutVersion: layoutVersion,
                thresholdConfigId: thresholdConfigId,
                capturedAt: capturedAt,
                deviceId: deviceId,
                warpedImagePath: warpedImagePath,
                thumbPath: thumbPath,
                annotatedPath: annotatedPath,
                originalPath: originalPath,
                sheetConfidence: sheetConfidence,
                gateReportJson: gateReportJson,
                curlFlag: curlFlag,
                status: status,
                syncState: syncState,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String tenantId,
                required String examId,
                Value<String?> studentId = const Value.absent(),
                Value<String?> rollNoRead = const Value.absent(),
                Value<double?> rollConfidence = const Value.absent(),
                Value<String?> setCodeRead = const Value.absent(),
                required int layoutVersion,
                Value<String?> thresholdConfigId = const Value.absent(),
                Value<DateTime> capturedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                required String warpedImagePath,
                required String thumbPath,
                required String annotatedPath,
                Value<String?> originalPath = const Value.absent(),
                Value<double?> sheetConfidence = const Value.absent(),
                Value<String> gateReportJson = const Value.absent(),
                Value<bool> curlFlag = const Value.absent(),
                Value<ScanStatus> status = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScansCompanion.insert(
                id: id,
                tenantId: tenantId,
                examId: examId,
                studentId: studentId,
                rollNoRead: rollNoRead,
                rollConfidence: rollConfidence,
                setCodeRead: setCodeRead,
                layoutVersion: layoutVersion,
                thresholdConfigId: thresholdConfigId,
                capturedAt: capturedAt,
                deviceId: deviceId,
                warpedImagePath: warpedImagePath,
                thumbPath: thumbPath,
                annotatedPath: annotatedPath,
                originalPath: originalPath,
                sheetConfidence: sheetConfidence,
                gateReportJson: gateReportJson,
                curlFlag: curlFlag,
                status: status,
                syncState: syncState,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$ScansTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                examId = false,
                studentId = false,
                bubbleReadsRefs = false,
                resultsRefs = false,
                reviewQueueRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (bubbleReadsRefs) db.bubbleReads,
                    if (resultsRefs) db.results,
                    if (reviewQueueRefs) db.reviewQueue,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (examId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.examId,
                                    referencedTable: $$ScansTableReferences
                                        ._examIdTable(db),
                                    referencedColumn: $$ScansTableReferences
                                        ._examIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (studentId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.studentId,
                                    referencedTable: $$ScansTableReferences
                                        ._studentIdTable(db),
                                    referencedColumn: $$ScansTableReferences
                                        ._studentIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (bubbleReadsRefs)
                        await $_getPrefetchedData<
                          Scan,
                          $ScansTable,
                          BubbleRead
                        >(
                          currentTable: table,
                          referencedTable: $$ScansTableReferences
                              ._bubbleReadsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ScansTableReferences(
                                db,
                                table,
                                p0,
                              ).bubbleReadsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.scanId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (resultsRefs)
                        await $_getPrefetchedData<Scan, $ScansTable, Result>(
                          currentTable: table,
                          referencedTable: $$ScansTableReferences
                              ._resultsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ScansTableReferences(db, table, p0).resultsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.scanId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (reviewQueueRefs)
                        await $_getPrefetchedData<
                          Scan,
                          $ScansTable,
                          ReviewQueueItem
                        >(
                          currentTable: table,
                          referencedTable: $$ScansTableReferences
                              ._reviewQueueRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ScansTableReferences(
                                db,
                                table,
                                p0,
                              ).reviewQueueRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.scanId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ScansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $ScansTable,
      Scan,
      $$ScansTableFilterComposer,
      $$ScansTableOrderingComposer,
      $$ScansTableAnnotationComposer,
      $$ScansTableCreateCompanionBuilder,
      $$ScansTableUpdateCompanionBuilder,
      (Scan, $$ScansTableReferences),
      Scan,
      PrefetchHooks Function({
        bool examId,
        bool studentId,
        bool bubbleReadsRefs,
        bool resultsRefs,
        bool reviewQueueRefs,
      })
    >;
typedef $$BubbleReadsTableCreateCompanionBuilder =
    BubbleReadsCompanion Function({
      required String tenantId,
      required String scanId,
      required String fieldKey,
      required int optionIndex,
      Value<double?> meanIntensity,
      Value<double?> fillRatio,
      required MarkClass markClass,
      Value<double?> confidence,
      Value<double?> thresholdUsed,
      Value<bool> isHumanCorrection,
      Value<int> rowid,
    });
typedef $$BubbleReadsTableUpdateCompanionBuilder =
    BubbleReadsCompanion Function({
      Value<String> tenantId,
      Value<String> scanId,
      Value<String> fieldKey,
      Value<int> optionIndex,
      Value<double?> meanIntensity,
      Value<double?> fillRatio,
      Value<MarkClass> markClass,
      Value<double?> confidence,
      Value<double?> thresholdUsed,
      Value<bool> isHumanCorrection,
      Value<int> rowid,
    });

final class $$BubbleReadsTableReferences
    extends BaseReferences<_$AppDb, $BubbleReadsTable, BubbleRead> {
  $$BubbleReadsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ScansTable _scanIdTable(_$AppDb db) =>
      db.scans.createAlias('bubble_reads__scan_id__scans__id');

  $$ScansTableProcessedTableManager get scanId {
    final $_column = $_itemColumn<String>('scan_id')!;

    final manager = $$ScansTableTableManager(
      $_db,
      $_db.scans,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_scanIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BubbleReadsTableFilterComposer
    extends Composer<_$AppDb, $BubbleReadsTable> {
  $$BubbleReadsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldKey => $composableBuilder(
    column: $table.fieldKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get optionIndex => $composableBuilder(
    column: $table.optionIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get meanIntensity => $composableBuilder(
    column: $table.meanIntensity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fillRatio => $composableBuilder(
    column: $table.fillRatio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MarkClass, MarkClass, String> get markClass =>
      $composableBuilder(
        column: $table.markClass,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get thresholdUsed => $composableBuilder(
    column: $table.thresholdUsed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isHumanCorrection => $composableBuilder(
    column: $table.isHumanCorrection,
    builder: (column) => ColumnFilters(column),
  );

  $$ScansTableFilterComposer get scanId {
    final $$ScansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scanId,
      referencedTable: $db.scans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScansTableFilterComposer(
            $db: $db,
            $table: $db.scans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BubbleReadsTableOrderingComposer
    extends Composer<_$AppDb, $BubbleReadsTable> {
  $$BubbleReadsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldKey => $composableBuilder(
    column: $table.fieldKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get optionIndex => $composableBuilder(
    column: $table.optionIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get meanIntensity => $composableBuilder(
    column: $table.meanIntensity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fillRatio => $composableBuilder(
    column: $table.fillRatio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get markClass => $composableBuilder(
    column: $table.markClass,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get thresholdUsed => $composableBuilder(
    column: $table.thresholdUsed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isHumanCorrection => $composableBuilder(
    column: $table.isHumanCorrection,
    builder: (column) => ColumnOrderings(column),
  );

  $$ScansTableOrderingComposer get scanId {
    final $$ScansTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scanId,
      referencedTable: $db.scans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScansTableOrderingComposer(
            $db: $db,
            $table: $db.scans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BubbleReadsTableAnnotationComposer
    extends Composer<_$AppDb, $BubbleReadsTable> {
  $$BubbleReadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get fieldKey =>
      $composableBuilder(column: $table.fieldKey, builder: (column) => column);

  GeneratedColumn<int> get optionIndex => $composableBuilder(
    column: $table.optionIndex,
    builder: (column) => column,
  );

  GeneratedColumn<double> get meanIntensity => $composableBuilder(
    column: $table.meanIntensity,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fillRatio =>
      $composableBuilder(column: $table.fillRatio, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MarkClass, String> get markClass =>
      $composableBuilder(column: $table.markClass, builder: (column) => column);

  GeneratedColumn<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<double> get thresholdUsed => $composableBuilder(
    column: $table.thresholdUsed,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isHumanCorrection => $composableBuilder(
    column: $table.isHumanCorrection,
    builder: (column) => column,
  );

  $$ScansTableAnnotationComposer get scanId {
    final $$ScansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scanId,
      referencedTable: $db.scans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScansTableAnnotationComposer(
            $db: $db,
            $table: $db.scans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BubbleReadsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $BubbleReadsTable,
          BubbleRead,
          $$BubbleReadsTableFilterComposer,
          $$BubbleReadsTableOrderingComposer,
          $$BubbleReadsTableAnnotationComposer,
          $$BubbleReadsTableCreateCompanionBuilder,
          $$BubbleReadsTableUpdateCompanionBuilder,
          (BubbleRead, $$BubbleReadsTableReferences),
          BubbleRead,
          PrefetchHooks Function({bool scanId})
        > {
  $$BubbleReadsTableTableManager(_$AppDb db, $BubbleReadsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BubbleReadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BubbleReadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BubbleReadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> tenantId = const Value.absent(),
                Value<String> scanId = const Value.absent(),
                Value<String> fieldKey = const Value.absent(),
                Value<int> optionIndex = const Value.absent(),
                Value<double?> meanIntensity = const Value.absent(),
                Value<double?> fillRatio = const Value.absent(),
                Value<MarkClass> markClass = const Value.absent(),
                Value<double?> confidence = const Value.absent(),
                Value<double?> thresholdUsed = const Value.absent(),
                Value<bool> isHumanCorrection = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BubbleReadsCompanion(
                tenantId: tenantId,
                scanId: scanId,
                fieldKey: fieldKey,
                optionIndex: optionIndex,
                meanIntensity: meanIntensity,
                fillRatio: fillRatio,
                markClass: markClass,
                confidence: confidence,
                thresholdUsed: thresholdUsed,
                isHumanCorrection: isHumanCorrection,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tenantId,
                required String scanId,
                required String fieldKey,
                required int optionIndex,
                Value<double?> meanIntensity = const Value.absent(),
                Value<double?> fillRatio = const Value.absent(),
                required MarkClass markClass,
                Value<double?> confidence = const Value.absent(),
                Value<double?> thresholdUsed = const Value.absent(),
                Value<bool> isHumanCorrection = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BubbleReadsCompanion.insert(
                tenantId: tenantId,
                scanId: scanId,
                fieldKey: fieldKey,
                optionIndex: optionIndex,
                meanIntensity: meanIntensity,
                fillRatio: fillRatio,
                markClass: markClass,
                confidence: confidence,
                thresholdUsed: thresholdUsed,
                isHumanCorrection: isHumanCorrection,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BubbleReadsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({scanId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (scanId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.scanId,
                                referencedTable: $$BubbleReadsTableReferences
                                    ._scanIdTable(db),
                                referencedColumn: $$BubbleReadsTableReferences
                                    ._scanIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BubbleReadsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $BubbleReadsTable,
      BubbleRead,
      $$BubbleReadsTableFilterComposer,
      $$BubbleReadsTableOrderingComposer,
      $$BubbleReadsTableAnnotationComposer,
      $$BubbleReadsTableCreateCompanionBuilder,
      $$BubbleReadsTableUpdateCompanionBuilder,
      (BubbleRead, $$BubbleReadsTableReferences),
      BubbleRead,
      PrefetchHooks Function({bool scanId})
    >;
typedef $$ScoringRunsTableCreateCompanionBuilder =
    ScoringRunsCompanion Function({
      Value<String> id,
      required String tenantId,
      required String examId,
      required String keyVersionId,
      required String scoringRuleSnapshotJson,
      required int sheetLayoutVersion,
      Value<String?> thresholdConfigId,
      Value<DateTime> startedAt,
      Value<DateTime?> finishedAt,
      Value<int> rowid,
    });
typedef $$ScoringRunsTableUpdateCompanionBuilder =
    ScoringRunsCompanion Function({
      Value<String> id,
      Value<String> tenantId,
      Value<String> examId,
      Value<String> keyVersionId,
      Value<String> scoringRuleSnapshotJson,
      Value<int> sheetLayoutVersion,
      Value<String?> thresholdConfigId,
      Value<DateTime> startedAt,
      Value<DateTime?> finishedAt,
      Value<int> rowid,
    });

final class $$ScoringRunsTableReferences
    extends BaseReferences<_$AppDb, $ScoringRunsTable, ScoringRun> {
  $$ScoringRunsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ExamsTable _examIdTable(_$AppDb db) =>
      db.exams.createAlias('scoring_runs__exam_id__exams__id');

  $$ExamsTableProcessedTableManager get examId {
    final $_column = $_itemColumn<String>('exam_id')!;

    final manager = $$ExamsTableTableManager(
      $_db,
      $_db.exams,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_examIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AnswerKeyVersionsTable _keyVersionIdTable(_$AppDb db) => db
      .answerKeyVersions
      .createAlias('scoring_runs__key_version_id__answer_key_versions__id');

  $$AnswerKeyVersionsTableProcessedTableManager get keyVersionId {
    final $_column = $_itemColumn<String>('key_version_id')!;

    final manager = $$AnswerKeyVersionsTableTableManager(
      $_db,
      $_db.answerKeyVersions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_keyVersionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ResultsTable, List<Result>> _resultsRefsTable(
    _$AppDb db,
  ) => MultiTypedResultKey.fromTable(
    db.results,
    aliasName: 'scoring_runs__id__results__scoring_run_id',
  );

  $$ResultsTableProcessedTableManager get resultsRefs {
    final manager = $$ResultsTableTableManager(
      $_db,
      $_db.results,
    ).filter((f) => f.scoringRunId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_resultsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ScoringRunsTableFilterComposer
    extends Composer<_$AppDb, $ScoringRunsTable> {
  $$ScoringRunsTableFilterComposer({
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

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scoringRuleSnapshotJson => $composableBuilder(
    column: $table.scoringRuleSnapshotJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sheetLayoutVersion => $composableBuilder(
    column: $table.sheetLayoutVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thresholdConfigId => $composableBuilder(
    column: $table.thresholdConfigId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get startedAt =>
      $composableBuilder(
        column: $table.startedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get finishedAt =>
      $composableBuilder(
        column: $table.finishedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$ExamsTableFilterComposer get examId {
    final $$ExamsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.examId,
      referencedTable: $db.exams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamsTableFilterComposer(
            $db: $db,
            $table: $db.exams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AnswerKeyVersionsTableFilterComposer get keyVersionId {
    final $$AnswerKeyVersionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.keyVersionId,
      referencedTable: $db.answerKeyVersions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnswerKeyVersionsTableFilterComposer(
            $db: $db,
            $table: $db.answerKeyVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> resultsRefs(
    Expression<bool> Function($$ResultsTableFilterComposer f) f,
  ) {
    final $$ResultsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.results,
      getReferencedColumn: (t) => t.scoringRunId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ResultsTableFilterComposer(
            $db: $db,
            $table: $db.results,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ScoringRunsTableOrderingComposer
    extends Composer<_$AppDb, $ScoringRunsTable> {
  $$ScoringRunsTableOrderingComposer({
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

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scoringRuleSnapshotJson => $composableBuilder(
    column: $table.scoringRuleSnapshotJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sheetLayoutVersion => $composableBuilder(
    column: $table.sheetLayoutVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thresholdConfigId => $composableBuilder(
    column: $table.thresholdConfigId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ExamsTableOrderingComposer get examId {
    final $$ExamsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.examId,
      referencedTable: $db.exams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamsTableOrderingComposer(
            $db: $db,
            $table: $db.exams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AnswerKeyVersionsTableOrderingComposer get keyVersionId {
    final $$AnswerKeyVersionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.keyVersionId,
      referencedTable: $db.answerKeyVersions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnswerKeyVersionsTableOrderingComposer(
            $db: $db,
            $table: $db.answerKeyVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScoringRunsTableAnnotationComposer
    extends Composer<_$AppDb, $ScoringRunsTable> {
  $$ScoringRunsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get scoringRuleSnapshotJson => $composableBuilder(
    column: $table.scoringRuleSnapshotJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sheetLayoutVersion => $composableBuilder(
    column: $table.sheetLayoutVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get thresholdConfigId => $composableBuilder(
    column: $table.thresholdConfigId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, String> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, String> get finishedAt =>
      $composableBuilder(
        column: $table.finishedAt,
        builder: (column) => column,
      );

  $$ExamsTableAnnotationComposer get examId {
    final $$ExamsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.examId,
      referencedTable: $db.exams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamsTableAnnotationComposer(
            $db: $db,
            $table: $db.exams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AnswerKeyVersionsTableAnnotationComposer get keyVersionId {
    final $$AnswerKeyVersionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.keyVersionId,
          referencedTable: $db.answerKeyVersions,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AnswerKeyVersionsTableAnnotationComposer(
                $db: $db,
                $table: $db.answerKeyVersions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<T> resultsRefs<T extends Object>(
    Expression<T> Function($$ResultsTableAnnotationComposer a) f,
  ) {
    final $$ResultsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.results,
      getReferencedColumn: (t) => t.scoringRunId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ResultsTableAnnotationComposer(
            $db: $db,
            $table: $db.results,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ScoringRunsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $ScoringRunsTable,
          ScoringRun,
          $$ScoringRunsTableFilterComposer,
          $$ScoringRunsTableOrderingComposer,
          $$ScoringRunsTableAnnotationComposer,
          $$ScoringRunsTableCreateCompanionBuilder,
          $$ScoringRunsTableUpdateCompanionBuilder,
          (ScoringRun, $$ScoringRunsTableReferences),
          ScoringRun,
          PrefetchHooks Function({
            bool examId,
            bool keyVersionId,
            bool resultsRefs,
          })
        > {
  $$ScoringRunsTableTableManager(_$AppDb db, $ScoringRunsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScoringRunsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScoringRunsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScoringRunsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String> examId = const Value.absent(),
                Value<String> keyVersionId = const Value.absent(),
                Value<String> scoringRuleSnapshotJson = const Value.absent(),
                Value<int> sheetLayoutVersion = const Value.absent(),
                Value<String?> thresholdConfigId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScoringRunsCompanion(
                id: id,
                tenantId: tenantId,
                examId: examId,
                keyVersionId: keyVersionId,
                scoringRuleSnapshotJson: scoringRuleSnapshotJson,
                sheetLayoutVersion: sheetLayoutVersion,
                thresholdConfigId: thresholdConfigId,
                startedAt: startedAt,
                finishedAt: finishedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String tenantId,
                required String examId,
                required String keyVersionId,
                required String scoringRuleSnapshotJson,
                required int sheetLayoutVersion,
                Value<String?> thresholdConfigId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScoringRunsCompanion.insert(
                id: id,
                tenantId: tenantId,
                examId: examId,
                keyVersionId: keyVersionId,
                scoringRuleSnapshotJson: scoringRuleSnapshotJson,
                sheetLayoutVersion: sheetLayoutVersion,
                thresholdConfigId: thresholdConfigId,
                startedAt: startedAt,
                finishedAt: finishedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ScoringRunsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({examId = false, keyVersionId = false, resultsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (resultsRefs) db.results],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (examId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.examId,
                                    referencedTable:
                                        $$ScoringRunsTableReferences
                                            ._examIdTable(db),
                                    referencedColumn:
                                        $$ScoringRunsTableReferences
                                            ._examIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (keyVersionId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.keyVersionId,
                                    referencedTable:
                                        $$ScoringRunsTableReferences
                                            ._keyVersionIdTable(db),
                                    referencedColumn:
                                        $$ScoringRunsTableReferences
                                            ._keyVersionIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (resultsRefs)
                        await $_getPrefetchedData<
                          ScoringRun,
                          $ScoringRunsTable,
                          Result
                        >(
                          currentTable: table,
                          referencedTable: $$ScoringRunsTableReferences
                              ._resultsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ScoringRunsTableReferences(
                                db,
                                table,
                                p0,
                              ).resultsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.scoringRunId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ScoringRunsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $ScoringRunsTable,
      ScoringRun,
      $$ScoringRunsTableFilterComposer,
      $$ScoringRunsTableOrderingComposer,
      $$ScoringRunsTableAnnotationComposer,
      $$ScoringRunsTableCreateCompanionBuilder,
      $$ScoringRunsTableUpdateCompanionBuilder,
      (ScoringRun, $$ScoringRunsTableReferences),
      ScoringRun,
      PrefetchHooks Function({bool examId, bool keyVersionId, bool resultsRefs})
    >;
typedef $$ResultsTableCreateCompanionBuilder =
    ResultsCompanion Function({
      Value<String> id,
      required String tenantId,
      required String scanId,
      required String examId,
      required String studentId,
      required String keyVersionId,
      required String scoringRunId,
      required double total,
      Value<int> correct,
      Value<int> wrong,
      Value<int> unattempted,
      Value<String> subjectTotalsJson,
      Value<int?> rank,
      Value<ResultStatus> status,
      Value<DateTime> gradedAt,
      Value<int> rowid,
    });
typedef $$ResultsTableUpdateCompanionBuilder =
    ResultsCompanion Function({
      Value<String> id,
      Value<String> tenantId,
      Value<String> scanId,
      Value<String> examId,
      Value<String> studentId,
      Value<String> keyVersionId,
      Value<String> scoringRunId,
      Value<double> total,
      Value<int> correct,
      Value<int> wrong,
      Value<int> unattempted,
      Value<String> subjectTotalsJson,
      Value<int?> rank,
      Value<ResultStatus> status,
      Value<DateTime> gradedAt,
      Value<int> rowid,
    });

final class $$ResultsTableReferences
    extends BaseReferences<_$AppDb, $ResultsTable, Result> {
  $$ResultsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ScansTable _scanIdTable(_$AppDb db) =>
      db.scans.createAlias('results__scan_id__scans__id');

  $$ScansTableProcessedTableManager get scanId {
    final $_column = $_itemColumn<String>('scan_id')!;

    final manager = $$ScansTableTableManager(
      $_db,
      $_db.scans,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_scanIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ExamsTable _examIdTable(_$AppDb db) =>
      db.exams.createAlias('results__exam_id__exams__id');

  $$ExamsTableProcessedTableManager get examId {
    final $_column = $_itemColumn<String>('exam_id')!;

    final manager = $$ExamsTableTableManager(
      $_db,
      $_db.exams,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_examIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $StudentsTable _studentIdTable(_$AppDb db) =>
      db.students.createAlias('results__student_id__students__id');

  $$StudentsTableProcessedTableManager get studentId {
    final $_column = $_itemColumn<String>('student_id')!;

    final manager = $$StudentsTableTableManager(
      $_db,
      $_db.students,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_studentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AnswerKeyVersionsTable _keyVersionIdTable(_$AppDb db) => db
      .answerKeyVersions
      .createAlias('results__key_version_id__answer_key_versions__id');

  $$AnswerKeyVersionsTableProcessedTableManager get keyVersionId {
    final $_column = $_itemColumn<String>('key_version_id')!;

    final manager = $$AnswerKeyVersionsTableTableManager(
      $_db,
      $_db.answerKeyVersions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_keyVersionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ScoringRunsTable _scoringRunIdTable(_$AppDb db) =>
      db.scoringRuns.createAlias('results__scoring_run_id__scoring_runs__id');

  $$ScoringRunsTableProcessedTableManager get scoringRunId {
    final $_column = $_itemColumn<String>('scoring_run_id')!;

    final manager = $$ScoringRunsTableTableManager(
      $_db,
      $_db.scoringRuns,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_scoringRunIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ResultsTableFilterComposer extends Composer<_$AppDb, $ResultsTable> {
  $$ResultsTableFilterComposer({
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

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correct => $composableBuilder(
    column: $table.correct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wrong => $composableBuilder(
    column: $table.wrong,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unattempted => $composableBuilder(
    column: $table.unattempted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subjectTotalsJson => $composableBuilder(
    column: $table.subjectTotalsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rank => $composableBuilder(
    column: $table.rank,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ResultStatus, ResultStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get gradedAt =>
      $composableBuilder(
        column: $table.gradedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$ScansTableFilterComposer get scanId {
    final $$ScansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scanId,
      referencedTable: $db.scans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScansTableFilterComposer(
            $db: $db,
            $table: $db.scans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExamsTableFilterComposer get examId {
    final $$ExamsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.examId,
      referencedTable: $db.exams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamsTableFilterComposer(
            $db: $db,
            $table: $db.exams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StudentsTableFilterComposer get studentId {
    final $$StudentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.students,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableFilterComposer(
            $db: $db,
            $table: $db.students,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AnswerKeyVersionsTableFilterComposer get keyVersionId {
    final $$AnswerKeyVersionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.keyVersionId,
      referencedTable: $db.answerKeyVersions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnswerKeyVersionsTableFilterComposer(
            $db: $db,
            $table: $db.answerKeyVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ScoringRunsTableFilterComposer get scoringRunId {
    final $$ScoringRunsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scoringRunId,
      referencedTable: $db.scoringRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoringRunsTableFilterComposer(
            $db: $db,
            $table: $db.scoringRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ResultsTableOrderingComposer extends Composer<_$AppDb, $ResultsTable> {
  $$ResultsTableOrderingComposer({
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

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correct => $composableBuilder(
    column: $table.correct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wrong => $composableBuilder(
    column: $table.wrong,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unattempted => $composableBuilder(
    column: $table.unattempted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subjectTotalsJson => $composableBuilder(
    column: $table.subjectTotalsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rank => $composableBuilder(
    column: $table.rank,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gradedAt => $composableBuilder(
    column: $table.gradedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ScansTableOrderingComposer get scanId {
    final $$ScansTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scanId,
      referencedTable: $db.scans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScansTableOrderingComposer(
            $db: $db,
            $table: $db.scans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExamsTableOrderingComposer get examId {
    final $$ExamsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.examId,
      referencedTable: $db.exams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamsTableOrderingComposer(
            $db: $db,
            $table: $db.exams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StudentsTableOrderingComposer get studentId {
    final $$StudentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.students,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableOrderingComposer(
            $db: $db,
            $table: $db.students,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AnswerKeyVersionsTableOrderingComposer get keyVersionId {
    final $$AnswerKeyVersionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.keyVersionId,
      referencedTable: $db.answerKeyVersions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnswerKeyVersionsTableOrderingComposer(
            $db: $db,
            $table: $db.answerKeyVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ScoringRunsTableOrderingComposer get scoringRunId {
    final $$ScoringRunsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scoringRunId,
      referencedTable: $db.scoringRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoringRunsTableOrderingComposer(
            $db: $db,
            $table: $db.scoringRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ResultsTableAnnotationComposer
    extends Composer<_$AppDb, $ResultsTable> {
  $$ResultsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<double> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<int> get correct =>
      $composableBuilder(column: $table.correct, builder: (column) => column);

  GeneratedColumn<int> get wrong =>
      $composableBuilder(column: $table.wrong, builder: (column) => column);

  GeneratedColumn<int> get unattempted => $composableBuilder(
    column: $table.unattempted,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subjectTotalsJson => $composableBuilder(
    column: $table.subjectTotalsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rank =>
      $composableBuilder(column: $table.rank, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ResultStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get gradedAt =>
      $composableBuilder(column: $table.gradedAt, builder: (column) => column);

  $$ScansTableAnnotationComposer get scanId {
    final $$ScansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scanId,
      referencedTable: $db.scans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScansTableAnnotationComposer(
            $db: $db,
            $table: $db.scans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExamsTableAnnotationComposer get examId {
    final $$ExamsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.examId,
      referencedTable: $db.exams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamsTableAnnotationComposer(
            $db: $db,
            $table: $db.exams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StudentsTableAnnotationComposer get studentId {
    final $$StudentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.students,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableAnnotationComposer(
            $db: $db,
            $table: $db.students,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AnswerKeyVersionsTableAnnotationComposer get keyVersionId {
    final $$AnswerKeyVersionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.keyVersionId,
          referencedTable: $db.answerKeyVersions,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AnswerKeyVersionsTableAnnotationComposer(
                $db: $db,
                $table: $db.answerKeyVersions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$ScoringRunsTableAnnotationComposer get scoringRunId {
    final $$ScoringRunsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scoringRunId,
      referencedTable: $db.scoringRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoringRunsTableAnnotationComposer(
            $db: $db,
            $table: $db.scoringRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ResultsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $ResultsTable,
          Result,
          $$ResultsTableFilterComposer,
          $$ResultsTableOrderingComposer,
          $$ResultsTableAnnotationComposer,
          $$ResultsTableCreateCompanionBuilder,
          $$ResultsTableUpdateCompanionBuilder,
          (Result, $$ResultsTableReferences),
          Result,
          PrefetchHooks Function({
            bool scanId,
            bool examId,
            bool studentId,
            bool keyVersionId,
            bool scoringRunId,
          })
        > {
  $$ResultsTableTableManager(_$AppDb db, $ResultsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ResultsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ResultsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ResultsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String> scanId = const Value.absent(),
                Value<String> examId = const Value.absent(),
                Value<String> studentId = const Value.absent(),
                Value<String> keyVersionId = const Value.absent(),
                Value<String> scoringRunId = const Value.absent(),
                Value<double> total = const Value.absent(),
                Value<int> correct = const Value.absent(),
                Value<int> wrong = const Value.absent(),
                Value<int> unattempted = const Value.absent(),
                Value<String> subjectTotalsJson = const Value.absent(),
                Value<int?> rank = const Value.absent(),
                Value<ResultStatus> status = const Value.absent(),
                Value<DateTime> gradedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ResultsCompanion(
                id: id,
                tenantId: tenantId,
                scanId: scanId,
                examId: examId,
                studentId: studentId,
                keyVersionId: keyVersionId,
                scoringRunId: scoringRunId,
                total: total,
                correct: correct,
                wrong: wrong,
                unattempted: unattempted,
                subjectTotalsJson: subjectTotalsJson,
                rank: rank,
                status: status,
                gradedAt: gradedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String tenantId,
                required String scanId,
                required String examId,
                required String studentId,
                required String keyVersionId,
                required String scoringRunId,
                required double total,
                Value<int> correct = const Value.absent(),
                Value<int> wrong = const Value.absent(),
                Value<int> unattempted = const Value.absent(),
                Value<String> subjectTotalsJson = const Value.absent(),
                Value<int?> rank = const Value.absent(),
                Value<ResultStatus> status = const Value.absent(),
                Value<DateTime> gradedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ResultsCompanion.insert(
                id: id,
                tenantId: tenantId,
                scanId: scanId,
                examId: examId,
                studentId: studentId,
                keyVersionId: keyVersionId,
                scoringRunId: scoringRunId,
                total: total,
                correct: correct,
                wrong: wrong,
                unattempted: unattempted,
                subjectTotalsJson: subjectTotalsJson,
                rank: rank,
                status: status,
                gradedAt: gradedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ResultsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                scanId = false,
                examId = false,
                studentId = false,
                keyVersionId = false,
                scoringRunId = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (scanId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.scanId,
                                    referencedTable: $$ResultsTableReferences
                                        ._scanIdTable(db),
                                    referencedColumn: $$ResultsTableReferences
                                        ._scanIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (examId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.examId,
                                    referencedTable: $$ResultsTableReferences
                                        ._examIdTable(db),
                                    referencedColumn: $$ResultsTableReferences
                                        ._examIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (studentId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.studentId,
                                    referencedTable: $$ResultsTableReferences
                                        ._studentIdTable(db),
                                    referencedColumn: $$ResultsTableReferences
                                        ._studentIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (keyVersionId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.keyVersionId,
                                    referencedTable: $$ResultsTableReferences
                                        ._keyVersionIdTable(db),
                                    referencedColumn: $$ResultsTableReferences
                                        ._keyVersionIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (scoringRunId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.scoringRunId,
                                    referencedTable: $$ResultsTableReferences
                                        ._scoringRunIdTable(db),
                                    referencedColumn: $$ResultsTableReferences
                                        ._scoringRunIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$ResultsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $ResultsTable,
      Result,
      $$ResultsTableFilterComposer,
      $$ResultsTableOrderingComposer,
      $$ResultsTableAnnotationComposer,
      $$ResultsTableCreateCompanionBuilder,
      $$ResultsTableUpdateCompanionBuilder,
      (Result, $$ResultsTableReferences),
      Result,
      PrefetchHooks Function({
        bool scanId,
        bool examId,
        bool studentId,
        bool keyVersionId,
        bool scoringRunId,
      })
    >;
typedef $$ReviewQueueTableCreateCompanionBuilder =
    ReviewQueueCompanion Function({
      Value<String> id,
      required String tenantId,
      required String scanId,
      required String reasonCode,
      Value<String> fieldRefsJson,
      required ReviewSeverity severity,
      Value<String?> resolvedBy,
      Value<DateTime?> resolvedAt,
      Value<String?> correctionJson,
      Value<ReviewOutcome> outcome,
      Value<int> rowid,
    });
typedef $$ReviewQueueTableUpdateCompanionBuilder =
    ReviewQueueCompanion Function({
      Value<String> id,
      Value<String> tenantId,
      Value<String> scanId,
      Value<String> reasonCode,
      Value<String> fieldRefsJson,
      Value<ReviewSeverity> severity,
      Value<String?> resolvedBy,
      Value<DateTime?> resolvedAt,
      Value<String?> correctionJson,
      Value<ReviewOutcome> outcome,
      Value<int> rowid,
    });

final class $$ReviewQueueTableReferences
    extends BaseReferences<_$AppDb, $ReviewQueueTable, ReviewQueueItem> {
  $$ReviewQueueTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ScansTable _scanIdTable(_$AppDb db) =>
      db.scans.createAlias('review_queue__scan_id__scans__id');

  $$ScansTableProcessedTableManager get scanId {
    final $_column = $_itemColumn<String>('scan_id')!;

    final manager = $$ScansTableTableManager(
      $_db,
      $_db.scans,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_scanIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReviewQueueTableFilterComposer
    extends Composer<_$AppDb, $ReviewQueueTable> {
  $$ReviewQueueTableFilterComposer({
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

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reasonCode => $composableBuilder(
    column: $table.reasonCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldRefsJson => $composableBuilder(
    column: $table.fieldRefsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ReviewSeverity, ReviewSeverity, String>
  get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get resolvedBy => $composableBuilder(
    column: $table.resolvedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get resolvedAt =>
      $composableBuilder(
        column: $table.resolvedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get correctionJson => $composableBuilder(
    column: $table.correctionJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ReviewOutcome, ReviewOutcome, String>
  get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$ScansTableFilterComposer get scanId {
    final $$ScansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scanId,
      referencedTable: $db.scans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScansTableFilterComposer(
            $db: $db,
            $table: $db.scans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewQueueTableOrderingComposer
    extends Composer<_$AppDb, $ReviewQueueTable> {
  $$ReviewQueueTableOrderingComposer({
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

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reasonCode => $composableBuilder(
    column: $table.reasonCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldRefsJson => $composableBuilder(
    column: $table.fieldRefsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resolvedBy => $composableBuilder(
    column: $table.resolvedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get correctionJson => $composableBuilder(
    column: $table.correctionJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnOrderings(column),
  );

  $$ScansTableOrderingComposer get scanId {
    final $$ScansTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scanId,
      referencedTable: $db.scans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScansTableOrderingComposer(
            $db: $db,
            $table: $db.scans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewQueueTableAnnotationComposer
    extends Composer<_$AppDb, $ReviewQueueTable> {
  $$ReviewQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get reasonCode => $composableBuilder(
    column: $table.reasonCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fieldRefsJson => $composableBuilder(
    column: $table.fieldRefsJson,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ReviewSeverity, String> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);

  GeneratedColumn<String> get resolvedBy => $composableBuilder(
    column: $table.resolvedBy,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime?, String> get resolvedAt =>
      $composableBuilder(
        column: $table.resolvedAt,
        builder: (column) => column,
      );

  GeneratedColumn<String> get correctionJson => $composableBuilder(
    column: $table.correctionJson,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ReviewOutcome, String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  $$ScansTableAnnotationComposer get scanId {
    final $$ScansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scanId,
      referencedTable: $db.scans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScansTableAnnotationComposer(
            $db: $db,
            $table: $db.scans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewQueueTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $ReviewQueueTable,
          ReviewQueueItem,
          $$ReviewQueueTableFilterComposer,
          $$ReviewQueueTableOrderingComposer,
          $$ReviewQueueTableAnnotationComposer,
          $$ReviewQueueTableCreateCompanionBuilder,
          $$ReviewQueueTableUpdateCompanionBuilder,
          (ReviewQueueItem, $$ReviewQueueTableReferences),
          ReviewQueueItem,
          PrefetchHooks Function({bool scanId})
        > {
  $$ReviewQueueTableTableManager(_$AppDb db, $ReviewQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String> scanId = const Value.absent(),
                Value<String> reasonCode = const Value.absent(),
                Value<String> fieldRefsJson = const Value.absent(),
                Value<ReviewSeverity> severity = const Value.absent(),
                Value<String?> resolvedBy = const Value.absent(),
                Value<DateTime?> resolvedAt = const Value.absent(),
                Value<String?> correctionJson = const Value.absent(),
                Value<ReviewOutcome> outcome = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReviewQueueCompanion(
                id: id,
                tenantId: tenantId,
                scanId: scanId,
                reasonCode: reasonCode,
                fieldRefsJson: fieldRefsJson,
                severity: severity,
                resolvedBy: resolvedBy,
                resolvedAt: resolvedAt,
                correctionJson: correctionJson,
                outcome: outcome,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String tenantId,
                required String scanId,
                required String reasonCode,
                Value<String> fieldRefsJson = const Value.absent(),
                required ReviewSeverity severity,
                Value<String?> resolvedBy = const Value.absent(),
                Value<DateTime?> resolvedAt = const Value.absent(),
                Value<String?> correctionJson = const Value.absent(),
                Value<ReviewOutcome> outcome = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReviewQueueCompanion.insert(
                id: id,
                tenantId: tenantId,
                scanId: scanId,
                reasonCode: reasonCode,
                fieldRefsJson: fieldRefsJson,
                severity: severity,
                resolvedBy: resolvedBy,
                resolvedAt: resolvedAt,
                correctionJson: correctionJson,
                outcome: outcome,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ReviewQueueTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({scanId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (scanId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.scanId,
                                referencedTable: $$ReviewQueueTableReferences
                                    ._scanIdTable(db),
                                referencedColumn: $$ReviewQueueTableReferences
                                    ._scanIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ReviewQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $ReviewQueueTable,
      ReviewQueueItem,
      $$ReviewQueueTableFilterComposer,
      $$ReviewQueueTableOrderingComposer,
      $$ReviewQueueTableAnnotationComposer,
      $$ReviewQueueTableCreateCompanionBuilder,
      $$ReviewQueueTableUpdateCompanionBuilder,
      (ReviewQueueItem, $$ReviewQueueTableReferences),
      ReviewQueueItem,
      PrefetchHooks Function({bool scanId})
    >;
typedef $$ReportJobsTableCreateCompanionBuilder =
    ReportJobsCompanion Function({
      Value<String> id,
      required String tenantId,
      required String examId,
      required ReportJobType type,
      required String format,
      required String paramsJson,
      Value<String?> filePath,
      Value<ReportJobStatus> status,
      Value<DateTime?> generatedAt,
      Value<String?> errorText,
      Value<int> rowid,
    });
typedef $$ReportJobsTableUpdateCompanionBuilder =
    ReportJobsCompanion Function({
      Value<String> id,
      Value<String> tenantId,
      Value<String> examId,
      Value<ReportJobType> type,
      Value<String> format,
      Value<String> paramsJson,
      Value<String?> filePath,
      Value<ReportJobStatus> status,
      Value<DateTime?> generatedAt,
      Value<String?> errorText,
      Value<int> rowid,
    });

final class $$ReportJobsTableReferences
    extends BaseReferences<_$AppDb, $ReportJobsTable, ReportJob> {
  $$ReportJobsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ExamsTable _examIdTable(_$AppDb db) =>
      db.exams.createAlias('report_jobs__exam_id__exams__id');

  $$ExamsTableProcessedTableManager get examId {
    final $_column = $_itemColumn<String>('exam_id')!;

    final manager = $$ExamsTableTableManager(
      $_db,
      $_db.exams,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_examIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReportJobsTableFilterComposer
    extends Composer<_$AppDb, $ReportJobsTable> {
  $$ReportJobsTableFilterComposer({
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

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ReportJobType, ReportJobType, String>
  get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paramsJson => $composableBuilder(
    column: $table.paramsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ReportJobStatus, ReportJobStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String> get generatedAt =>
      $composableBuilder(
        column: $table.generatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get errorText => $composableBuilder(
    column: $table.errorText,
    builder: (column) => ColumnFilters(column),
  );

  $$ExamsTableFilterComposer get examId {
    final $$ExamsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.examId,
      referencedTable: $db.exams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamsTableFilterComposer(
            $db: $db,
            $table: $db.exams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReportJobsTableOrderingComposer
    extends Composer<_$AppDb, $ReportJobsTable> {
  $$ReportJobsTableOrderingComposer({
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

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paramsJson => $composableBuilder(
    column: $table.paramsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorText => $composableBuilder(
    column: $table.errorText,
    builder: (column) => ColumnOrderings(column),
  );

  $$ExamsTableOrderingComposer get examId {
    final $$ExamsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.examId,
      referencedTable: $db.exams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamsTableOrderingComposer(
            $db: $db,
            $table: $db.exams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReportJobsTableAnnotationComposer
    extends Composer<_$AppDb, $ReportJobsTable> {
  $$ReportJobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ReportJobType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<String> get paramsJson => $composableBuilder(
    column: $table.paramsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ReportJobStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, String> get generatedAt =>
      $composableBuilder(
        column: $table.generatedAt,
        builder: (column) => column,
      );

  GeneratedColumn<String> get errorText =>
      $composableBuilder(column: $table.errorText, builder: (column) => column);

  $$ExamsTableAnnotationComposer get examId {
    final $$ExamsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.examId,
      referencedTable: $db.exams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExamsTableAnnotationComposer(
            $db: $db,
            $table: $db.exams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReportJobsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $ReportJobsTable,
          ReportJob,
          $$ReportJobsTableFilterComposer,
          $$ReportJobsTableOrderingComposer,
          $$ReportJobsTableAnnotationComposer,
          $$ReportJobsTableCreateCompanionBuilder,
          $$ReportJobsTableUpdateCompanionBuilder,
          (ReportJob, $$ReportJobsTableReferences),
          ReportJob,
          PrefetchHooks Function({bool examId})
        > {
  $$ReportJobsTableTableManager(_$AppDb db, $ReportJobsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReportJobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReportJobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReportJobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String> examId = const Value.absent(),
                Value<ReportJobType> type = const Value.absent(),
                Value<String> format = const Value.absent(),
                Value<String> paramsJson = const Value.absent(),
                Value<String?> filePath = const Value.absent(),
                Value<ReportJobStatus> status = const Value.absent(),
                Value<DateTime?> generatedAt = const Value.absent(),
                Value<String?> errorText = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReportJobsCompanion(
                id: id,
                tenantId: tenantId,
                examId: examId,
                type: type,
                format: format,
                paramsJson: paramsJson,
                filePath: filePath,
                status: status,
                generatedAt: generatedAt,
                errorText: errorText,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String tenantId,
                required String examId,
                required ReportJobType type,
                required String format,
                required String paramsJson,
                Value<String?> filePath = const Value.absent(),
                Value<ReportJobStatus> status = const Value.absent(),
                Value<DateTime?> generatedAt = const Value.absent(),
                Value<String?> errorText = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReportJobsCompanion.insert(
                id: id,
                tenantId: tenantId,
                examId: examId,
                type: type,
                format: format,
                paramsJson: paramsJson,
                filePath: filePath,
                status: status,
                generatedAt: generatedAt,
                errorText: errorText,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ReportJobsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({examId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (examId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.examId,
                                referencedTable: $$ReportJobsTableReferences
                                    ._examIdTable(db),
                                referencedColumn: $$ReportJobsTableReferences
                                    ._examIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ReportJobsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $ReportJobsTable,
      ReportJob,
      $$ReportJobsTableFilterComposer,
      $$ReportJobsTableOrderingComposer,
      $$ReportJobsTableAnnotationComposer,
      $$ReportJobsTableCreateCompanionBuilder,
      $$ReportJobsTableUpdateCompanionBuilder,
      (ReportJob, $$ReportJobsTableReferences),
      ReportJob,
      PrefetchHooks Function({bool examId})
    >;
typedef $$AuditLogTableCreateCompanionBuilder =
    AuditLogCompanion Function({
      Value<String> id,
      required String tenantId,
      required String entity,
      required String entityId,
      required String action,
      Value<String?> beforeJson,
      Value<String?> afterJson,
      Value<DateTime> at,
      Value<String?> byUser,
      Value<int> rowid,
    });
typedef $$AuditLogTableUpdateCompanionBuilder =
    AuditLogCompanion Function({
      Value<String> id,
      Value<String> tenantId,
      Value<String> entity,
      Value<String> entityId,
      Value<String> action,
      Value<String?> beforeJson,
      Value<String?> afterJson,
      Value<DateTime> at,
      Value<String?> byUser,
      Value<int> rowid,
    });

class $$AuditLogTableFilterComposer extends Composer<_$AppDb, $AuditLogTable> {
  $$AuditLogTableFilterComposer({
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

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
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

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get beforeJson => $composableBuilder(
    column: $table.beforeJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get afterJson => $composableBuilder(
    column: $table.afterJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, String> get at =>
      $composableBuilder(
        column: $table.at,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get byUser => $composableBuilder(
    column: $table.byUser,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AuditLogTableOrderingComposer
    extends Composer<_$AppDb, $AuditLogTable> {
  $$AuditLogTableOrderingComposer({
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

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
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

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get beforeJson => $composableBuilder(
    column: $table.beforeJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get afterJson => $composableBuilder(
    column: $table.afterJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get byUser => $composableBuilder(
    column: $table.byUser,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AuditLogTableAnnotationComposer
    extends Composer<_$AppDb, $AuditLogTable> {
  $$AuditLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get beforeJson => $composableBuilder(
    column: $table.beforeJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get afterJson =>
      $composableBuilder(column: $table.afterJson, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, String> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get byUser =>
      $composableBuilder(column: $table.byUser, builder: (column) => column);
}

class $$AuditLogTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $AuditLogTable,
          AuditLogEntry,
          $$AuditLogTableFilterComposer,
          $$AuditLogTableOrderingComposer,
          $$AuditLogTableAnnotationComposer,
          $$AuditLogTableCreateCompanionBuilder,
          $$AuditLogTableUpdateCompanionBuilder,
          (
            AuditLogEntry,
            BaseReferences<_$AppDb, $AuditLogTable, AuditLogEntry>,
          ),
          AuditLogEntry,
          PrefetchHooks Function()
        > {
  $$AuditLogTableTableManager(_$AppDb db, $AuditLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuditLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuditLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuditLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String> entity = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String?> beforeJson = const Value.absent(),
                Value<String?> afterJson = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<String?> byUser = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuditLogCompanion(
                id: id,
                tenantId: tenantId,
                entity: entity,
                entityId: entityId,
                action: action,
                beforeJson: beforeJson,
                afterJson: afterJson,
                at: at,
                byUser: byUser,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String tenantId,
                required String entity,
                required String entityId,
                required String action,
                Value<String?> beforeJson = const Value.absent(),
                Value<String?> afterJson = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<String?> byUser = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuditLogCompanion.insert(
                id: id,
                tenantId: tenantId,
                entity: entity,
                entityId: entityId,
                action: action,
                beforeJson: beforeJson,
                afterJson: afterJson,
                at: at,
                byUser: byUser,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AuditLogTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $AuditLogTable,
      AuditLogEntry,
      $$AuditLogTableFilterComposer,
      $$AuditLogTableOrderingComposer,
      $$AuditLogTableAnnotationComposer,
      $$AuditLogTableCreateCompanionBuilder,
      $$AuditLogTableUpdateCompanionBuilder,
      (AuditLogEntry, BaseReferences<_$AppDb, $AuditLogTable, AuditLogEntry>),
      AuditLogEntry,
      PrefetchHooks Function()
    >;
typedef $$SyncOutboxTableCreateCompanionBuilder =
    SyncOutboxCompanion Function({
      Value<String> id,
      required String tenantId,
      required String targetTable,
      required String rowId,
      required SyncOp op,
      Value<String> payloadJson,
      Value<int> attempts,
      Value<DateTime?> lastAttemptAt,
      Value<int> rowid,
    });
typedef $$SyncOutboxTableUpdateCompanionBuilder =
    SyncOutboxCompanion Function({
      Value<String> id,
      Value<String> tenantId,
      Value<String> targetTable,
      Value<String> rowId,
      Value<SyncOp> op,
      Value<String> payloadJson,
      Value<int> attempts,
      Value<DateTime?> lastAttemptAt,
      Value<int> rowid,
    });

class $$SyncOutboxTableFilterComposer
    extends Composer<_$AppDb, $SyncOutboxTable> {
  $$SyncOutboxTableFilterComposer({
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

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncOp, SyncOp, String> get op =>
      $composableBuilder(
        column: $table.op,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, String>
  get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$SyncOutboxTableOrderingComposer
    extends Composer<_$AppDb, $SyncOutboxTable> {
  $$SyncOutboxTableOrderingComposer({
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

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get op => $composableBuilder(
    column: $table.op,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncOutboxTableAnnotationComposer
    extends Composer<_$AppDb, $SyncOutboxTable> {
  $$SyncOutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncOp, String> get op =>
      $composableBuilder(column: $table.op, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, String> get lastAttemptAt =>
      $composableBuilder(
        column: $table.lastAttemptAt,
        builder: (column) => column,
      );
}

class $$SyncOutboxTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $SyncOutboxTable,
          SyncOutboxEntry,
          $$SyncOutboxTableFilterComposer,
          $$SyncOutboxTableOrderingComposer,
          $$SyncOutboxTableAnnotationComposer,
          $$SyncOutboxTableCreateCompanionBuilder,
          $$SyncOutboxTableUpdateCompanionBuilder,
          (
            SyncOutboxEntry,
            BaseReferences<_$AppDb, $SyncOutboxTable, SyncOutboxEntry>,
          ),
          SyncOutboxEntry,
          PrefetchHooks Function()
        > {
  $$SyncOutboxTableTableManager(_$AppDb db, $SyncOutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncOutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncOutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncOutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String> targetTable = const Value.absent(),
                Value<String> rowId = const Value.absent(),
                Value<SyncOp> op = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncOutboxCompanion(
                id: id,
                tenantId: tenantId,
                targetTable: targetTable,
                rowId: rowId,
                op: op,
                payloadJson: payloadJson,
                attempts: attempts,
                lastAttemptAt: lastAttemptAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String tenantId,
                required String targetTable,
                required String rowId,
                required SyncOp op,
                Value<String> payloadJson = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncOutboxCompanion.insert(
                id: id,
                tenantId: tenantId,
                targetTable: targetTable,
                rowId: rowId,
                op: op,
                payloadJson: payloadJson,
                attempts: attempts,
                lastAttemptAt: lastAttemptAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncOutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $SyncOutboxTable,
      SyncOutboxEntry,
      $$SyncOutboxTableFilterComposer,
      $$SyncOutboxTableOrderingComposer,
      $$SyncOutboxTableAnnotationComposer,
      $$SyncOutboxTableCreateCompanionBuilder,
      $$SyncOutboxTableUpdateCompanionBuilder,
      (
        SyncOutboxEntry,
        BaseReferences<_$AppDb, $SyncOutboxTable, SyncOutboxEntry>,
      ),
      SyncOutboxEntry,
      PrefetchHooks Function()
    >;

class $AppDbManager {
  final _$AppDb _db;
  $AppDbManager(this._db);
  $$TenantsTableTableManager get tenants =>
      $$TenantsTableTableManager(_db, _db.tenants);
  $$InstitutesTableTableManager get institutes =>
      $$InstitutesTableTableManager(_db, _db.institutes);
  $$StudentsTableTableManager get students =>
      $$StudentsTableTableManager(_db, _db.students);
  $$SheetLayoutsTableTableManager get sheetLayouts =>
      $$SheetLayoutsTableTableManager(_db, _db.sheetLayouts);
  $$ExamsTableTableManager get exams =>
      $$ExamsTableTableManager(_db, _db.exams);
  $$QuestionSetsTableTableManager get questionSets =>
      $$QuestionSetsTableTableManager(_db, _db.questionSets);
  $$ScoringRulesTableTableManager get scoringRules =>
      $$ScoringRulesTableTableManager(_db, _db.scoringRules);
  $$AnswerKeyVersionsTableTableManager get answerKeyVersions =>
      $$AnswerKeyVersionsTableTableManager(_db, _db.answerKeyVersions);
  $$AnswerKeyEntriesTableTableManager get answerKeyEntries =>
      $$AnswerKeyEntriesTableTableManager(_db, _db.answerKeyEntries);
  $$ScansTableTableManager get scans =>
      $$ScansTableTableManager(_db, _db.scans);
  $$BubbleReadsTableTableManager get bubbleReads =>
      $$BubbleReadsTableTableManager(_db, _db.bubbleReads);
  $$ScoringRunsTableTableManager get scoringRuns =>
      $$ScoringRunsTableTableManager(_db, _db.scoringRuns);
  $$ResultsTableTableManager get results =>
      $$ResultsTableTableManager(_db, _db.results);
  $$ReviewQueueTableTableManager get reviewQueue =>
      $$ReviewQueueTableTableManager(_db, _db.reviewQueue);
  $$ReportJobsTableTableManager get reportJobs =>
      $$ReportJobsTableTableManager(_db, _db.reportJobs);
  $$AuditLogTableTableManager get auditLog =>
      $$AuditLogTableTableManager(_db, _db.auditLog);
  $$SyncOutboxTableTableManager get syncOutbox =>
      $$SyncOutboxTableTableManager(_db, _db.syncOutbox);
}
