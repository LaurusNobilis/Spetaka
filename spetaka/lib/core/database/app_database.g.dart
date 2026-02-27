// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $FriendsTable extends Friends with TableInfo<$FriendsTable, Friend> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FriendsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mobileMeta = const VerificationMeta('mobile');
  @override
  late final GeneratedColumn<String> mobile = GeneratedColumn<String>(
      'mobile', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
      'tags', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _careScoreMeta =
      const VerificationMeta('careScore');
  @override
  late final GeneratedColumn<double> careScore = GeneratedColumn<double>(
      'care_score', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _isConcernActiveMeta =
      const VerificationMeta('isConcernActive');
  @override
  late final GeneratedColumn<bool> isConcernActive = GeneratedColumn<bool>(
      'is_concern_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_concern_active" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _concernNoteMeta =
      const VerificationMeta('concernNote');
  @override
  late final GeneratedColumn<String> concernNote = GeneratedColumn<String>(
      'concern_note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        mobile,
        tags,
        notes,
        careScore,
        isConcernActive,
        concernNote,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'friends';
  @override
  VerificationContext validateIntegrity(Insertable<Friend> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('mobile')) {
      context.handle(_mobileMeta,
          mobile.isAcceptableOrUnknown(data['mobile']!, _mobileMeta));
    } else if (isInserting) {
      context.missing(_mobileMeta);
    }
    if (data.containsKey('tags')) {
      context.handle(
          _tagsMeta, tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('care_score')) {
      context.handle(_careScoreMeta,
          careScore.isAcceptableOrUnknown(data['care_score']!, _careScoreMeta));
    }
    if (data.containsKey('is_concern_active')) {
      context.handle(
          _isConcernActiveMeta,
          isConcernActive.isAcceptableOrUnknown(
              data['is_concern_active']!, _isConcernActiveMeta));
    }
    if (data.containsKey('concern_note')) {
      context.handle(
          _concernNoteMeta,
          concernNote.isAcceptableOrUnknown(
              data['concern_note']!, _concernNoteMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Friend map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Friend(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      mobile: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mobile'])!,
      tags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      careScore: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}care_score'])!,
      isConcernActive: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}is_concern_active'])!,
      concernNote: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}concern_note']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $FriendsTable createAlias(String alias) {
    return $FriendsTable(attachedDatabase, alias);
  }
}

class Friend extends DataClass implements Insertable<Friend> {
  /// UUID v4 primary key generated in Dart at creation time.
  final String id;

  /// Display name — plaintext; used for search/sort.
  final String name;

  /// Normalised E.164 mobile number — plaintext; required for phone actions.
  final String mobile;

  /// Category tags — plaintext.
  ///
  /// Stored as a stable, explicit serialization format (Story 2.3):
  /// recommended JSON array string (e.g. ["Family","Work"]).
  ///
  /// Null means "no tags".
  final String? tags;

  /// Free-text narrative note — ENCRYPTED at repository layer.
  final String? notes;

  /// Floating-point care score; range [0.0, 1.0]; default 0.0.
  final double careScore;

  /// Whether the concern/préoccupation flag is active; stored as 0/1.
  final bool isConcernActive;

  /// Free-text concern note — ENCRYPTED at repository layer.
  final String? concernNote;

  /// Unix-epoch milliseconds — timezone-independent timestamp.
  final int createdAt;

  /// Unix-epoch milliseconds — updated on every write.
  final int updatedAt;
  const Friend(
      {required this.id,
      required this.name,
      required this.mobile,
      this.tags,
      this.notes,
      required this.careScore,
      required this.isConcernActive,
      this.concernNote,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['mobile'] = Variable<String>(mobile);
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['care_score'] = Variable<double>(careScore);
    map['is_concern_active'] = Variable<bool>(isConcernActive);
    if (!nullToAbsent || concernNote != null) {
      map['concern_note'] = Variable<String>(concernNote);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  FriendsCompanion toCompanion(bool nullToAbsent) {
    return FriendsCompanion(
      id: Value(id),
      name: Value(name),
      mobile: Value(mobile),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      careScore: Value(careScore),
      isConcernActive: Value(isConcernActive),
      concernNote: concernNote == null && nullToAbsent
          ? const Value.absent()
          : Value(concernNote),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Friend.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Friend(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      mobile: serializer.fromJson<String>(json['mobile']),
      tags: serializer.fromJson<String?>(json['tags']),
      notes: serializer.fromJson<String?>(json['notes']),
      careScore: serializer.fromJson<double>(json['careScore']),
      isConcernActive: serializer.fromJson<bool>(json['isConcernActive']),
      concernNote: serializer.fromJson<String?>(json['concernNote']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'mobile': serializer.toJson<String>(mobile),
      'tags': serializer.toJson<String?>(tags),
      'notes': serializer.toJson<String?>(notes),
      'careScore': serializer.toJson<double>(careScore),
      'isConcernActive': serializer.toJson<bool>(isConcernActive),
      'concernNote': serializer.toJson<String?>(concernNote),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Friend copyWith(
          {String? id,
          String? name,
          String? mobile,
          Value<String?> tags = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          double? careScore,
          bool? isConcernActive,
          Value<String?> concernNote = const Value.absent(),
          int? createdAt,
          int? updatedAt}) =>
      Friend(
        id: id ?? this.id,
        name: name ?? this.name,
        mobile: mobile ?? this.mobile,
        tags: tags.present ? tags.value : this.tags,
        notes: notes.present ? notes.value : this.notes,
        careScore: careScore ?? this.careScore,
        isConcernActive: isConcernActive ?? this.isConcernActive,
        concernNote: concernNote.present ? concernNote.value : this.concernNote,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Friend copyWithCompanion(FriendsCompanion data) {
    return Friend(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      mobile: data.mobile.present ? data.mobile.value : this.mobile,
      tags: data.tags.present ? data.tags.value : this.tags,
      notes: data.notes.present ? data.notes.value : this.notes,
      careScore: data.careScore.present ? data.careScore.value : this.careScore,
      isConcernActive: data.isConcernActive.present
          ? data.isConcernActive.value
          : this.isConcernActive,
      concernNote:
          data.concernNote.present ? data.concernNote.value : this.concernNote,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Friend(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('mobile: $mobile, ')
          ..write('tags: $tags, ')
          ..write('notes: $notes, ')
          ..write('careScore: $careScore, ')
          ..write('isConcernActive: $isConcernActive, ')
          ..write('concernNote: $concernNote, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, mobile, tags, notes, careScore,
      isConcernActive, concernNote, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Friend &&
          other.id == this.id &&
          other.name == this.name &&
          other.mobile == this.mobile &&
          other.tags == this.tags &&
          other.notes == this.notes &&
          other.careScore == this.careScore &&
          other.isConcernActive == this.isConcernActive &&
          other.concernNote == this.concernNote &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FriendsCompanion extends UpdateCompanion<Friend> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> mobile;
  final Value<String?> tags;
  final Value<String?> notes;
  final Value<double> careScore;
  final Value<bool> isConcernActive;
  final Value<String?> concernNote;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const FriendsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.mobile = const Value.absent(),
    this.tags = const Value.absent(),
    this.notes = const Value.absent(),
    this.careScore = const Value.absent(),
    this.isConcernActive = const Value.absent(),
    this.concernNote = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FriendsCompanion.insert({
    required String id,
    required String name,
    required String mobile,
    this.tags = const Value.absent(),
    this.notes = const Value.absent(),
    this.careScore = const Value.absent(),
    this.isConcernActive = const Value.absent(),
    this.concernNote = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        mobile = Value(mobile),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Friend> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? mobile,
    Expression<String>? tags,
    Expression<String>? notes,
    Expression<double>? careScore,
    Expression<bool>? isConcernActive,
    Expression<String>? concernNote,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (mobile != null) 'mobile': mobile,
      if (tags != null) 'tags': tags,
      if (notes != null) 'notes': notes,
      if (careScore != null) 'care_score': careScore,
      if (isConcernActive != null) 'is_concern_active': isConcernActive,
      if (concernNote != null) 'concern_note': concernNote,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FriendsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? mobile,
      Value<String?>? tags,
      Value<String?>? notes,
      Value<double>? careScore,
      Value<bool>? isConcernActive,
      Value<String?>? concernNote,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<int>? rowid}) {
    return FriendsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      careScore: careScore ?? this.careScore,
      isConcernActive: isConcernActive ?? this.isConcernActive,
      concernNote: concernNote ?? this.concernNote,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (mobile.present) {
      map['mobile'] = Variable<String>(mobile.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (careScore.present) {
      map['care_score'] = Variable<double>(careScore.value);
    }
    if (isConcernActive.present) {
      map['is_concern_active'] = Variable<bool>(isConcernActive.value);
    }
    if (concernNote.present) {
      map['concern_note'] = Variable<String>(concernNote.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FriendsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('mobile: $mobile, ')
          ..write('tags: $tags, ')
          ..write('notes: $notes, ')
          ..write('careScore: $careScore, ')
          ..write('isConcernActive: $isConcernActive, ')
          ..write('concernNote: $concernNote, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AcquittementsTable extends Acquittements
    with TableInfo<$AcquittementsTable, Acquittement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AcquittementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _friendIdMeta =
      const VerificationMeta('friendId');
  @override
  late final GeneratedColumn<String> friendId = GeneratedColumn<String>(
      'friend_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, friendId, type, note, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'acquittements';
  @override
  VerificationContext validateIntegrity(Insertable<Acquittement> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('friend_id')) {
      context.handle(_friendIdMeta,
          friendId.isAcceptableOrUnknown(data['friend_id']!, _friendIdMeta));
    } else if (isInserting) {
      context.missing(_friendIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Acquittement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Acquittement(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      friendId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}friend_id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $AcquittementsTable createAlias(String alias) {
    return $AcquittementsTable(attachedDatabase, alias);
  }
}

class Acquittement extends DataClass implements Insertable<Acquittement> {
  /// UUID v4 primary key generated in Dart at creation time.
  final String id;

  /// Foreign key reference to [Friends.id].
  final String friendId;

  /// Action type (e.g., 'call', 'sms', 'whatsapp', 'in_person') — plaintext.
  final String type;

  /// Optional free-text note — ENCRYPTED at repository layer.
  final String? note;

  /// Unix-epoch milliseconds — timezone-independent creation timestamp.
  final int createdAt;
  const Acquittement(
      {required this.id,
      required this.friendId,
      required this.type,
      this.note,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['friend_id'] = Variable<String>(friendId);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  AcquittementsCompanion toCompanion(bool nullToAbsent) {
    return AcquittementsCompanion(
      id: Value(id),
      friendId: Value(friendId),
      type: Value(type),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory Acquittement.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Acquittement(
      id: serializer.fromJson<String>(json['id']),
      friendId: serializer.fromJson<String>(json['friendId']),
      type: serializer.fromJson<String>(json['type']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'friendId': serializer.toJson<String>(friendId),
      'type': serializer.toJson<String>(type),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  Acquittement copyWith(
          {String? id,
          String? friendId,
          String? type,
          Value<String?> note = const Value.absent(),
          int? createdAt}) =>
      Acquittement(
        id: id ?? this.id,
        friendId: friendId ?? this.friendId,
        type: type ?? this.type,
        note: note.present ? note.value : this.note,
        createdAt: createdAt ?? this.createdAt,
      );
  Acquittement copyWithCompanion(AcquittementsCompanion data) {
    return Acquittement(
      id: data.id.present ? data.id.value : this.id,
      friendId: data.friendId.present ? data.friendId.value : this.friendId,
      type: data.type.present ? data.type.value : this.type,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Acquittement(')
          ..write('id: $id, ')
          ..write('friendId: $friendId, ')
          ..write('type: $type, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, friendId, type, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Acquittement &&
          other.id == this.id &&
          other.friendId == this.friendId &&
          other.type == this.type &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class AcquittementsCompanion extends UpdateCompanion<Acquittement> {
  final Value<String> id;
  final Value<String> friendId;
  final Value<String> type;
  final Value<String?> note;
  final Value<int> createdAt;
  final Value<int> rowid;
  const AcquittementsCompanion({
    this.id = const Value.absent(),
    this.friendId = const Value.absent(),
    this.type = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AcquittementsCompanion.insert({
    required String id,
    required String friendId,
    required String type,
    this.note = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        friendId = Value(friendId),
        type = Value(type),
        createdAt = Value(createdAt);
  static Insertable<Acquittement> custom({
    Expression<String>? id,
    Expression<String>? friendId,
    Expression<String>? type,
    Expression<String>? note,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (friendId != null) 'friend_id': friendId,
      if (type != null) 'type': type,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AcquittementsCompanion copyWith(
      {Value<String>? id,
      Value<String>? friendId,
      Value<String>? type,
      Value<String?>? note,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return AcquittementsCompanion(
      id: id ?? this.id,
      friendId: friendId ?? this.friendId,
      type: type ?? this.type,
      note: note ?? this.note,
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
    if (friendId.present) {
      map['friend_id'] = Variable<String>(friendId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AcquittementsCompanion(')
          ..write('id: $id, ')
          ..write('friendId: $friendId, ')
          ..write('type: $type, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FriendsTable friends = $FriendsTable(this);
  late final $AcquittementsTable acquittements = $AcquittementsTable(this);
  late final FriendDao friendDao = FriendDao(this as AppDatabase);
  late final EventDao eventDao = EventDao(this as AppDatabase);
  late final AcquittementDao acquittementDao =
      AcquittementDao(this as AppDatabase);
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [friends, acquittements];
}

typedef $$FriendsTableCreateCompanionBuilder = FriendsCompanion Function({
  required String id,
  required String name,
  required String mobile,
  Value<String?> tags,
  Value<String?> notes,
  Value<double> careScore,
  Value<bool> isConcernActive,
  Value<String?> concernNote,
  required int createdAt,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$FriendsTableUpdateCompanionBuilder = FriendsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> mobile,
  Value<String?> tags,
  Value<String?> notes,
  Value<double> careScore,
  Value<bool> isConcernActive,
  Value<String?> concernNote,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int> rowid,
});

class $$FriendsTableFilterComposer
    extends Composer<_$AppDatabase, $FriendsTable> {
  $$FriendsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mobile => $composableBuilder(
      column: $table.mobile, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get careScore => $composableBuilder(
      column: $table.careScore, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isConcernActive => $composableBuilder(
      column: $table.isConcernActive,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get concernNote => $composableBuilder(
      column: $table.concernNote, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$FriendsTableOrderingComposer
    extends Composer<_$AppDatabase, $FriendsTable> {
  $$FriendsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mobile => $composableBuilder(
      column: $table.mobile, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get careScore => $composableBuilder(
      column: $table.careScore, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isConcernActive => $composableBuilder(
      column: $table.isConcernActive,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get concernNote => $composableBuilder(
      column: $table.concernNote, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$FriendsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FriendsTable> {
  $$FriendsTableAnnotationComposer({
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

  GeneratedColumn<String> get mobile =>
      $composableBuilder(column: $table.mobile, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<double> get careScore =>
      $composableBuilder(column: $table.careScore, builder: (column) => column);

  GeneratedColumn<bool> get isConcernActive => $composableBuilder(
      column: $table.isConcernActive, builder: (column) => column);

  GeneratedColumn<String> get concernNote => $composableBuilder(
      column: $table.concernNote, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$FriendsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FriendsTable,
    Friend,
    $$FriendsTableFilterComposer,
    $$FriendsTableOrderingComposer,
    $$FriendsTableAnnotationComposer,
    $$FriendsTableCreateCompanionBuilder,
    $$FriendsTableUpdateCompanionBuilder,
    (Friend, BaseReferences<_$AppDatabase, $FriendsTable, Friend>),
    Friend,
    PrefetchHooks Function()> {
  $$FriendsTableTableManager(_$AppDatabase db, $FriendsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FriendsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FriendsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FriendsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> mobile = const Value.absent(),
            Value<String?> tags = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<double> careScore = const Value.absent(),
            Value<bool> isConcernActive = const Value.absent(),
            Value<String?> concernNote = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FriendsCompanion(
            id: id,
            name: name,
            mobile: mobile,
            tags: tags,
            notes: notes,
            careScore: careScore,
            isConcernActive: isConcernActive,
            concernNote: concernNote,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String mobile,
            Value<String?> tags = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<double> careScore = const Value.absent(),
            Value<bool> isConcernActive = const Value.absent(),
            Value<String?> concernNote = const Value.absent(),
            required int createdAt,
            required int updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              FriendsCompanion.insert(
            id: id,
            name: name,
            mobile: mobile,
            tags: tags,
            notes: notes,
            careScore: careScore,
            isConcernActive: isConcernActive,
            concernNote: concernNote,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FriendsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FriendsTable,
    Friend,
    $$FriendsTableFilterComposer,
    $$FriendsTableOrderingComposer,
    $$FriendsTableAnnotationComposer,
    $$FriendsTableCreateCompanionBuilder,
    $$FriendsTableUpdateCompanionBuilder,
    (Friend, BaseReferences<_$AppDatabase, $FriendsTable, Friend>),
    Friend,
    PrefetchHooks Function()>;
typedef $$AcquittementsTableCreateCompanionBuilder = AcquittementsCompanion
    Function({
  required String id,
  required String friendId,
  required String type,
  Value<String?> note,
  required int createdAt,
  Value<int> rowid,
});
typedef $$AcquittementsTableUpdateCompanionBuilder = AcquittementsCompanion
    Function({
  Value<String> id,
  Value<String> friendId,
  Value<String> type,
  Value<String?> note,
  Value<int> createdAt,
  Value<int> rowid,
});

class $$AcquittementsTableFilterComposer
    extends Composer<_$AppDatabase, $AcquittementsTable> {
  $$AcquittementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get friendId => $composableBuilder(
      column: $table.friendId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$AcquittementsTableOrderingComposer
    extends Composer<_$AppDatabase, $AcquittementsTable> {
  $$AcquittementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get friendId => $composableBuilder(
      column: $table.friendId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$AcquittementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AcquittementsTable> {
  $$AcquittementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get friendId =>
      $composableBuilder(column: $table.friendId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AcquittementsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AcquittementsTable,
    Acquittement,
    $$AcquittementsTableFilterComposer,
    $$AcquittementsTableOrderingComposer,
    $$AcquittementsTableAnnotationComposer,
    $$AcquittementsTableCreateCompanionBuilder,
    $$AcquittementsTableUpdateCompanionBuilder,
    (
      Acquittement,
      BaseReferences<_$AppDatabase, $AcquittementsTable, Acquittement>
    ),
    Acquittement,
    PrefetchHooks Function()> {
  $$AcquittementsTableTableManager(_$AppDatabase db, $AcquittementsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AcquittementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AcquittementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AcquittementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> friendId = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AcquittementsCompanion(
            id: id,
            friendId: friendId,
            type: type,
            note: note,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String friendId,
            required String type,
            Value<String?> note = const Value.absent(),
            required int createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              AcquittementsCompanion.insert(
            id: id,
            friendId: friendId,
            type: type,
            note: note,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AcquittementsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AcquittementsTable,
    Acquittement,
    $$AcquittementsTableFilterComposer,
    $$AcquittementsTableOrderingComposer,
    $$AcquittementsTableAnnotationComposer,
    $$AcquittementsTableCreateCompanionBuilder,
    $$AcquittementsTableUpdateCompanionBuilder,
    (
      Acquittement,
      BaseReferences<_$AppDatabase, $AcquittementsTable, Acquittement>
    ),
    Acquittement,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FriendsTableTableManager get friends =>
      $$FriendsTableTableManager(_db, _db.friends);
  $$AcquittementsTableTableManager get acquittements =>
      $$AcquittementsTableTableManager(_db, _db.acquittements);
}

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod provider that exposes [AppDatabase] to the widget tree.
///
/// The database is closed automatically when the provider is disposed
/// (e.g. when the [ProviderScope] containing it is removed).

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

/// Riverpod provider that exposes [AppDatabase] to the widget tree.
///
/// The database is closed automatically when the provider is disposed
/// (e.g. when the [ProviderScope] containing it is removed).

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// Riverpod provider that exposes [AppDatabase] to the widget tree.
  ///
  /// The database is closed automatically when the provider is disposed
  /// (e.g. when the [ProviderScope] containing it is removed).
  AppDatabaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'appDatabaseProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'59cce38d45eeaba199eddd097d8e149d66f9f3e1';
