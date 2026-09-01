/// Shared column converters and JSON helpers for the drift schema.
///
/// Timestamps are stored as ISO-8601 **TEXT** (UTC) rather than unix ints so
/// the same values round-trip to Postgres/Supabase in phase 2 (plan §4). All
/// UTC ISO-8601 strings also sort chronologically as plain text, which the
/// `ORDER BY captured_at` queries rely on.
library;

import 'dart:convert';

import 'package:drift/drift.dart';

/// `DateTime` ⇄ ISO-8601 UTC TEXT.
class IsoDateTimeConverter extends TypeConverter<DateTime, String> {
  const IsoDateTimeConverter();

  @override
  DateTime fromSql(String fromDb) => DateTime.parse(fromDb);

  @override
  String toSql(DateTime value) => value.toUtc().toIso8601String();
}

/// Nullable-timestamp columns wrap the converter with drift's
/// `NullAwareTypeConverter` so `null` maps to `null` in both directions.
const NullAwareTypeConverter<DateTime, String> nullableIsoDate =
    NullAwareTypeConverter.wrap(IsoDateTimeConverter());

/// Default for `clientDefault`d created-at columns.
String nowIsoUtc() => DateTime.now().toUtc().toIso8601String();

/// Decodes a JSON object column. Const-error safe: a corrupt or non-object
/// payload yields `const {}` instead of throwing — a bad `gate_report_json`
/// must never take the whole scan read path down.
Map<String, Object?> decodeJsonObject(String source) {
  try {
    final Object? decoded = jsonDecode(source);
    if (decoded is Map<String, Object?>) {
      return decoded;
    }
  } on FormatException {
    // Fall through to the safe default.
  }
  return const <String, Object?>{};
}

/// Decodes a JSON array column with the same const-error safety as
/// [decodeJsonObject].
List<Object?> decodeJsonList(String source) {
  try {
    final Object? decoded = jsonDecode(source);
    if (decoded is List<Object?>) {
      return decoded;
    }
  } on FormatException {
    // Fall through to the safe default.
  }
  return const <Object?>[];
}

/// Encodes a JSON object column.
String encodeJsonObject(Map<String, Object?> value) => jsonEncode(value);

/// Encodes a JSON array column.
String encodeJsonList(List<Object?> value) => jsonEncode(value);
