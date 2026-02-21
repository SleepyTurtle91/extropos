// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarInventoryCollection on Isar {
  IsarCollection<IsarInventory> get isarInventorys => this.collection();
}

const IsarInventorySchema = CollectionSchema(
  name: r'IsarInventory',
  id: -3530786713037431178,
  properties: {
    r'backendId': PropertySchema(
      id: 0,
      name: r'backendId',
      type: IsarType.string,
    ),
    r'costPerUnit': PropertySchema(
      id: 1,
      name: r'costPerUnit',
      type: IsarType.double,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.long,
    ),
    r'currentQuantity': PropertySchema(
      id: 3,
      name: r'currentQuantity',
      type: IsarType.double,
    ),
    r'inventoryValue': PropertySchema(
      id: 4,
      name: r'inventoryValue',
      type: IsarType.double,
    ),
    r'isSynced': PropertySchema(
      id: 5,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'lastCountedAt': PropertySchema(
      id: 6,
      name: r'lastCountedAt',
      type: IsarType.long,
    ),
    r'lastSyncedAt': PropertySchema(
      id: 7,
      name: r'lastSyncedAt',
      type: IsarType.long,
    ),
    r'maxStockLevel': PropertySchema(
      id: 8,
      name: r'maxStockLevel',
      type: IsarType.double,
    ),
    r'minStockLevel': PropertySchema(
      id: 9,
      name: r'minStockLevel',
      type: IsarType.double,
    ),
    r'movementsJson': PropertySchema(
      id: 10,
      name: r'movementsJson',
      type: IsarType.string,
    ),
    r'productId': PropertySchema(
      id: 11,
      name: r'productId',
      type: IsarType.string,
    ),
    r'productName': PropertySchema(
      id: 12,
      name: r'productName',
      type: IsarType.string,
    ),
    r'reorderQuantity': PropertySchema(
      id: 13,
      name: r'reorderQuantity',
      type: IsarType.double,
    ),
    r'sku': PropertySchema(
      id: 14,
      name: r'sku',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 15,
      name: r'updatedAt',
      type: IsarType.long,
    ),
    r'warehouseLocation': PropertySchema(
      id: 16,
      name: r'warehouseLocation',
      type: IsarType.string,
    )
  },
  estimateSize: _isarInventoryEstimateSize,
  serialize: _isarInventorySerialize,
  deserialize: _isarInventoryDeserialize,
  deserializeProp: _isarInventoryDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _isarInventoryGetId,
  getLinks: _isarInventoryGetLinks,
  attach: _isarInventoryAttach,
  version: '3.1.0+1',
);

int _isarInventoryEstimateSize(
  IsarInventory object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.backendId.length * 3;
  bytesCount += 3 + object.movementsJson.length * 3;
  bytesCount += 3 + object.productId.length * 3;
  {
    final value = object.productName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.sku;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.warehouseLocation;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _isarInventorySerialize(
  IsarInventory object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.backendId);
  writer.writeDouble(offsets[1], object.costPerUnit);
  writer.writeLong(offsets[2], object.createdAt);
  writer.writeDouble(offsets[3], object.currentQuantity);
  writer.writeDouble(offsets[4], object.inventoryValue);
  writer.writeBool(offsets[5], object.isSynced);
  writer.writeLong(offsets[6], object.lastCountedAt);
  writer.writeLong(offsets[7], object.lastSyncedAt);
  writer.writeDouble(offsets[8], object.maxStockLevel);
  writer.writeDouble(offsets[9], object.minStockLevel);
  writer.writeString(offsets[10], object.movementsJson);
  writer.writeString(offsets[11], object.productId);
  writer.writeString(offsets[12], object.productName);
  writer.writeDouble(offsets[13], object.reorderQuantity);
  writer.writeString(offsets[14], object.sku);
  writer.writeLong(offsets[15], object.updatedAt);
  writer.writeString(offsets[16], object.warehouseLocation);
}

IsarInventory _isarInventoryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarInventory(
    backendId: reader.readString(offsets[0]),
    costPerUnit: reader.readDoubleOrNull(offsets[1]),
    currentQuantity: reader.readDouble(offsets[3]),
    inventoryValue: reader.readDoubleOrNull(offsets[4]),
    isSynced: reader.readBoolOrNull(offsets[5]) ?? false,
    lastCountedAt: reader.readLongOrNull(offsets[6]),
    lastSyncedAt: reader.readLongOrNull(offsets[7]),
    maxStockLevel: reader.readDoubleOrNull(offsets[8]) ?? 0.0,
    minStockLevel: reader.readDoubleOrNull(offsets[9]) ?? 0.0,
    movementsJson: reader.readStringOrNull(offsets[10]) ?? '[]',
    productId: reader.readString(offsets[11]),
    productName: reader.readStringOrNull(offsets[12]),
    reorderQuantity: reader.readDoubleOrNull(offsets[13]) ?? 0.0,
    sku: reader.readStringOrNull(offsets[14]),
    warehouseLocation: reader.readStringOrNull(offsets[16]),
  );
  object.createdAt = reader.readLong(offsets[2]);
  object.id = id;
  object.updatedAt = reader.readLong(offsets[15]);
  return object;
}

P _isarInventoryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDoubleOrNull(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    case 4:
      return (reader.readDoubleOrNull(offset)) as P;
    case 5:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 6:
      return (reader.readLongOrNull(offset)) as P;
    case 7:
      return (reader.readLongOrNull(offset)) as P;
    case 8:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 9:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 10:
      return (reader.readStringOrNull(offset) ?? '[]') as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readDoubleOrNull(offset) ?? 0.0) as P;
    case 14:
      return (reader.readStringOrNull(offset)) as P;
    case 15:
      return (reader.readLong(offset)) as P;
    case 16:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarInventoryGetId(IsarInventory object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarInventoryGetLinks(IsarInventory object) {
  return [];
}

void _isarInventoryAttach(
    IsarCollection<dynamic> col, Id id, IsarInventory object) {
  object.id = id;
}

extension IsarInventoryQueryWhereSort
    on QueryBuilder<IsarInventory, IsarInventory, QWhere> {
  QueryBuilder<IsarInventory, IsarInventory, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarInventoryQueryWhere
    on QueryBuilder<IsarInventory, IsarInventory, QWhereClause> {
  QueryBuilder<IsarInventory, IsarInventory, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension IsarInventoryQueryFilter
    on QueryBuilder<IsarInventory, IsarInventory, QFilterCondition> {
  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      backendIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'backendId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      backendIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'backendId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      backendIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'backendId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      backendIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'backendId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      backendIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'backendId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      backendIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'backendId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      backendIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'backendId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      backendIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'backendId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      backendIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'backendId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      backendIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'backendId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      costPerUnitIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'costPerUnit',
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      costPerUnitIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'costPerUnit',
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      costPerUnitEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'costPerUnit',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      costPerUnitGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'costPerUnit',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      costPerUnitLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'costPerUnit',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      costPerUnitBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'costPerUnit',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      createdAtEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      createdAtGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      createdAtLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      createdAtBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      currentQuantityEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currentQuantity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      currentQuantityGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currentQuantity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      currentQuantityLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currentQuantity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      currentQuantityBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currentQuantity',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      inventoryValueIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'inventoryValue',
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      inventoryValueIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'inventoryValue',
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      inventoryValueEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'inventoryValue',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      inventoryValueGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'inventoryValue',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      inventoryValueLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'inventoryValue',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      inventoryValueBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'inventoryValue',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      isSyncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      lastCountedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastCountedAt',
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      lastCountedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastCountedAt',
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      lastCountedAtEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastCountedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      lastCountedAtGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastCountedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      lastCountedAtLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastCountedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      lastCountedAtBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastCountedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      lastSyncedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastSyncedAt',
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      lastSyncedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastSyncedAt',
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      lastSyncedAtEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSyncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      lastSyncedAtGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastSyncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      lastSyncedAtLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastSyncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      lastSyncedAtBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastSyncedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      maxStockLevelEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'maxStockLevel',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      maxStockLevelGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'maxStockLevel',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      maxStockLevelLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'maxStockLevel',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      maxStockLevelBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'maxStockLevel',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      minStockLevelEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'minStockLevel',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      minStockLevelGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'minStockLevel',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      minStockLevelLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'minStockLevel',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      minStockLevelBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'minStockLevel',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      movementsJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'movementsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      movementsJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'movementsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      movementsJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'movementsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      movementsJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'movementsJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      movementsJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'movementsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      movementsJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'movementsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      movementsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'movementsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      movementsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'movementsJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      movementsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'movementsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      movementsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'movementsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      productIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'productId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      productIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'productId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      productIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'productId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      productIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'productId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      productIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'productId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      productIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'productId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      productIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'productId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      productIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'productId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      productIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'productId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      productIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'productId',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      productNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'productName',
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      productNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'productName',
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      productNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'productName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      productNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'productName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      productNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'productName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      productNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'productName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      productNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'productName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      productNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'productName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      productNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'productName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      productNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'productName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      productNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'productName',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      productNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'productName',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      reorderQuantityEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reorderQuantity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      reorderQuantityGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'reorderQuantity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      reorderQuantityLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'reorderQuantity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      reorderQuantityBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'reorderQuantity',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      skuIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sku',
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      skuIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sku',
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition> skuEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sku',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      skuGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sku',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition> skuLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sku',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition> skuBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sku',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      skuStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'sku',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition> skuEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'sku',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition> skuContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'sku',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition> skuMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'sku',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      skuIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sku',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      skuIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'sku',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      updatedAtEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      updatedAtGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      updatedAtLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      updatedAtBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      warehouseLocationIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'warehouseLocation',
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      warehouseLocationIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'warehouseLocation',
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      warehouseLocationEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'warehouseLocation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      warehouseLocationGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'warehouseLocation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      warehouseLocationLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'warehouseLocation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      warehouseLocationBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'warehouseLocation',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      warehouseLocationStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'warehouseLocation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      warehouseLocationEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'warehouseLocation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      warehouseLocationContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'warehouseLocation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      warehouseLocationMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'warehouseLocation',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      warehouseLocationIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'warehouseLocation',
        value: '',
      ));
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterFilterCondition>
      warehouseLocationIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'warehouseLocation',
        value: '',
      ));
    });
  }
}

extension IsarInventoryQueryObject
    on QueryBuilder<IsarInventory, IsarInventory, QFilterCondition> {}

extension IsarInventoryQueryLinks
    on QueryBuilder<IsarInventory, IsarInventory, QFilterCondition> {}

extension IsarInventoryQuerySortBy
    on QueryBuilder<IsarInventory, IsarInventory, QSortBy> {
  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy> sortByBackendId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backendId', Sort.asc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      sortByBackendIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backendId', Sort.desc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy> sortByCostPerUnit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'costPerUnit', Sort.asc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      sortByCostPerUnitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'costPerUnit', Sort.desc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      sortByCurrentQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentQuantity', Sort.asc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      sortByCurrentQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentQuantity', Sort.desc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      sortByInventoryValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inventoryValue', Sort.asc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      sortByInventoryValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inventoryValue', Sort.desc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy> sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      sortByLastCountedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastCountedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      sortByLastCountedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastCountedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      sortByLastSyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      sortByLastSyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      sortByMaxStockLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxStockLevel', Sort.asc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      sortByMaxStockLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxStockLevel', Sort.desc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      sortByMinStockLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minStockLevel', Sort.asc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      sortByMinStockLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minStockLevel', Sort.desc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      sortByMovementsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'movementsJson', Sort.asc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      sortByMovementsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'movementsJson', Sort.desc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy> sortByProductId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.asc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      sortByProductIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.desc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy> sortByProductName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productName', Sort.asc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      sortByProductNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productName', Sort.desc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      sortByReorderQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reorderQuantity', Sort.asc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      sortByReorderQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reorderQuantity', Sort.desc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy> sortBySku() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sku', Sort.asc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy> sortBySkuDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sku', Sort.desc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      sortByWarehouseLocation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'warehouseLocation', Sort.asc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      sortByWarehouseLocationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'warehouseLocation', Sort.desc);
    });
  }
}

extension IsarInventoryQuerySortThenBy
    on QueryBuilder<IsarInventory, IsarInventory, QSortThenBy> {
  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy> thenByBackendId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backendId', Sort.asc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      thenByBackendIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backendId', Sort.desc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy> thenByCostPerUnit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'costPerUnit', Sort.asc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      thenByCostPerUnitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'costPerUnit', Sort.desc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      thenByCurrentQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentQuantity', Sort.asc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      thenByCurrentQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentQuantity', Sort.desc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      thenByInventoryValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inventoryValue', Sort.asc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      thenByInventoryValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inventoryValue', Sort.desc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy> thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      thenByLastCountedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastCountedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      thenByLastCountedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastCountedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      thenByLastSyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      thenByLastSyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      thenByMaxStockLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxStockLevel', Sort.asc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      thenByMaxStockLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'maxStockLevel', Sort.desc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      thenByMinStockLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minStockLevel', Sort.asc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      thenByMinStockLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minStockLevel', Sort.desc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      thenByMovementsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'movementsJson', Sort.asc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      thenByMovementsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'movementsJson', Sort.desc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy> thenByProductId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.asc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      thenByProductIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productId', Sort.desc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy> thenByProductName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productName', Sort.asc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      thenByProductNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productName', Sort.desc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      thenByReorderQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reorderQuantity', Sort.asc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      thenByReorderQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reorderQuantity', Sort.desc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy> thenBySku() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sku', Sort.asc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy> thenBySkuDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sku', Sort.desc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      thenByWarehouseLocation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'warehouseLocation', Sort.asc);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QAfterSortBy>
      thenByWarehouseLocationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'warehouseLocation', Sort.desc);
    });
  }
}

extension IsarInventoryQueryWhereDistinct
    on QueryBuilder<IsarInventory, IsarInventory, QDistinct> {
  QueryBuilder<IsarInventory, IsarInventory, QDistinct> distinctByBackendId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'backendId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QDistinct>
      distinctByCostPerUnit() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'costPerUnit');
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QDistinct>
      distinctByCurrentQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currentQuantity');
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QDistinct>
      distinctByInventoryValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'inventoryValue');
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QDistinct> distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QDistinct>
      distinctByLastCountedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastCountedAt');
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QDistinct>
      distinctByLastSyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSyncedAt');
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QDistinct>
      distinctByMaxStockLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'maxStockLevel');
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QDistinct>
      distinctByMinStockLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'minStockLevel');
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QDistinct> distinctByMovementsJson(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'movementsJson',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QDistinct> distinctByProductId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'productId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QDistinct> distinctByProductName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'productName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QDistinct>
      distinctByReorderQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reorderQuantity');
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QDistinct> distinctBySku(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sku', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<IsarInventory, IsarInventory, QDistinct>
      distinctByWarehouseLocation({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'warehouseLocation',
          caseSensitive: caseSensitive);
    });
  }
}

extension IsarInventoryQueryProperty
    on QueryBuilder<IsarInventory, IsarInventory, QQueryProperty> {
  QueryBuilder<IsarInventory, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarInventory, String, QQueryOperations> backendIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'backendId');
    });
  }

  QueryBuilder<IsarInventory, double?, QQueryOperations> costPerUnitProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'costPerUnit');
    });
  }

  QueryBuilder<IsarInventory, int, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<IsarInventory, double, QQueryOperations>
      currentQuantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentQuantity');
    });
  }

  QueryBuilder<IsarInventory, double?, QQueryOperations>
      inventoryValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'inventoryValue');
    });
  }

  QueryBuilder<IsarInventory, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<IsarInventory, int?, QQueryOperations> lastCountedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastCountedAt');
    });
  }

  QueryBuilder<IsarInventory, int?, QQueryOperations> lastSyncedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSyncedAt');
    });
  }

  QueryBuilder<IsarInventory, double, QQueryOperations>
      maxStockLevelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'maxStockLevel');
    });
  }

  QueryBuilder<IsarInventory, double, QQueryOperations>
      minStockLevelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'minStockLevel');
    });
  }

  QueryBuilder<IsarInventory, String, QQueryOperations>
      movementsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'movementsJson');
    });
  }

  QueryBuilder<IsarInventory, String, QQueryOperations> productIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'productId');
    });
  }

  QueryBuilder<IsarInventory, String?, QQueryOperations> productNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'productName');
    });
  }

  QueryBuilder<IsarInventory, double, QQueryOperations>
      reorderQuantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reorderQuantity');
    });
  }

  QueryBuilder<IsarInventory, String?, QQueryOperations> skuProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sku');
    });
  }

  QueryBuilder<IsarInventory, int, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<IsarInventory, String?, QQueryOperations>
      warehouseLocationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'warehouseLocation');
    });
  }
}
