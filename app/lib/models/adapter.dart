import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:theme_json_converter/theme_json_converter.dart";
import "package:typewriter/models/book.dart";
import 'package:typewriter/widgets/icons.dart';
import "package:typewriter/widgets/inspector/editors/object.dart";

part "adapter.freezed.dart";
part "adapter.g.dart";

/// A generated provider to fetch and cache a list of [Adapter]s.
@riverpod
List<Adapter> adapters(AdaptersRef ref) => ref.watch(bookProvider).adapters;

/// A generated provider to fetch and cache a list of all the [EntryBlueprint]s.
@riverpod
List<EntryBlueprint> entryBlueprints(EntryBlueprintsRef ref) =>
    ref.watch(adaptersProvider).expand((e) => e.entries).toList();

/// A generated provider to fetch and cache a specific [EntryBlueprint] by its [name].
@riverpod
EntryBlueprint? entryBlueprint(EntryBlueprintRef ref, String name) =>
    ref.watch(entryBlueprintsProvider).firstWhereOrNull((e) => e.name == name);

@riverpod
List<String> entryTags(EntryTagsRef ref, String name) => ref.watch(entryBlueprintProvider(name))?.tags ?? [];

@riverpod
Map<String, Modifier> fieldModifiers(FieldModifiersRef ref, String blueprint, String name) {
  return ref.watch(entryBlueprintProvider(blueprint))?.fieldsWithModifier(name) ?? {};
}

@riverpod
List<String> modifierPaths(ModifierPathsRef ref, String blueprint, String name) {
  return ref.watch(fieldModifiersProvider(blueprint, name)).keys.toList();
}

/// A data model that represents an adapter.
@freezed
class Adapter with _$Adapter {
  const factory Adapter({
    required String name,
    required String description,
    required String version,
    required List<EntryBlueprint> entries,
  }) = _Adapter;

  factory Adapter.fromJson(Map<String, dynamic> json) => _$AdapterFromJson(json);
}

/// A data model that represents an entry blueprint.
@freezed
class EntryBlueprint with _$EntryBlueprint {
  const factory EntryBlueprint({
    required String name,
    required String description,
    required ObjectField fields,
    @Default(<String>[]) List<String> tags,
    @ColorConverter() @Default(Colors.grey) Color color,
    @IconConverter() @Default(Icons.help) IconData icon,
  }) = _EntryBlueprint;

  factory EntryBlueprint.fromJson(Map<String, dynamic> json) => _$EntryBlueprintFromJson(json);
}

/// A data model for the fields of an adapter entry.
@Freezed(unionKey: "kind")
class FieldInfo with _$FieldInfo {
  /// A default constructor that should never be used.
  const factory FieldInfo({
    @Default([]) List<Modifier> modifiers,
  }) = _FieldType;

  /// Primitive field type, such as a string or a number.
  const factory FieldInfo.primitive({
    required PrimitiveFieldType type,
    @Default([]) List<Modifier> modifiers,
  }) = PrimitiveField;

  /// Enum field type, such as a list of options.
  @FreezedUnionValue("enum")
  const factory FieldInfo.enumField({
    required List<String> values,
    @Default([]) List<Modifier> modifiers,
  }) = EnumField;

  /// List field type, such as a list of strings.
  const factory FieldInfo.list({
    required FieldInfo type,
    @Default([]) List<Modifier> modifiers,
  }) = ListField;

  /// Map field type, such as a map of strings to strings.
  /// Only strings and enums are supported as keys.
  const factory FieldInfo.map({
    required FieldInfo key,
    required FieldInfo value,
    @Default([]) List<Modifier> modifiers,
  }) = MapField;

  /// Object field type, such as a nested object.
  const factory FieldInfo.object({
    required Map<String, FieldInfo> fields,
    @Default([]) List<Modifier> modifiers,
  }) = ObjectField;

  factory FieldInfo.fromJson(Map<String, dynamic> json) => _$FieldInfoFromJson(json);
}

@freezed
class Modifier with _$Modifier {
  const factory Modifier({
    required String name,
    dynamic data,
  }) = _Modifier;

  factory Modifier.fromJson(Map<String, dynamic> json) => _$ModifierFromJson(json);
}

extension EntryBlueprintExt on EntryBlueprint {
  Map<String, Modifier> fieldsWithModifier(String name) => _fieldsWithModifier(name, "", fields);

  /// Parse through the fields of this entry and return a list of all the fields that have the given modifier with [name].
  Map<String, Modifier> _fieldsWithModifier(String name, String path, FieldInfo info) {
    final fields = {
      if (info.hasModifier(name)) path: info.getModifier(name)!,
    };

    final separator = path.isEmpty ? "" : ".";
    if (info is ObjectField) {
      for (final field in info.fields.entries) {
        fields.addAll(_fieldsWithModifier(name, "$path$separator${field.key}", field.value));
      }
    } else if (info is ListField) {
      fields.addAll(_fieldsWithModifier(name, "$path$separator*", info.type));
    } else if (info is MapField) {
      fields.addAll(_fieldsWithModifier(name, "$path$separator*", info.value));
    }

    return fields;
  }
}

/// Since freezed does not support methods on data models, we have to create a separate extension class.
extension FieldTypeExtension on FieldInfo {
  /// Get the default value for this field type.
  dynamic get defaultValue => when(
        (_) => null,
        primitive: (type, _) => type.defaultValue,
        enumField: (values, _) => values.first,
        list: (type, _) => [],
        map: (key, value, _) => {},
        object: (fields, _) => fields.map((key, value) => MapEntry(key, value.defaultValue)),
      );

  /// If the [ObjectEditor] needs to show a default layout or if a field declares a custom layout.
  bool get hasCustomLayout {
    if (this is ObjectField) {
      return true;
    }
    if (this is ListField) {
      return true;
    }
    if (this is MapField) {
      return true;
    }
    if (this is PrimitiveField && (this as PrimitiveField).type == PrimitiveFieldType.boolean) {
      return true;
    }
    return false;
  }

  Modifier? getModifier(String name) {
    return modifiers.firstWhereOrNull((e) => e.name == name);
  }

  bool hasModifier(String name) {
    return getModifier(name) != null;
  }
}

/// A data model that represents a primitive field type.
enum PrimitiveFieldType {
  boolean(false),
  double(0.0),
  integer(0),
  string(""),
  ;

  /// A constructor that is used to create an instance of the [PrimitiveFieldType] class.
  const PrimitiveFieldType(this.defaultValue);

  /// The default value for this field type.
  final dynamic defaultValue;
}

class IconConverter extends JsonConverter<IconData, String> {
  const IconConverter();

  @override
  IconData fromJson(String json) {
    return icons[json] ?? Icons.question_mark;
  }

  // This should not be used.
  @override
  String toJson(IconData object) {
    throw Exception("Icon data cannot be converted to JSON");
  }
}
