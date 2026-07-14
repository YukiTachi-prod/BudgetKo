// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_database.dart';

// ignore_for_file: type=lint
class $AccountsTable extends Accounts with TableInfo<$AccountsTable, Account> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
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
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
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
  static const VerificationMeta _colorHexMeta = const VerificationMeta(
    'colorHex',
  );
  @override
  late final GeneratedColumn<int> colorHex = GeneratedColumn<int>(
    'color_hex',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _initialBalanceMeta = const VerificationMeta(
    'initialBalance',
  );
  @override
  late final GeneratedColumn<double> initialBalance = GeneratedColumn<double>(
    'initial_balance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _currentBalanceMeta = const VerificationMeta(
    'currentBalance',
  );
  @override
  late final GeneratedColumn<double> currentBalance = GeneratedColumn<double>(
    'current_balance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    iconCodePoint,
    colorHex,
    initialBalance,
    currentBalance,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Account> instance, {
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
    if (data.containsKey('color_hex')) {
      context.handle(
        _colorHexMeta,
        colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta),
      );
    } else if (isInserting) {
      context.missing(_colorHexMeta);
    }
    if (data.containsKey('initial_balance')) {
      context.handle(
        _initialBalanceMeta,
        initialBalance.isAcceptableOrUnknown(
          data['initial_balance']!,
          _initialBalanceMeta,
        ),
      );
    }
    if (data.containsKey('current_balance')) {
      context.handle(
        _currentBalanceMeta,
        currentBalance.isAcceptableOrUnknown(
          data['current_balance']!,
          _currentBalanceMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Account map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Account(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      iconCodePoint: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}icon_code_point'],
      )!,
      colorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_hex'],
      )!,
      initialBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}initial_balance'],
      )!,
      currentBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}current_balance'],
      )!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class Account extends DataClass implements Insertable<Account> {
  final int id;
  final String name;
  final int iconCodePoint;
  final int colorHex;
  final double initialBalance;
  final double currentBalance;
  const Account({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.colorHex,
    required this.initialBalance,
    required this.currentBalance,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['icon_code_point'] = Variable<int>(iconCodePoint);
    map['color_hex'] = Variable<int>(colorHex);
    map['initial_balance'] = Variable<double>(initialBalance);
    map['current_balance'] = Variable<double>(currentBalance);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      name: Value(name),
      iconCodePoint: Value(iconCodePoint),
      colorHex: Value(colorHex),
      initialBalance: Value(initialBalance),
      currentBalance: Value(currentBalance),
    );
  }

  factory Account.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Account(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      iconCodePoint: serializer.fromJson<int>(json['iconCodePoint']),
      colorHex: serializer.fromJson<int>(json['colorHex']),
      initialBalance: serializer.fromJson<double>(json['initialBalance']),
      currentBalance: serializer.fromJson<double>(json['currentBalance']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'iconCodePoint': serializer.toJson<int>(iconCodePoint),
      'colorHex': serializer.toJson<int>(colorHex),
      'initialBalance': serializer.toJson<double>(initialBalance),
      'currentBalance': serializer.toJson<double>(currentBalance),
    };
  }

  Account copyWith({
    int? id,
    String? name,
    int? iconCodePoint,
    int? colorHex,
    double? initialBalance,
    double? currentBalance,
  }) => Account(
    id: id ?? this.id,
    name: name ?? this.name,
    iconCodePoint: iconCodePoint ?? this.iconCodePoint,
    colorHex: colorHex ?? this.colorHex,
    initialBalance: initialBalance ?? this.initialBalance,
    currentBalance: currentBalance ?? this.currentBalance,
  );
  Account copyWithCompanion(AccountsCompanion data) {
    return Account(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      iconCodePoint: data.iconCodePoint.present
          ? data.iconCodePoint.value
          : this.iconCodePoint,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      initialBalance: data.initialBalance.present
          ? data.initialBalance.value
          : this.initialBalance,
      currentBalance: data.currentBalance.present
          ? data.currentBalance.value
          : this.currentBalance,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Account(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('iconCodePoint: $iconCodePoint, ')
          ..write('colorHex: $colorHex, ')
          ..write('initialBalance: $initialBalance, ')
          ..write('currentBalance: $currentBalance')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    iconCodePoint,
    colorHex,
    initialBalance,
    currentBalance,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Account &&
          other.id == this.id &&
          other.name == this.name &&
          other.iconCodePoint == this.iconCodePoint &&
          other.colorHex == this.colorHex &&
          other.initialBalance == this.initialBalance &&
          other.currentBalance == this.currentBalance);
}

class AccountsCompanion extends UpdateCompanion<Account> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> iconCodePoint;
  final Value<int> colorHex;
  final Value<double> initialBalance;
  final Value<double> currentBalance;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.iconCodePoint = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.initialBalance = const Value.absent(),
    this.currentBalance = const Value.absent(),
  });
  AccountsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int iconCodePoint,
    required int colorHex,
    this.initialBalance = const Value.absent(),
    this.currentBalance = const Value.absent(),
  }) : name = Value(name),
       iconCodePoint = Value(iconCodePoint),
       colorHex = Value(colorHex);
  static Insertable<Account> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? iconCodePoint,
    Expression<int>? colorHex,
    Expression<double>? initialBalance,
    Expression<double>? currentBalance,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (iconCodePoint != null) 'icon_code_point': iconCodePoint,
      if (colorHex != null) 'color_hex': colorHex,
      if (initialBalance != null) 'initial_balance': initialBalance,
      if (currentBalance != null) 'current_balance': currentBalance,
    });
  }

  AccountsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? iconCodePoint,
    Value<int>? colorHex,
    Value<double>? initialBalance,
    Value<double>? currentBalance,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorHex: colorHex ?? this.colorHex,
      initialBalance: initialBalance ?? this.initialBalance,
      currentBalance: currentBalance ?? this.currentBalance,
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
    if (iconCodePoint.present) {
      map['icon_code_point'] = Variable<int>(iconCodePoint.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<int>(colorHex.value);
    }
    if (initialBalance.present) {
      map['initial_balance'] = Variable<double>(initialBalance.value);
    }
    if (currentBalance.present) {
      map['current_balance'] = Variable<double>(currentBalance.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('iconCodePoint: $iconCodePoint, ')
          ..write('colorHex: $colorHex, ')
          ..write('initialBalance: $initialBalance, ')
          ..write('currentBalance: $currentBalance')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, BudgetCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
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
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
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
  static const VerificationMeta _colorHexMeta = const VerificationMeta(
    'colorHex',
  );
  @override
  late final GeneratedColumn<int> colorHex = GeneratedColumn<int>(
    'color_hex',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isExpenseMeta = const VerificationMeta(
    'isExpense',
  );
  @override
  late final GeneratedColumn<bool> isExpense = GeneratedColumn<bool>(
    'is_expense',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_expense" IN (0, 1))',
    ),
  );
  static const VerificationMeta _monthlyBudgetLimitMeta =
      const VerificationMeta('monthlyBudgetLimit');
  @override
  late final GeneratedColumn<double> monthlyBudgetLimit =
      GeneratedColumn<double>(
        'monthly_budget_limit',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    iconCodePoint,
    colorHex,
    isExpense,
    monthlyBudgetLimit,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<BudgetCategory> instance, {
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
    if (data.containsKey('color_hex')) {
      context.handle(
        _colorHexMeta,
        colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta),
      );
    } else if (isInserting) {
      context.missing(_colorHexMeta);
    }
    if (data.containsKey('is_expense')) {
      context.handle(
        _isExpenseMeta,
        isExpense.isAcceptableOrUnknown(data['is_expense']!, _isExpenseMeta),
      );
    } else if (isInserting) {
      context.missing(_isExpenseMeta);
    }
    if (data.containsKey('monthly_budget_limit')) {
      context.handle(
        _monthlyBudgetLimitMeta,
        monthlyBudgetLimit.isAcceptableOrUnknown(
          data['monthly_budget_limit']!,
          _monthlyBudgetLimitMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BudgetCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BudgetCategory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      iconCodePoint: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}icon_code_point'],
      )!,
      colorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_hex'],
      )!,
      isExpense: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_expense'],
      )!,
      monthlyBudgetLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monthly_budget_limit'],
      ),
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class BudgetCategory extends DataClass implements Insertable<BudgetCategory> {
  final int id;
  final String name;
  final int iconCodePoint;
  final int colorHex;
  final bool isExpense;
  final double? monthlyBudgetLimit;
  const BudgetCategory({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.colorHex,
    required this.isExpense,
    this.monthlyBudgetLimit,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['icon_code_point'] = Variable<int>(iconCodePoint);
    map['color_hex'] = Variable<int>(colorHex);
    map['is_expense'] = Variable<bool>(isExpense);
    if (!nullToAbsent || monthlyBudgetLimit != null) {
      map['monthly_budget_limit'] = Variable<double>(monthlyBudgetLimit);
    }
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      iconCodePoint: Value(iconCodePoint),
      colorHex: Value(colorHex),
      isExpense: Value(isExpense),
      monthlyBudgetLimit: monthlyBudgetLimit == null && nullToAbsent
          ? const Value.absent()
          : Value(monthlyBudgetLimit),
    );
  }

  factory BudgetCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BudgetCategory(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      iconCodePoint: serializer.fromJson<int>(json['iconCodePoint']),
      colorHex: serializer.fromJson<int>(json['colorHex']),
      isExpense: serializer.fromJson<bool>(json['isExpense']),
      monthlyBudgetLimit: serializer.fromJson<double?>(
        json['monthlyBudgetLimit'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'iconCodePoint': serializer.toJson<int>(iconCodePoint),
      'colorHex': serializer.toJson<int>(colorHex),
      'isExpense': serializer.toJson<bool>(isExpense),
      'monthlyBudgetLimit': serializer.toJson<double?>(monthlyBudgetLimit),
    };
  }

  BudgetCategory copyWith({
    int? id,
    String? name,
    int? iconCodePoint,
    int? colorHex,
    bool? isExpense,
    Value<double?> monthlyBudgetLimit = const Value.absent(),
  }) => BudgetCategory(
    id: id ?? this.id,
    name: name ?? this.name,
    iconCodePoint: iconCodePoint ?? this.iconCodePoint,
    colorHex: colorHex ?? this.colorHex,
    isExpense: isExpense ?? this.isExpense,
    monthlyBudgetLimit: monthlyBudgetLimit.present
        ? monthlyBudgetLimit.value
        : this.monthlyBudgetLimit,
  );
  BudgetCategory copyWithCompanion(CategoriesCompanion data) {
    return BudgetCategory(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      iconCodePoint: data.iconCodePoint.present
          ? data.iconCodePoint.value
          : this.iconCodePoint,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      isExpense: data.isExpense.present ? data.isExpense.value : this.isExpense,
      monthlyBudgetLimit: data.monthlyBudgetLimit.present
          ? data.monthlyBudgetLimit.value
          : this.monthlyBudgetLimit,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BudgetCategory(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('iconCodePoint: $iconCodePoint, ')
          ..write('colorHex: $colorHex, ')
          ..write('isExpense: $isExpense, ')
          ..write('monthlyBudgetLimit: $monthlyBudgetLimit')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    iconCodePoint,
    colorHex,
    isExpense,
    monthlyBudgetLimit,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BudgetCategory &&
          other.id == this.id &&
          other.name == this.name &&
          other.iconCodePoint == this.iconCodePoint &&
          other.colorHex == this.colorHex &&
          other.isExpense == this.isExpense &&
          other.monthlyBudgetLimit == this.monthlyBudgetLimit);
}

class CategoriesCompanion extends UpdateCompanion<BudgetCategory> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> iconCodePoint;
  final Value<int> colorHex;
  final Value<bool> isExpense;
  final Value<double?> monthlyBudgetLimit;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.iconCodePoint = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.isExpense = const Value.absent(),
    this.monthlyBudgetLimit = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int iconCodePoint,
    required int colorHex,
    required bool isExpense,
    this.monthlyBudgetLimit = const Value.absent(),
  }) : name = Value(name),
       iconCodePoint = Value(iconCodePoint),
       colorHex = Value(colorHex),
       isExpense = Value(isExpense);
  static Insertable<BudgetCategory> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? iconCodePoint,
    Expression<int>? colorHex,
    Expression<bool>? isExpense,
    Expression<double>? monthlyBudgetLimit,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (iconCodePoint != null) 'icon_code_point': iconCodePoint,
      if (colorHex != null) 'color_hex': colorHex,
      if (isExpense != null) 'is_expense': isExpense,
      if (monthlyBudgetLimit != null)
        'monthly_budget_limit': monthlyBudgetLimit,
    });
  }

  CategoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? iconCodePoint,
    Value<int>? colorHex,
    Value<bool>? isExpense,
    Value<double?>? monthlyBudgetLimit,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorHex: colorHex ?? this.colorHex,
      isExpense: isExpense ?? this.isExpense,
      monthlyBudgetLimit: monthlyBudgetLimit ?? this.monthlyBudgetLimit,
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
    if (iconCodePoint.present) {
      map['icon_code_point'] = Variable<int>(iconCodePoint.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<int>(colorHex.value);
    }
    if (isExpense.present) {
      map['is_expense'] = Variable<bool>(isExpense.value);
    }
    if (monthlyBudgetLimit.present) {
      map['monthly_budget_limit'] = Variable<double>(monthlyBudgetLimit.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('iconCodePoint: $iconCodePoint, ')
          ..write('colorHex: $colorHex, ')
          ..write('isExpense: $isExpense, ')
          ..write('monthlyBudgetLimit: $monthlyBudgetLimit')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, LedgerTransaction> {
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
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transactionTypeMeta = const VerificationMeta(
    'transactionType',
  );
  @override
  late final GeneratedColumn<int> transactionType = GeneratedColumn<int>(
    'transaction_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromAccountIdMeta = const VerificationMeta(
    'fromAccountId',
  );
  @override
  late final GeneratedColumn<int> fromAccountId = GeneratedColumn<int>(
    'from_account_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toAccountIdMeta = const VerificationMeta(
    'toAccountId',
  );
  @override
  late final GeneratedColumn<int> toAccountId = GeneratedColumn<int>(
    'to_account_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    amount,
    date,
    notes,
    transactionType,
    fromAccountId,
    toAccountId,
    categoryId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<LedgerTransaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('transaction_type')) {
      context.handle(
        _transactionTypeMeta,
        transactionType.isAcceptableOrUnknown(
          data['transaction_type']!,
          _transactionTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionTypeMeta);
    }
    if (data.containsKey('from_account_id')) {
      context.handle(
        _fromAccountIdMeta,
        fromAccountId.isAcceptableOrUnknown(
          data['from_account_id']!,
          _fromAccountIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fromAccountIdMeta);
    }
    if (data.containsKey('to_account_id')) {
      context.handle(
        _toAccountIdMeta,
        toAccountId.isAcceptableOrUnknown(
          data['to_account_id']!,
          _toAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LedgerTransaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LedgerTransaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      transactionType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}transaction_type'],
      )!,
      fromAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}from_account_id'],
      )!,
      toAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}to_account_id'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      ),
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class LedgerTransaction extends DataClass
    implements Insertable<LedgerTransaction> {
  final int id;
  final double amount;
  final DateTime date;
  final String? notes;
  final int transactionType;
  final int fromAccountId;
  final int? toAccountId;
  final int? categoryId;
  const LedgerTransaction({
    required this.id,
    required this.amount,
    required this.date,
    this.notes,
    required this.transactionType,
    required this.fromAccountId,
    this.toAccountId,
    this.categoryId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['amount'] = Variable<double>(amount);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['transaction_type'] = Variable<int>(transactionType);
    map['from_account_id'] = Variable<int>(fromAccountId);
    if (!nullToAbsent || toAccountId != null) {
      map['to_account_id'] = Variable<int>(toAccountId);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      amount: Value(amount),
      date: Value(date),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      transactionType: Value(transactionType),
      fromAccountId: Value(fromAccountId),
      toAccountId: toAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(toAccountId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
    );
  }

  factory LedgerTransaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LedgerTransaction(
      id: serializer.fromJson<int>(json['id']),
      amount: serializer.fromJson<double>(json['amount']),
      date: serializer.fromJson<DateTime>(json['date']),
      notes: serializer.fromJson<String?>(json['notes']),
      transactionType: serializer.fromJson<int>(json['transactionType']),
      fromAccountId: serializer.fromJson<int>(json['fromAccountId']),
      toAccountId: serializer.fromJson<int?>(json['toAccountId']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'amount': serializer.toJson<double>(amount),
      'date': serializer.toJson<DateTime>(date),
      'notes': serializer.toJson<String?>(notes),
      'transactionType': serializer.toJson<int>(transactionType),
      'fromAccountId': serializer.toJson<int>(fromAccountId),
      'toAccountId': serializer.toJson<int?>(toAccountId),
      'categoryId': serializer.toJson<int?>(categoryId),
    };
  }

  LedgerTransaction copyWith({
    int? id,
    double? amount,
    DateTime? date,
    Value<String?> notes = const Value.absent(),
    int? transactionType,
    int? fromAccountId,
    Value<int?> toAccountId = const Value.absent(),
    Value<int?> categoryId = const Value.absent(),
  }) => LedgerTransaction(
    id: id ?? this.id,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    notes: notes.present ? notes.value : this.notes,
    transactionType: transactionType ?? this.transactionType,
    fromAccountId: fromAccountId ?? this.fromAccountId,
    toAccountId: toAccountId.present ? toAccountId.value : this.toAccountId,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
  );
  LedgerTransaction copyWithCompanion(TransactionsCompanion data) {
    return LedgerTransaction(
      id: data.id.present ? data.id.value : this.id,
      amount: data.amount.present ? data.amount.value : this.amount,
      date: data.date.present ? data.date.value : this.date,
      notes: data.notes.present ? data.notes.value : this.notes,
      transactionType: data.transactionType.present
          ? data.transactionType.value
          : this.transactionType,
      fromAccountId: data.fromAccountId.present
          ? data.fromAccountId.value
          : this.fromAccountId,
      toAccountId: data.toAccountId.present
          ? data.toAccountId.value
          : this.toAccountId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LedgerTransaction(')
          ..write('id: $id, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('notes: $notes, ')
          ..write('transactionType: $transactionType, ')
          ..write('fromAccountId: $fromAccountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('categoryId: $categoryId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    amount,
    date,
    notes,
    transactionType,
    fromAccountId,
    toAccountId,
    categoryId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LedgerTransaction &&
          other.id == this.id &&
          other.amount == this.amount &&
          other.date == this.date &&
          other.notes == this.notes &&
          other.transactionType == this.transactionType &&
          other.fromAccountId == this.fromAccountId &&
          other.toAccountId == this.toAccountId &&
          other.categoryId == this.categoryId);
}

class TransactionsCompanion extends UpdateCompanion<LedgerTransaction> {
  final Value<int> id;
  final Value<double> amount;
  final Value<DateTime> date;
  final Value<String?> notes;
  final Value<int> transactionType;
  final Value<int> fromAccountId;
  final Value<int?> toAccountId;
  final Value<int?> categoryId;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.amount = const Value.absent(),
    this.date = const Value.absent(),
    this.notes = const Value.absent(),
    this.transactionType = const Value.absent(),
    this.fromAccountId = const Value.absent(),
    this.toAccountId = const Value.absent(),
    this.categoryId = const Value.absent(),
  });
  TransactionsCompanion.insert({
    this.id = const Value.absent(),
    required double amount,
    required DateTime date,
    this.notes = const Value.absent(),
    required int transactionType,
    required int fromAccountId,
    this.toAccountId = const Value.absent(),
    this.categoryId = const Value.absent(),
  }) : amount = Value(amount),
       date = Value(date),
       transactionType = Value(transactionType),
       fromAccountId = Value(fromAccountId);
  static Insertable<LedgerTransaction> custom({
    Expression<int>? id,
    Expression<double>? amount,
    Expression<DateTime>? date,
    Expression<String>? notes,
    Expression<int>? transactionType,
    Expression<int>? fromAccountId,
    Expression<int>? toAccountId,
    Expression<int>? categoryId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (amount != null) 'amount': amount,
      if (date != null) 'date': date,
      if (notes != null) 'notes': notes,
      if (transactionType != null) 'transaction_type': transactionType,
      if (fromAccountId != null) 'from_account_id': fromAccountId,
      if (toAccountId != null) 'to_account_id': toAccountId,
      if (categoryId != null) 'category_id': categoryId,
    });
  }

  TransactionsCompanion copyWith({
    Value<int>? id,
    Value<double>? amount,
    Value<DateTime>? date,
    Value<String?>? notes,
    Value<int>? transactionType,
    Value<int>? fromAccountId,
    Value<int?>? toAccountId,
    Value<int?>? categoryId,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      transactionType: transactionType ?? this.transactionType,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (transactionType.present) {
      map['transaction_type'] = Variable<int>(transactionType.value);
    }
    if (fromAccountId.present) {
      map['from_account_id'] = Variable<int>(fromAccountId.value);
    }
    if (toAccountId.present) {
      map['to_account_id'] = Variable<int>(toAccountId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('notes: $notes, ')
          ..write('transactionType: $transactionType, ')
          ..write('fromAccountId: $fromAccountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('categoryId: $categoryId')
          ..write(')'))
        .toString();
  }
}

abstract class _$BudgetDatabase extends GeneratedDatabase {
  _$BudgetDatabase(QueryExecutor e) : super(e);
  $BudgetDatabaseManager get managers => $BudgetDatabaseManager(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    accounts,
    categories,
    transactions,
  ];
}

typedef $$AccountsTableCreateCompanionBuilder =
    AccountsCompanion Function({
      Value<int> id,
      required String name,
      required int iconCodePoint,
      required int colorHex,
      Value<double> initialBalance,
      Value<double> currentBalance,
    });
typedef $$AccountsTableUpdateCompanionBuilder =
    AccountsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> iconCodePoint,
      Value<int> colorHex,
      Value<double> initialBalance,
      Value<double> currentBalance,
    });

class $$AccountsTableFilterComposer
    extends Composer<_$BudgetDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
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

  ColumnFilters<int> get iconCodePoint => $composableBuilder(
    column: $table.iconCodePoint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get initialBalance => $composableBuilder(
    column: $table.initialBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get currentBalance => $composableBuilder(
    column: $table.currentBalance,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AccountsTableOrderingComposer
    extends Composer<_$BudgetDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
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

  ColumnOrderings<int> get iconCodePoint => $composableBuilder(
    column: $table.iconCodePoint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get initialBalance => $composableBuilder(
    column: $table.initialBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get currentBalance => $composableBuilder(
    column: $table.currentBalance,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$BudgetDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
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

  GeneratedColumn<int> get iconCodePoint => $composableBuilder(
    column: $table.iconCodePoint,
    builder: (column) => column,
  );

  GeneratedColumn<int> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<double> get initialBalance => $composableBuilder(
    column: $table.initialBalance,
    builder: (column) => column,
  );

  GeneratedColumn<double> get currentBalance => $composableBuilder(
    column: $table.currentBalance,
    builder: (column) => column,
  );
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$BudgetDatabase,
          $AccountsTable,
          Account,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (Account, BaseReferences<_$BudgetDatabase, $AccountsTable, Account>),
          Account,
          PrefetchHooks Function()
        > {
  $$AccountsTableTableManager(_$BudgetDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> iconCodePoint = const Value.absent(),
                Value<int> colorHex = const Value.absent(),
                Value<double> initialBalance = const Value.absent(),
                Value<double> currentBalance = const Value.absent(),
              }) => AccountsCompanion(
                id: id,
                name: name,
                iconCodePoint: iconCodePoint,
                colorHex: colorHex,
                initialBalance: initialBalance,
                currentBalance: currentBalance,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int iconCodePoint,
                required int colorHex,
                Value<double> initialBalance = const Value.absent(),
                Value<double> currentBalance = const Value.absent(),
              }) => AccountsCompanion.insert(
                id: id,
                name: name,
                iconCodePoint: iconCodePoint,
                colorHex: colorHex,
                initialBalance: initialBalance,
                currentBalance: currentBalance,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$BudgetDatabase,
      $AccountsTable,
      Account,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (Account, BaseReferences<_$BudgetDatabase, $AccountsTable, Account>),
      Account,
      PrefetchHooks Function()
    >;
typedef $$CategoriesTableCreateCompanionBuilder =
    CategoriesCompanion Function({
      Value<int> id,
      required String name,
      required int iconCodePoint,
      required int colorHex,
      required bool isExpense,
      Value<double?> monthlyBudgetLimit,
    });
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> iconCodePoint,
      Value<int> colorHex,
      Value<bool> isExpense,
      Value<double?> monthlyBudgetLimit,
    });

class $$CategoriesTableFilterComposer
    extends Composer<_$BudgetDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
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

  ColumnFilters<int> get iconCodePoint => $composableBuilder(
    column: $table.iconCodePoint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isExpense => $composableBuilder(
    column: $table.isExpense,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get monthlyBudgetLimit => $composableBuilder(
    column: $table.monthlyBudgetLimit,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$BudgetDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
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

  ColumnOrderings<int> get iconCodePoint => $composableBuilder(
    column: $table.iconCodePoint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isExpense => $composableBuilder(
    column: $table.isExpense,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get monthlyBudgetLimit => $composableBuilder(
    column: $table.monthlyBudgetLimit,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$BudgetDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
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

  GeneratedColumn<int> get iconCodePoint => $composableBuilder(
    column: $table.iconCodePoint,
    builder: (column) => column,
  );

  GeneratedColumn<int> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<bool> get isExpense =>
      $composableBuilder(column: $table.isExpense, builder: (column) => column);

  GeneratedColumn<double> get monthlyBudgetLimit => $composableBuilder(
    column: $table.monthlyBudgetLimit,
    builder: (column) => column,
  );
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$BudgetDatabase,
          $CategoriesTable,
          BudgetCategory,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (
            BudgetCategory,
            BaseReferences<_$BudgetDatabase, $CategoriesTable, BudgetCategory>,
          ),
          BudgetCategory,
          PrefetchHooks Function()
        > {
  $$CategoriesTableTableManager(_$BudgetDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> iconCodePoint = const Value.absent(),
                Value<int> colorHex = const Value.absent(),
                Value<bool> isExpense = const Value.absent(),
                Value<double?> monthlyBudgetLimit = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                name: name,
                iconCodePoint: iconCodePoint,
                colorHex: colorHex,
                isExpense: isExpense,
                monthlyBudgetLimit: monthlyBudgetLimit,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int iconCodePoint,
                required int colorHex,
                required bool isExpense,
                Value<double?> monthlyBudgetLimit = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                name: name,
                iconCodePoint: iconCodePoint,
                colorHex: colorHex,
                isExpense: isExpense,
                monthlyBudgetLimit: monthlyBudgetLimit,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$BudgetDatabase,
      $CategoriesTable,
      BudgetCategory,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (
        BudgetCategory,
        BaseReferences<_$BudgetDatabase, $CategoriesTable, BudgetCategory>,
      ),
      BudgetCategory,
      PrefetchHooks Function()
    >;
typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> id,
      required double amount,
      required DateTime date,
      Value<String?> notes,
      required int transactionType,
      required int fromAccountId,
      Value<int?> toAccountId,
      Value<int?> categoryId,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> id,
      Value<double> amount,
      Value<DateTime> date,
      Value<String?> notes,
      Value<int> transactionType,
      Value<int> fromAccountId,
      Value<int?> toAccountId,
      Value<int?> categoryId,
    });

class $$TransactionsTableFilterComposer
    extends Composer<_$BudgetDatabase, $TransactionsTable> {
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

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fromAccountId => $composableBuilder(
    column: $table.fromAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get toAccountId => $composableBuilder(
    column: $table.toAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$BudgetDatabase, $TransactionsTable> {
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

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fromAccountId => $composableBuilder(
    column: $table.fromAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get toAccountId => $composableBuilder(
    column: $table.toAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$BudgetDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fromAccountId => $composableBuilder(
    column: $table.fromAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get toAccountId => $composableBuilder(
    column: $table.toAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$BudgetDatabase,
          $TransactionsTable,
          LedgerTransaction,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (
            LedgerTransaction,
            BaseReferences<
              _$BudgetDatabase,
              $TransactionsTable,
              LedgerTransaction
            >,
          ),
          LedgerTransaction,
          PrefetchHooks Function()
        > {
  $$TransactionsTableTableManager(_$BudgetDatabase db, $TransactionsTable table)
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
                Value<double> amount = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> transactionType = const Value.absent(),
                Value<int> fromAccountId = const Value.absent(),
                Value<int?> toAccountId = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                amount: amount,
                date: date,
                notes: notes,
                transactionType: transactionType,
                fromAccountId: fromAccountId,
                toAccountId: toAccountId,
                categoryId: categoryId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required double amount,
                required DateTime date,
                Value<String?> notes = const Value.absent(),
                required int transactionType,
                required int fromAccountId,
                Value<int?> toAccountId = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                amount: amount,
                date: date,
                notes: notes,
                transactionType: transactionType,
                fromAccountId: fromAccountId,
                toAccountId: toAccountId,
                categoryId: categoryId,
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
      _$BudgetDatabase,
      $TransactionsTable,
      LedgerTransaction,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (
        LedgerTransaction,
        BaseReferences<_$BudgetDatabase, $TransactionsTable, LedgerTransaction>,
      ),
      LedgerTransaction,
      PrefetchHooks Function()
    >;

class $BudgetDatabaseManager {
  final _$BudgetDatabase _db;
  $BudgetDatabaseManager(this._db);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
}
