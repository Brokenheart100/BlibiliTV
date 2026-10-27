// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $WatchProgressRowsTable extends WatchProgressRows
    with TableInfo<$WatchProgressRowsTable, WatchProgressRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WatchProgressRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ownerKeyMeta = const VerificationMeta(
    'ownerKey',
  );
  @override
  late final GeneratedColumn<String> ownerKey = GeneratedColumn<String>(
    'owner_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _videoIdMeta = const VerificationMeta(
    'videoId',
  );
  @override
  late final GeneratedColumn<String> videoId = GeneratedColumn<String>(
    'video_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _partIdMeta = const VerificationMeta('partId');
  @override
  late final GeneratedColumn<String> partId = GeneratedColumn<String>(
    'part_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMsMeta = const VerificationMeta(
    'positionMs',
  );
  @override
  late final GeneratedColumn<int> positionMs = GeneratedColumn<int>(
    'position_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    ownerKey,
    videoId,
    partId,
    positionMs,
    durationMs,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'watch_progress_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<WatchProgressRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('owner_key')) {
      context.handle(
        _ownerKeyMeta,
        ownerKey.isAcceptableOrUnknown(data['owner_key']!, _ownerKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerKeyMeta);
    }
    if (data.containsKey('video_id')) {
      context.handle(
        _videoIdMeta,
        videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_videoIdMeta);
    }
    if (data.containsKey('part_id')) {
      context.handle(
        _partIdMeta,
        partId.isAcceptableOrUnknown(data['part_id']!, _partIdMeta),
      );
    } else if (isInserting) {
      context.missing(_partIdMeta);
    }
    if (data.containsKey('position_ms')) {
      context.handle(
        _positionMsMeta,
        positionMs.isAcceptableOrUnknown(data['position_ms']!, _positionMsMeta),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
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
  Set<GeneratedColumn> get $primaryKey => {ownerKey, videoId, partId};
  @override
  WatchProgressRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WatchProgressRow(
      ownerKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_key'],
      )!,
      videoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_id'],
      )!,
      partId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}part_id'],
      )!,
      positionMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position_ms'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $WatchProgressRowsTable createAlias(String alias) {
    return $WatchProgressRowsTable(attachedDatabase, alias);
  }
}

class WatchProgressRow extends DataClass
    implements Insertable<WatchProgressRow> {
  final String ownerKey;
  final String videoId;
  final String partId;
  final int positionMs;
  final int durationMs;
  final DateTime updatedAt;
  const WatchProgressRow({
    required this.ownerKey,
    required this.videoId,
    required this.partId,
    required this.positionMs,
    required this.durationMs,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['owner_key'] = Variable<String>(ownerKey);
    map['video_id'] = Variable<String>(videoId);
    map['part_id'] = Variable<String>(partId);
    map['position_ms'] = Variable<int>(positionMs);
    map['duration_ms'] = Variable<int>(durationMs);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  WatchProgressRowsCompanion toCompanion(bool nullToAbsent) {
    return WatchProgressRowsCompanion(
      ownerKey: Value(ownerKey),
      videoId: Value(videoId),
      partId: Value(partId),
      positionMs: Value(positionMs),
      durationMs: Value(durationMs),
      updatedAt: Value(updatedAt),
    );
  }

  factory WatchProgressRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WatchProgressRow(
      ownerKey: serializer.fromJson<String>(json['ownerKey']),
      videoId: serializer.fromJson<String>(json['videoId']),
      partId: serializer.fromJson<String>(json['partId']),
      positionMs: serializer.fromJson<int>(json['positionMs']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ownerKey': serializer.toJson<String>(ownerKey),
      'videoId': serializer.toJson<String>(videoId),
      'partId': serializer.toJson<String>(partId),
      'positionMs': serializer.toJson<int>(positionMs),
      'durationMs': serializer.toJson<int>(durationMs),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  WatchProgressRow copyWith({
    String? ownerKey,
    String? videoId,
    String? partId,
    int? positionMs,
    int? durationMs,
    DateTime? updatedAt,
  }) => WatchProgressRow(
    ownerKey: ownerKey ?? this.ownerKey,
    videoId: videoId ?? this.videoId,
    partId: partId ?? this.partId,
    positionMs: positionMs ?? this.positionMs,
    durationMs: durationMs ?? this.durationMs,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  WatchProgressRow copyWithCompanion(WatchProgressRowsCompanion data) {
    return WatchProgressRow(
      ownerKey: data.ownerKey.present ? data.ownerKey.value : this.ownerKey,
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      partId: data.partId.present ? data.partId.value : this.partId,
      positionMs: data.positionMs.present
          ? data.positionMs.value
          : this.positionMs,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WatchProgressRow(')
          ..write('ownerKey: $ownerKey, ')
          ..write('videoId: $videoId, ')
          ..write('partId: $partId, ')
          ..write('positionMs: $positionMs, ')
          ..write('durationMs: $durationMs, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(ownerKey, videoId, partId, positionMs, durationMs, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WatchProgressRow &&
          other.ownerKey == this.ownerKey &&
          other.videoId == this.videoId &&
          other.partId == this.partId &&
          other.positionMs == this.positionMs &&
          other.durationMs == this.durationMs &&
          other.updatedAt == this.updatedAt);
}

class WatchProgressRowsCompanion extends UpdateCompanion<WatchProgressRow> {
  final Value<String> ownerKey;
  final Value<String> videoId;
  final Value<String> partId;
  final Value<int> positionMs;
  final Value<int> durationMs;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const WatchProgressRowsCompanion({
    this.ownerKey = const Value.absent(),
    this.videoId = const Value.absent(),
    this.partId = const Value.absent(),
    this.positionMs = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WatchProgressRowsCompanion.insert({
    required String ownerKey,
    required String videoId,
    required String partId,
    this.positionMs = const Value.absent(),
    this.durationMs = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : ownerKey = Value(ownerKey),
       videoId = Value(videoId),
       partId = Value(partId),
       updatedAt = Value(updatedAt);
  static Insertable<WatchProgressRow> custom({
    Expression<String>? ownerKey,
    Expression<String>? videoId,
    Expression<String>? partId,
    Expression<int>? positionMs,
    Expression<int>? durationMs,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ownerKey != null) 'owner_key': ownerKey,
      if (videoId != null) 'video_id': videoId,
      if (partId != null) 'part_id': partId,
      if (positionMs != null) 'position_ms': positionMs,
      if (durationMs != null) 'duration_ms': durationMs,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WatchProgressRowsCompanion copyWith({
    Value<String>? ownerKey,
    Value<String>? videoId,
    Value<String>? partId,
    Value<int>? positionMs,
    Value<int>? durationMs,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return WatchProgressRowsCompanion(
      ownerKey: ownerKey ?? this.ownerKey,
      videoId: videoId ?? this.videoId,
      partId: partId ?? this.partId,
      positionMs: positionMs ?? this.positionMs,
      durationMs: durationMs ?? this.durationMs,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ownerKey.present) {
      map['owner_key'] = Variable<String>(ownerKey.value);
    }
    if (videoId.present) {
      map['video_id'] = Variable<String>(videoId.value);
    }
    if (partId.present) {
      map['part_id'] = Variable<String>(partId.value);
    }
    if (positionMs.present) {
      map['position_ms'] = Variable<int>(positionMs.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WatchProgressRowsCompanion(')
          ..write('ownerKey: $ownerKey, ')
          ..write('videoId: $videoId, ')
          ..write('partId: $partId, ')
          ..write('positionMs: $positionMs, ')
          ..write('durationMs: $durationMs, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SearchEntriesTable extends SearchEntries
    with TableInfo<$SearchEntriesTable, SearchEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SearchEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ownerKeyMeta = const VerificationMeta(
    'ownerKey',
  );
  @override
  late final GeneratedColumn<String> ownerKey = GeneratedColumn<String>(
    'owner_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _queryMeta = const VerificationMeta('query');
  @override
  late final GeneratedColumn<String> query = GeneratedColumn<String>(
    'query',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [ownerKey, query, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'search_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SearchEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('owner_key')) {
      context.handle(
        _ownerKeyMeta,
        ownerKey.isAcceptableOrUnknown(data['owner_key']!, _ownerKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerKeyMeta);
    }
    if (data.containsKey('query')) {
      context.handle(
        _queryMeta,
        query.isAcceptableOrUnknown(data['query']!, _queryMeta),
      );
    } else if (isInserting) {
      context.missing(_queryMeta);
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
  Set<GeneratedColumn> get $primaryKey => {ownerKey, query};
  @override
  SearchEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SearchEntry(
      ownerKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_key'],
      )!,
      query: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}query'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SearchEntriesTable createAlias(String alias) {
    return $SearchEntriesTable(attachedDatabase, alias);
  }
}

class SearchEntry extends DataClass implements Insertable<SearchEntry> {
  final String ownerKey;
  final String query;
  final DateTime updatedAt;
  const SearchEntry({
    required this.ownerKey,
    required this.query,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['owner_key'] = Variable<String>(ownerKey);
    map['query'] = Variable<String>(query);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SearchEntriesCompanion toCompanion(bool nullToAbsent) {
    return SearchEntriesCompanion(
      ownerKey: Value(ownerKey),
      query: Value(query),
      updatedAt: Value(updatedAt),
    );
  }

  factory SearchEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SearchEntry(
      ownerKey: serializer.fromJson<String>(json['ownerKey']),
      query: serializer.fromJson<String>(json['query']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ownerKey': serializer.toJson<String>(ownerKey),
      'query': serializer.toJson<String>(query),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SearchEntry copyWith({
    String? ownerKey,
    String? query,
    DateTime? updatedAt,
  }) => SearchEntry(
    ownerKey: ownerKey ?? this.ownerKey,
    query: query ?? this.query,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SearchEntry copyWithCompanion(SearchEntriesCompanion data) {
    return SearchEntry(
      ownerKey: data.ownerKey.present ? data.ownerKey.value : this.ownerKey,
      query: data.query.present ? data.query.value : this.query,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SearchEntry(')
          ..write('ownerKey: $ownerKey, ')
          ..write('query: $query, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(ownerKey, query, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SearchEntry &&
          other.ownerKey == this.ownerKey &&
          other.query == this.query &&
          other.updatedAt == this.updatedAt);
}

class SearchEntriesCompanion extends UpdateCompanion<SearchEntry> {
  final Value<String> ownerKey;
  final Value<String> query;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SearchEntriesCompanion({
    this.ownerKey = const Value.absent(),
    this.query = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SearchEntriesCompanion.insert({
    required String ownerKey,
    required String query,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : ownerKey = Value(ownerKey),
       query = Value(query),
       updatedAt = Value(updatedAt);
  static Insertable<SearchEntry> custom({
    Expression<String>? ownerKey,
    Expression<String>? query,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ownerKey != null) 'owner_key': ownerKey,
      if (query != null) 'query': query,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SearchEntriesCompanion copyWith({
    Value<String>? ownerKey,
    Value<String>? query,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SearchEntriesCompanion(
      ownerKey: ownerKey ?? this.ownerKey,
      query: query ?? this.query,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ownerKey.present) {
      map['owner_key'] = Variable<String>(ownerKey.value);
    }
    if (query.present) {
      map['query'] = Variable<String>(query.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SearchEntriesCompanion(')
          ..write('ownerKey: $ownerKey, ')
          ..write('query: $query, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HistoryVideosTable extends HistoryVideos
    with TableInfo<$HistoryVideosTable, HistoryVideo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HistoryVideosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ownerKeyMeta = const VerificationMeta(
    'ownerKey',
  );
  @override
  late final GeneratedColumn<String> ownerKey = GeneratedColumn<String>(
    'owner_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _videoIdMeta = const VerificationMeta(
    'videoId',
  );
  @override
  late final GeneratedColumn<String> videoId = GeneratedColumn<String>(
    'video_id',
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
  static const VerificationMeta _creatorMeta = const VerificationMeta(
    'creator',
  );
  @override
  late final GeneratedColumn<String> creator = GeneratedColumn<String>(
    'creator',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coverUrlMeta = const VerificationMeta(
    'coverUrl',
  );
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
    'cover_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _creatorAvatarUrlMeta = const VerificationMeta(
    'creatorAvatarUrl',
  );
  @override
  late final GeneratedColumn<String> creatorAvatarUrl = GeneratedColumn<String>(
    'creator_avatar_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _viewCountMeta = const VerificationMeta(
    'viewCount',
  );
  @override
  late final GeneratedColumn<int> viewCount = GeneratedColumn<int>(
    'view_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    ownerKey,
    videoId,
    title,
    creator,
    coverUrl,
    creatorAvatarUrl,
    durationSeconds,
    viewCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'history_videos';
  @override
  VerificationContext validateIntegrity(
    Insertable<HistoryVideo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('owner_key')) {
      context.handle(
        _ownerKeyMeta,
        ownerKey.isAcceptableOrUnknown(data['owner_key']!, _ownerKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerKeyMeta);
    }
    if (data.containsKey('video_id')) {
      context.handle(
        _videoIdMeta,
        videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_videoIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('creator')) {
      context.handle(
        _creatorMeta,
        creator.isAcceptableOrUnknown(data['creator']!, _creatorMeta),
      );
    } else if (isInserting) {
      context.missing(_creatorMeta);
    }
    if (data.containsKey('cover_url')) {
      context.handle(
        _coverUrlMeta,
        coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta),
      );
    }
    if (data.containsKey('creator_avatar_url')) {
      context.handle(
        _creatorAvatarUrlMeta,
        creatorAvatarUrl.isAcceptableOrUnknown(
          data['creator_avatar_url']!,
          _creatorAvatarUrlMeta,
        ),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationSecondsMeta);
    }
    if (data.containsKey('view_count')) {
      context.handle(
        _viewCountMeta,
        viewCount.isAcceptableOrUnknown(data['view_count']!, _viewCountMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ownerKey, videoId};
  @override
  HistoryVideo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HistoryVideo(
      ownerKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_key'],
      )!,
      videoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      creator: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}creator'],
      )!,
      coverUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_url'],
      ),
      creatorAvatarUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}creator_avatar_url'],
      ),
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      )!,
      viewCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}view_count'],
      )!,
    );
  }

  @override
  $HistoryVideosTable createAlias(String alias) {
    return $HistoryVideosTable(attachedDatabase, alias);
  }
}

class HistoryVideo extends DataClass implements Insertable<HistoryVideo> {
  final String ownerKey;
  final String videoId;
  final String title;
  final String creator;
  final String? coverUrl;
  final String? creatorAvatarUrl;
  final int durationSeconds;
  final int viewCount;
  const HistoryVideo({
    required this.ownerKey,
    required this.videoId,
    required this.title,
    required this.creator,
    this.coverUrl,
    this.creatorAvatarUrl,
    required this.durationSeconds,
    required this.viewCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['owner_key'] = Variable<String>(ownerKey);
    map['video_id'] = Variable<String>(videoId);
    map['title'] = Variable<String>(title);
    map['creator'] = Variable<String>(creator);
    if (!nullToAbsent || coverUrl != null) {
      map['cover_url'] = Variable<String>(coverUrl);
    }
    if (!nullToAbsent || creatorAvatarUrl != null) {
      map['creator_avatar_url'] = Variable<String>(creatorAvatarUrl);
    }
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['view_count'] = Variable<int>(viewCount);
    return map;
  }

  HistoryVideosCompanion toCompanion(bool nullToAbsent) {
    return HistoryVideosCompanion(
      ownerKey: Value(ownerKey),
      videoId: Value(videoId),
      title: Value(title),
      creator: Value(creator),
      coverUrl: coverUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverUrl),
      creatorAvatarUrl: creatorAvatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(creatorAvatarUrl),
      durationSeconds: Value(durationSeconds),
      viewCount: Value(viewCount),
    );
  }

  factory HistoryVideo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HistoryVideo(
      ownerKey: serializer.fromJson<String>(json['ownerKey']),
      videoId: serializer.fromJson<String>(json['videoId']),
      title: serializer.fromJson<String>(json['title']),
      creator: serializer.fromJson<String>(json['creator']),
      coverUrl: serializer.fromJson<String?>(json['coverUrl']),
      creatorAvatarUrl: serializer.fromJson<String?>(json['creatorAvatarUrl']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      viewCount: serializer.fromJson<int>(json['viewCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ownerKey': serializer.toJson<String>(ownerKey),
      'videoId': serializer.toJson<String>(videoId),
      'title': serializer.toJson<String>(title),
      'creator': serializer.toJson<String>(creator),
      'coverUrl': serializer.toJson<String?>(coverUrl),
      'creatorAvatarUrl': serializer.toJson<String?>(creatorAvatarUrl),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'viewCount': serializer.toJson<int>(viewCount),
    };
  }

  HistoryVideo copyWith({
    String? ownerKey,
    String? videoId,
    String? title,
    String? creator,
    Value<String?> coverUrl = const Value.absent(),
    Value<String?> creatorAvatarUrl = const Value.absent(),
    int? durationSeconds,
    int? viewCount,
  }) => HistoryVideo(
    ownerKey: ownerKey ?? this.ownerKey,
    videoId: videoId ?? this.videoId,
    title: title ?? this.title,
    creator: creator ?? this.creator,
    coverUrl: coverUrl.present ? coverUrl.value : this.coverUrl,
    creatorAvatarUrl: creatorAvatarUrl.present
        ? creatorAvatarUrl.value
        : this.creatorAvatarUrl,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    viewCount: viewCount ?? this.viewCount,
  );
  HistoryVideo copyWithCompanion(HistoryVideosCompanion data) {
    return HistoryVideo(
      ownerKey: data.ownerKey.present ? data.ownerKey.value : this.ownerKey,
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      title: data.title.present ? data.title.value : this.title,
      creator: data.creator.present ? data.creator.value : this.creator,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      creatorAvatarUrl: data.creatorAvatarUrl.present
          ? data.creatorAvatarUrl.value
          : this.creatorAvatarUrl,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      viewCount: data.viewCount.present ? data.viewCount.value : this.viewCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HistoryVideo(')
          ..write('ownerKey: $ownerKey, ')
          ..write('videoId: $videoId, ')
          ..write('title: $title, ')
          ..write('creator: $creator, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('creatorAvatarUrl: $creatorAvatarUrl, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('viewCount: $viewCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    ownerKey,
    videoId,
    title,
    creator,
    coverUrl,
    creatorAvatarUrl,
    durationSeconds,
    viewCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HistoryVideo &&
          other.ownerKey == this.ownerKey &&
          other.videoId == this.videoId &&
          other.title == this.title &&
          other.creator == this.creator &&
          other.coverUrl == this.coverUrl &&
          other.creatorAvatarUrl == this.creatorAvatarUrl &&
          other.durationSeconds == this.durationSeconds &&
          other.viewCount == this.viewCount);
}

class HistoryVideosCompanion extends UpdateCompanion<HistoryVideo> {
  final Value<String> ownerKey;
  final Value<String> videoId;
  final Value<String> title;
  final Value<String> creator;
  final Value<String?> coverUrl;
  final Value<String?> creatorAvatarUrl;
  final Value<int> durationSeconds;
  final Value<int> viewCount;
  final Value<int> rowid;
  const HistoryVideosCompanion({
    this.ownerKey = const Value.absent(),
    this.videoId = const Value.absent(),
    this.title = const Value.absent(),
    this.creator = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.creatorAvatarUrl = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.viewCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HistoryVideosCompanion.insert({
    required String ownerKey,
    required String videoId,
    required String title,
    required String creator,
    this.coverUrl = const Value.absent(),
    this.creatorAvatarUrl = const Value.absent(),
    required int durationSeconds,
    this.viewCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : ownerKey = Value(ownerKey),
       videoId = Value(videoId),
       title = Value(title),
       creator = Value(creator),
       durationSeconds = Value(durationSeconds);
  static Insertable<HistoryVideo> custom({
    Expression<String>? ownerKey,
    Expression<String>? videoId,
    Expression<String>? title,
    Expression<String>? creator,
    Expression<String>? coverUrl,
    Expression<String>? creatorAvatarUrl,
    Expression<int>? durationSeconds,
    Expression<int>? viewCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ownerKey != null) 'owner_key': ownerKey,
      if (videoId != null) 'video_id': videoId,
      if (title != null) 'title': title,
      if (creator != null) 'creator': creator,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (creatorAvatarUrl != null) 'creator_avatar_url': creatorAvatarUrl,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (viewCount != null) 'view_count': viewCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HistoryVideosCompanion copyWith({
    Value<String>? ownerKey,
    Value<String>? videoId,
    Value<String>? title,
    Value<String>? creator,
    Value<String?>? coverUrl,
    Value<String?>? creatorAvatarUrl,
    Value<int>? durationSeconds,
    Value<int>? viewCount,
    Value<int>? rowid,
  }) {
    return HistoryVideosCompanion(
      ownerKey: ownerKey ?? this.ownerKey,
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      creator: creator ?? this.creator,
      coverUrl: coverUrl ?? this.coverUrl,
      creatorAvatarUrl: creatorAvatarUrl ?? this.creatorAvatarUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      viewCount: viewCount ?? this.viewCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ownerKey.present) {
      map['owner_key'] = Variable<String>(ownerKey.value);
    }
    if (videoId.present) {
      map['video_id'] = Variable<String>(videoId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (creator.present) {
      map['creator'] = Variable<String>(creator.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (creatorAvatarUrl.present) {
      map['creator_avatar_url'] = Variable<String>(creatorAvatarUrl.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (viewCount.present) {
      map['view_count'] = Variable<int>(viewCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HistoryVideosCompanion(')
          ..write('ownerKey: $ownerKey, ')
          ..write('videoId: $videoId, ')
          ..write('title: $title, ')
          ..write('creator: $creator, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('creatorAvatarUrl: $creatorAvatarUrl, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('viewCount: $viewCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WatchProgressRowsTable watchProgressRows =
      $WatchProgressRowsTable(this);
  late final $SearchEntriesTable searchEntries = $SearchEntriesTable(this);
  late final $HistoryVideosTable historyVideos = $HistoryVideosTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    watchProgressRows,
    searchEntries,
    historyVideos,
  ];
}

typedef $$WatchProgressRowsTableCreateCompanionBuilder =
    WatchProgressRowsCompanion Function({
      required String ownerKey,
      required String videoId,
      required String partId,
      Value<int> positionMs,
      Value<int> durationMs,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$WatchProgressRowsTableUpdateCompanionBuilder =
    WatchProgressRowsCompanion Function({
      Value<String> ownerKey,
      Value<String> videoId,
      Value<String> partId,
      Value<int> positionMs,
      Value<int> durationMs,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$WatchProgressRowsTableFilterComposer
    extends Composer<_$AppDatabase, $WatchProgressRowsTable> {
  $$WatchProgressRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get ownerKey => $composableBuilder(
    column: $table.ownerKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partId => $composableBuilder(
    column: $table.partId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WatchProgressRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $WatchProgressRowsTable> {
  $$WatchProgressRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get ownerKey => $composableBuilder(
    column: $table.ownerKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partId => $composableBuilder(
    column: $table.partId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WatchProgressRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WatchProgressRowsTable> {
  $$WatchProgressRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get ownerKey =>
      $composableBuilder(column: $table.ownerKey, builder: (column) => column);

  GeneratedColumn<String> get videoId =>
      $composableBuilder(column: $table.videoId, builder: (column) => column);

  GeneratedColumn<String> get partId =>
      $composableBuilder(column: $table.partId, builder: (column) => column);

  GeneratedColumn<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$WatchProgressRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WatchProgressRowsTable,
          WatchProgressRow,
          $$WatchProgressRowsTableFilterComposer,
          $$WatchProgressRowsTableOrderingComposer,
          $$WatchProgressRowsTableAnnotationComposer,
          $$WatchProgressRowsTableCreateCompanionBuilder,
          $$WatchProgressRowsTableUpdateCompanionBuilder,
          (
            WatchProgressRow,
            BaseReferences<
              _$AppDatabase,
              $WatchProgressRowsTable,
              WatchProgressRow
            >,
          ),
          WatchProgressRow,
          PrefetchHooks Function()
        > {
  $$WatchProgressRowsTableTableManager(
    _$AppDatabase db,
    $WatchProgressRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WatchProgressRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WatchProgressRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WatchProgressRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> ownerKey = const Value.absent(),
                Value<String> videoId = const Value.absent(),
                Value<String> partId = const Value.absent(),
                Value<int> positionMs = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WatchProgressRowsCompanion(
                ownerKey: ownerKey,
                videoId: videoId,
                partId: partId,
                positionMs: positionMs,
                durationMs: durationMs,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String ownerKey,
                required String videoId,
                required String partId,
                Value<int> positionMs = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => WatchProgressRowsCompanion.insert(
                ownerKey: ownerKey,
                videoId: videoId,
                partId: partId,
                positionMs: positionMs,
                durationMs: durationMs,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WatchProgressRowsTable, WatchProgressRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $WatchProgressRowsTable,
                    WatchProgressRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WatchProgressRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WatchProgressRowsTable,
      WatchProgressRow,
      $$WatchProgressRowsTableFilterComposer,
      $$WatchProgressRowsTableOrderingComposer,
      $$WatchProgressRowsTableAnnotationComposer,
      $$WatchProgressRowsTableCreateCompanionBuilder,
      $$WatchProgressRowsTableUpdateCompanionBuilder,
      (
        WatchProgressRow,
        BaseReferences<
          _$AppDatabase,
          $WatchProgressRowsTable,
          WatchProgressRow
        >,
      ),
      WatchProgressRow,
      PrefetchHooks Function()
    >;
typedef $$SearchEntriesTableCreateCompanionBuilder =
    SearchEntriesCompanion Function({
      required String ownerKey,
      required String query,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$SearchEntriesTableUpdateCompanionBuilder =
    SearchEntriesCompanion Function({
      Value<String> ownerKey,
      Value<String> query,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SearchEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SearchEntriesTable> {
  $$SearchEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get ownerKey => $composableBuilder(
    column: $table.ownerKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get query => $composableBuilder(
    column: $table.query,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SearchEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SearchEntriesTable> {
  $$SearchEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get ownerKey => $composableBuilder(
    column: $table.ownerKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get query => $composableBuilder(
    column: $table.query,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SearchEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SearchEntriesTable> {
  $$SearchEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get ownerKey =>
      $composableBuilder(column: $table.ownerKey, builder: (column) => column);

  GeneratedColumn<String> get query =>
      $composableBuilder(column: $table.query, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SearchEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SearchEntriesTable,
          SearchEntry,
          $$SearchEntriesTableFilterComposer,
          $$SearchEntriesTableOrderingComposer,
          $$SearchEntriesTableAnnotationComposer,
          $$SearchEntriesTableCreateCompanionBuilder,
          $$SearchEntriesTableUpdateCompanionBuilder,
          (
            SearchEntry,
            BaseReferences<_$AppDatabase, $SearchEntriesTable, SearchEntry>,
          ),
          SearchEntry,
          PrefetchHooks Function()
        > {
  $$SearchEntriesTableTableManager(_$AppDatabase db, $SearchEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SearchEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SearchEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SearchEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> ownerKey = const Value.absent(),
                Value<String> query = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SearchEntriesCompanion(
                ownerKey: ownerKey,
                query: query,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String ownerKey,
                required String query,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SearchEntriesCompanion.insert(
                ownerKey: ownerKey,
                query: query,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SearchEntriesTable, SearchEntry>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SearchEntriesTable,
                    SearchEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SearchEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SearchEntriesTable,
      SearchEntry,
      $$SearchEntriesTableFilterComposer,
      $$SearchEntriesTableOrderingComposer,
      $$SearchEntriesTableAnnotationComposer,
      $$SearchEntriesTableCreateCompanionBuilder,
      $$SearchEntriesTableUpdateCompanionBuilder,
      (
        SearchEntry,
        BaseReferences<_$AppDatabase, $SearchEntriesTable, SearchEntry>,
      ),
      SearchEntry,
      PrefetchHooks Function()
    >;
typedef $$HistoryVideosTableCreateCompanionBuilder =
    HistoryVideosCompanion Function({
      required String ownerKey,
      required String videoId,
      required String title,
      required String creator,
      Value<String?> coverUrl,
      Value<String?> creatorAvatarUrl,
      required int durationSeconds,
      Value<int> viewCount,
      Value<int> rowid,
    });
typedef $$HistoryVideosTableUpdateCompanionBuilder =
    HistoryVideosCompanion Function({
      Value<String> ownerKey,
      Value<String> videoId,
      Value<String> title,
      Value<String> creator,
      Value<String?> coverUrl,
      Value<String?> creatorAvatarUrl,
      Value<int> durationSeconds,
      Value<int> viewCount,
      Value<int> rowid,
    });

class $$HistoryVideosTableFilterComposer
    extends Composer<_$AppDatabase, $HistoryVideosTable> {
  $$HistoryVideosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get ownerKey => $composableBuilder(
    column: $table.ownerKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creator => $composableBuilder(
    column: $table.creator,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creatorAvatarUrl => $composableBuilder(
    column: $table.creatorAvatarUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get viewCount => $composableBuilder(
    column: $table.viewCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HistoryVideosTableOrderingComposer
    extends Composer<_$AppDatabase, $HistoryVideosTable> {
  $$HistoryVideosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get ownerKey => $composableBuilder(
    column: $table.ownerKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creator => $composableBuilder(
    column: $table.creator,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creatorAvatarUrl => $composableBuilder(
    column: $table.creatorAvatarUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get viewCount => $composableBuilder(
    column: $table.viewCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HistoryVideosTableAnnotationComposer
    extends Composer<_$AppDatabase, $HistoryVideosTable> {
  $$HistoryVideosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get ownerKey =>
      $composableBuilder(column: $table.ownerKey, builder: (column) => column);

  GeneratedColumn<String> get videoId =>
      $composableBuilder(column: $table.videoId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get creator =>
      $composableBuilder(column: $table.creator, builder: (column) => column);

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<String> get creatorAvatarUrl => $composableBuilder(
    column: $table.creatorAvatarUrl,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get viewCount =>
      $composableBuilder(column: $table.viewCount, builder: (column) => column);
}

class $$HistoryVideosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HistoryVideosTable,
          HistoryVideo,
          $$HistoryVideosTableFilterComposer,
          $$HistoryVideosTableOrderingComposer,
          $$HistoryVideosTableAnnotationComposer,
          $$HistoryVideosTableCreateCompanionBuilder,
          $$HistoryVideosTableUpdateCompanionBuilder,
          (
            HistoryVideo,
            BaseReferences<_$AppDatabase, $HistoryVideosTable, HistoryVideo>,
          ),
          HistoryVideo,
          PrefetchHooks Function()
        > {
  $$HistoryVideosTableTableManager(_$AppDatabase db, $HistoryVideosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HistoryVideosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HistoryVideosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HistoryVideosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> ownerKey = const Value.absent(),
                Value<String> videoId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> creator = const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                Value<String?> creatorAvatarUrl = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<int> viewCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HistoryVideosCompanion(
                ownerKey: ownerKey,
                videoId: videoId,
                title: title,
                creator: creator,
                coverUrl: coverUrl,
                creatorAvatarUrl: creatorAvatarUrl,
                durationSeconds: durationSeconds,
                viewCount: viewCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String ownerKey,
                required String videoId,
                required String title,
                required String creator,
                Value<String?> coverUrl = const Value.absent(),
                Value<String?> creatorAvatarUrl = const Value.absent(),
                required int durationSeconds,
                Value<int> viewCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HistoryVideosCompanion.insert(
                ownerKey: ownerKey,
                videoId: videoId,
                title: title,
                creator: creator,
                coverUrl: coverUrl,
                creatorAvatarUrl: creatorAvatarUrl,
                durationSeconds: durationSeconds,
                viewCount: viewCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HistoryVideosTable, HistoryVideo>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $HistoryVideosTable,
                    HistoryVideo
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HistoryVideosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HistoryVideosTable,
      HistoryVideo,
      $$HistoryVideosTableFilterComposer,
      $$HistoryVideosTableOrderingComposer,
      $$HistoryVideosTableAnnotationComposer,
      $$HistoryVideosTableCreateCompanionBuilder,
      $$HistoryVideosTableUpdateCompanionBuilder,
      (
        HistoryVideo,
        BaseReferences<_$AppDatabase, $HistoryVideosTable, HistoryVideo>,
      ),
      HistoryVideo,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WatchProgressRowsTableTableManager get watchProgressRows =>
      $$WatchProgressRowsTableTableManager(_db, _db.watchProgressRows);
  $$SearchEntriesTableTableManager get searchEntries =>
      $$SearchEntriesTableTableManager(_db, _db.searchEntries);
  $$HistoryVideosTableTableManager get historyVideos =>
      $$HistoryVideosTableTableManager(_db, _db.historyVideos);
}
