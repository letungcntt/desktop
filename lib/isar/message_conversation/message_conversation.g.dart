// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_conversation.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// ignore_for_file: duplicate_ignore, non_constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast

extension GetMessageConversationCollection on Isar {
  IsarCollection<MessageConversation> get messageConversations {
    return getCollection('MessageConversation');
  }
}

final MessageConversationSchema = CollectionSchema(
  name: 'MessageConversation',
  schema:
      '{"name":"MessageConversation","idName":"localId","properties":[{"name":"action","type":"String"},{"name":"attachments","type":"StringList"},{"name":"conversationId","type":"String"},{"name":"count","type":"Long"},{"name":"currentTime","type":"Long"},{"name":"dataRead","type":"StringList"},{"name":"fakeId","type":"String"},{"name":"id","type":"String"},{"name":"infoThread","type":"StringList"},{"name":"insertedAt","type":"String"},{"name":"isBlur","type":"Bool"},{"name":"isSystemMessage","type":"Bool"},{"name":"lastEditedAt","type":"String"},{"name":"message","type":"String"},{"name":"messageParse","type":"String"},{"name":"parentId","type":"String"},{"name":"publicKeySender","type":"String"},{"name":"sending","type":"Bool"},{"name":"success","type":"Bool"},{"name":"userId","type":"String"}],"indexes":[{"name":"conversationId","unique":false,"properties":[{"name":"conversationId","type":"Hash","caseSensitive":true}]},{"name":"id","unique":false,"properties":[{"name":"id","type":"Hash","caseSensitive":true}]},{"name":"messageParse","unique":false,"properties":[{"name":"messageParse","type":"Value","caseSensitive":true}]},{"name":"parentId_conversationId","unique":false,"properties":[{"name":"parentId","type":"Hash","caseSensitive":true},{"name":"conversationId","type":"Hash","caseSensitive":true}]}],"links":[]}',
  nativeAdapter: const _MessageConversationNativeAdapter(),
  webAdapter: const _MessageConversationWebAdapter(),
  idName: 'localId',
  propertyIds: {
    'action': 0,
    'attachments': 1,
    'conversationId': 2,
    'count': 3,
    'currentTime': 4,
    'dataRead': 5,
    'fakeId': 6,
    'id': 7,
    'infoThread': 8,
    'insertedAt': 9,
    'isBlur': 10,
    'isSystemMessage': 11,
    'lastEditedAt': 12,
    'message': 13,
    'messageParse': 14,
    'parentId': 15,
    'publicKeySender': 16,
    'sending': 17,
    'success': 18,
    'userId': 19
  },
  listProperties: {'attachments', 'dataRead', 'infoThread'},
  indexIds: {
    'conversationId': 0,
    'id': 1,
    'messageParse': 2,
    'parentId_conversationId': 3
  },
  indexTypes: {
    'conversationId': [
      NativeIndexType.stringHash,
    ],
    'id': [
      NativeIndexType.stringHash,
    ],
    'messageParse': [
      NativeIndexType.string,
    ],
    'parentId_conversationId': [
      NativeIndexType.stringHash,
      NativeIndexType.stringHash,
    ]
  },
  linkIds: {},
  backlinkIds: {},
  linkedCollections: [],
  getId: (obj) {
    if (obj.localId == Isar.autoIncrement) {
      return null;
    } else {
      return obj.localId;
    }
  },
  setId: (obj, id) => obj.localId = id,
  getLinks: (obj) => [],
  version: 2,
);

class _MessageConversationWebAdapter
    extends IsarWebTypeAdapter<MessageConversation> {
  const _MessageConversationWebAdapter();

  @override
  Object serialize(IsarCollection<MessageConversation> collection,
      MessageConversation object) {
    final jsObj = IsarNative.newJsObject();
    IsarNative.jsObjectSet(jsObj, 'action', object.action);
    IsarNative.jsObjectSet(jsObj, 'attachments', object.attachments);
    IsarNative.jsObjectSet(jsObj, 'conversationId', object.conversationId);
    IsarNative.jsObjectSet(jsObj, 'count', object.count);
    IsarNative.jsObjectSet(jsObj, 'currentTime', object.currentTime);
    IsarNative.jsObjectSet(jsObj, 'dataRead', object.dataRead);
    IsarNative.jsObjectSet(jsObj, 'fakeId', object.fakeId);
    IsarNative.jsObjectSet(jsObj, 'id', object.id);
    IsarNative.jsObjectSet(jsObj, 'infoThread', object.infoThread);
    IsarNative.jsObjectSet(jsObj, 'insertedAt', object.insertedAt);
    IsarNative.jsObjectSet(jsObj, 'isBlur', object.isBlur);
    IsarNative.jsObjectSet(jsObj, 'isSystemMessage', object.isSystemMessage);
    IsarNative.jsObjectSet(jsObj, 'lastEditedAt', object.lastEditedAt);
    IsarNative.jsObjectSet(jsObj, 'localId', object.localId);
    IsarNative.jsObjectSet(jsObj, 'message', object.message);
    IsarNative.jsObjectSet(jsObj, 'messageParse', object.messageParse);
    IsarNative.jsObjectSet(jsObj, 'parentId', object.parentId);
    IsarNative.jsObjectSet(jsObj, 'publicKeySender', object.publicKeySender);
    IsarNative.jsObjectSet(jsObj, 'sending', object.sending);
    IsarNative.jsObjectSet(jsObj, 'success', object.success);
    IsarNative.jsObjectSet(jsObj, 'userId', object.userId);
    return jsObj;
  }

  @override
  MessageConversation deserialize(
      IsarCollection<MessageConversation> collection, dynamic jsObj) {
    final object = MessageConversation();
    object.action = IsarNative.jsObjectGet(jsObj, 'action');
    object.attachments = (IsarNative.jsObjectGet(jsObj, 'attachments') as List?)
        ?.map((e) => e ?? '')
        .toList()
        .cast<String>();
    object.conversationId = IsarNative.jsObjectGet(jsObj, 'conversationId');
    object.count = IsarNative.jsObjectGet(jsObj, 'count');
    object.currentTime = IsarNative.jsObjectGet(jsObj, 'currentTime');
    object.dataRead = (IsarNative.jsObjectGet(jsObj, 'dataRead') as List?)
        ?.map((e) => e ?? '')
        .toList()
        .cast<String>();
    object.fakeId = IsarNative.jsObjectGet(jsObj, 'fakeId');
    object.id = IsarNative.jsObjectGet(jsObj, 'id');
    object.infoThread = (IsarNative.jsObjectGet(jsObj, 'infoThread') as List?)
        ?.map((e) => e ?? '')
        .toList()
        .cast<String>();
    object.insertedAt = IsarNative.jsObjectGet(jsObj, 'insertedAt');
    object.isBlur = IsarNative.jsObjectGet(jsObj, 'isBlur');
    object.isSystemMessage = IsarNative.jsObjectGet(jsObj, 'isSystemMessage');
    object.lastEditedAt = IsarNative.jsObjectGet(jsObj, 'lastEditedAt');
    object.localId = IsarNative.jsObjectGet(jsObj, 'localId');
    object.message = IsarNative.jsObjectGet(jsObj, 'message');
    object.messageParse = IsarNative.jsObjectGet(jsObj, 'messageParse');
    object.parentId = IsarNative.jsObjectGet(jsObj, 'parentId');
    object.publicKeySender = IsarNative.jsObjectGet(jsObj, 'publicKeySender');
    object.sending = IsarNative.jsObjectGet(jsObj, 'sending');
    object.success = IsarNative.jsObjectGet(jsObj, 'success');
    object.userId = IsarNative.jsObjectGet(jsObj, 'userId');
    return object;
  }

  @override
  P deserializeProperty<P>(Object jsObj, String propertyName) {
    switch (propertyName) {
      case 'action':
        return (IsarNative.jsObjectGet(jsObj, 'action')) as P;
      case 'attachments':
        return ((IsarNative.jsObjectGet(jsObj, 'attachments') as List?)
            ?.map((e) => e ?? '')
            .toList()
            .cast<String>()) as P;
      case 'conversationId':
        return (IsarNative.jsObjectGet(jsObj, 'conversationId')) as P;
      case 'count':
        return (IsarNative.jsObjectGet(jsObj, 'count')) as P;
      case 'currentTime':
        return (IsarNative.jsObjectGet(jsObj, 'currentTime')) as P;
      case 'dataRead':
        return ((IsarNative.jsObjectGet(jsObj, 'dataRead') as List?)
            ?.map((e) => e ?? '')
            .toList()
            .cast<String>()) as P;
      case 'fakeId':
        return (IsarNative.jsObjectGet(jsObj, 'fakeId')) as P;
      case 'id':
        return (IsarNative.jsObjectGet(jsObj, 'id')) as P;
      case 'infoThread':
        return ((IsarNative.jsObjectGet(jsObj, 'infoThread') as List?)
            ?.map((e) => e ?? '')
            .toList()
            .cast<String>()) as P;
      case 'insertedAt':
        return (IsarNative.jsObjectGet(jsObj, 'insertedAt')) as P;
      case 'isBlur':
        return (IsarNative.jsObjectGet(jsObj, 'isBlur')) as P;
      case 'isSystemMessage':
        return (IsarNative.jsObjectGet(jsObj, 'isSystemMessage')) as P;
      case 'lastEditedAt':
        return (IsarNative.jsObjectGet(jsObj, 'lastEditedAt')) as P;
      case 'localId':
        return (IsarNative.jsObjectGet(jsObj, 'localId')) as P;
      case 'message':
        return (IsarNative.jsObjectGet(jsObj, 'message')) as P;
      case 'messageParse':
        return (IsarNative.jsObjectGet(jsObj, 'messageParse')) as P;
      case 'parentId':
        return (IsarNative.jsObjectGet(jsObj, 'parentId')) as P;
      case 'publicKeySender':
        return (IsarNative.jsObjectGet(jsObj, 'publicKeySender')) as P;
      case 'sending':
        return (IsarNative.jsObjectGet(jsObj, 'sending')) as P;
      case 'success':
        return (IsarNative.jsObjectGet(jsObj, 'success')) as P;
      case 'userId':
        return (IsarNative.jsObjectGet(jsObj, 'userId')) as P;
      default:
        throw 'Illegal propertyName';
    }
  }

  @override
  void attachLinks(Isar isar, int id, MessageConversation object) {}
}

class _MessageConversationNativeAdapter
    extends IsarNativeTypeAdapter<MessageConversation> {
  const _MessageConversationNativeAdapter();

  @override
  void serialize(
      IsarCollection<MessageConversation> collection,
      IsarRawObject rawObj,
      MessageConversation object,
      int staticSize,
      List<int> offsets,
      AdapterAlloc alloc) {
    var dynamicSize = 0;
    final value0 = object.action;
    IsarUint8List? _action;
    if (value0 != null) {
      _action = IsarBinaryWriter.utf8Encoder.convert(value0);
    }
    dynamicSize += (_action?.length ?? 0) as int;
    final value1 = object.attachments;
    dynamicSize += (value1?.length ?? 0) * 8;
    List<IsarUint8List?>? bytesList1;
    if (value1 != null) {
      bytesList1 = [];
      for (var str in value1) {
        final bytes = IsarBinaryWriter.utf8Encoder.convert(str);
        bytesList1.add(bytes);
        dynamicSize += bytes.length as int;
      }
    }
    final _attachments = bytesList1;
    final value2 = object.conversationId;
    IsarUint8List? _conversationId;
    if (value2 != null) {
      _conversationId = IsarBinaryWriter.utf8Encoder.convert(value2);
    }
    dynamicSize += (_conversationId?.length ?? 0) as int;
    final value3 = object.count;
    final _count = value3;
    final value4 = object.currentTime;
    final _currentTime = value4;
    final value5 = object.dataRead;
    dynamicSize += (value5?.length ?? 0) * 8;
    List<IsarUint8List?>? bytesList5;
    if (value5 != null) {
      bytesList5 = [];
      for (var str in value5) {
        final bytes = IsarBinaryWriter.utf8Encoder.convert(str);
        bytesList5.add(bytes);
        dynamicSize += bytes.length as int;
      }
    }
    final _dataRead = bytesList5;
    final value6 = object.fakeId;
    IsarUint8List? _fakeId;
    if (value6 != null) {
      _fakeId = IsarBinaryWriter.utf8Encoder.convert(value6);
    }
    dynamicSize += (_fakeId?.length ?? 0) as int;
    final value7 = object.id;
    IsarUint8List? _id;
    if (value7 != null) {
      _id = IsarBinaryWriter.utf8Encoder.convert(value7);
    }
    dynamicSize += (_id?.length ?? 0) as int;
    final value8 = object.infoThread;
    dynamicSize += (value8?.length ?? 0) * 8;
    List<IsarUint8List?>? bytesList8;
    if (value8 != null) {
      bytesList8 = [];
      for (var str in value8) {
        final bytes = IsarBinaryWriter.utf8Encoder.convert(str);
        bytesList8.add(bytes);
        dynamicSize += bytes.length as int;
      }
    }
    final _infoThread = bytesList8;
    final value9 = object.insertedAt;
    IsarUint8List? _insertedAt;
    if (value9 != null) {
      _insertedAt = IsarBinaryWriter.utf8Encoder.convert(value9);
    }
    dynamicSize += (_insertedAt?.length ?? 0) as int;
    final value10 = object.isBlur;
    final _isBlur = value10;
    final value11 = object.isSystemMessage;
    final _isSystemMessage = value11;
    final value12 = object.lastEditedAt;
    IsarUint8List? _lastEditedAt;
    if (value12 != null) {
      _lastEditedAt = IsarBinaryWriter.utf8Encoder.convert(value12);
    }
    dynamicSize += (_lastEditedAt?.length ?? 0) as int;
    final value13 = object.message;
    IsarUint8List? _message;
    if (value13 != null) {
      _message = IsarBinaryWriter.utf8Encoder.convert(value13);
    }
    dynamicSize += (_message?.length ?? 0) as int;
    final value14 = object.messageParse;
    IsarUint8List? _messageParse;
    if (value14 != null) {
      _messageParse = IsarBinaryWriter.utf8Encoder.convert(value14);
    }
    dynamicSize += (_messageParse?.length ?? 0) as int;
    final value15 = object.parentId;
    IsarUint8List? _parentId;
    if (value15 != null) {
      _parentId = IsarBinaryWriter.utf8Encoder.convert(value15);
    }
    dynamicSize += (_parentId?.length ?? 0) as int;
    final value16 = object.publicKeySender;
    IsarUint8List? _publicKeySender;
    if (value16 != null) {
      _publicKeySender = IsarBinaryWriter.utf8Encoder.convert(value16);
    }
    dynamicSize += (_publicKeySender?.length ?? 0) as int;
    final value17 = object.sending;
    final _sending = value17;
    final value18 = object.success;
    final _success = value18;
    final value19 = object.userId;
    IsarUint8List? _userId;
    if (value19 != null) {
      _userId = IsarBinaryWriter.utf8Encoder.convert(value19);
    }
    dynamicSize += (_userId?.length ?? 0) as int;
    final size = staticSize + dynamicSize;

    rawObj.buffer = alloc(size);
    rawObj.buffer_length = size;
    final buffer = IsarNative.bufAsBytes(rawObj.buffer, size);
    final writer = IsarBinaryWriter(buffer, staticSize);
    writer.writeBytes(offsets[0], _action);
    writer.writeStringList(offsets[1], _attachments);
    writer.writeBytes(offsets[2], _conversationId);
    writer.writeLong(offsets[3], _count);
    writer.writeLong(offsets[4], _currentTime);
    writer.writeStringList(offsets[5], _dataRead);
    writer.writeBytes(offsets[6], _fakeId);
    writer.writeBytes(offsets[7], _id);
    writer.writeStringList(offsets[8], _infoThread);
    writer.writeBytes(offsets[9], _insertedAt);
    writer.writeBool(offsets[10], _isBlur);
    writer.writeBool(offsets[11], _isSystemMessage);
    writer.writeBytes(offsets[12], _lastEditedAt);
    writer.writeBytes(offsets[13], _message);
    writer.writeBytes(offsets[14], _messageParse);
    writer.writeBytes(offsets[15], _parentId);
    writer.writeBytes(offsets[16], _publicKeySender);
    writer.writeBool(offsets[17], _sending);
    writer.writeBool(offsets[18], _success);
    writer.writeBytes(offsets[19], _userId);
  }

  @override
  MessageConversation deserialize(
      IsarCollection<MessageConversation> collection,
      int id,
      IsarBinaryReader reader,
      List<int> offsets) {
    final object = MessageConversation();
    object.action = reader.readStringOrNull(offsets[0]);
    object.attachments = reader.readStringList(offsets[1]);
    object.conversationId = reader.readStringOrNull(offsets[2]);
    object.count = reader.readLongOrNull(offsets[3]);
    object.currentTime = reader.readLongOrNull(offsets[4]);
    object.dataRead = reader.readStringList(offsets[5]);
    object.fakeId = reader.readStringOrNull(offsets[6]);
    object.id = reader.readStringOrNull(offsets[7]);
    object.infoThread = reader.readStringList(offsets[8]);
    object.insertedAt = reader.readStringOrNull(offsets[9]);
    object.isBlur = reader.readBoolOrNull(offsets[10]);
    object.isSystemMessage = reader.readBoolOrNull(offsets[11]);
    object.lastEditedAt = reader.readStringOrNull(offsets[12]);
    object.localId = id;
    object.message = reader.readStringOrNull(offsets[13]);
    object.messageParse = reader.readStringOrNull(offsets[14]);
    object.parentId = reader.readStringOrNull(offsets[15]);
    object.publicKeySender = reader.readStringOrNull(offsets[16]);
    object.sending = reader.readBoolOrNull(offsets[17]);
    object.success = reader.readBoolOrNull(offsets[18]);
    object.userId = reader.readStringOrNull(offsets[19]);
    return object;
  }

  @override
  P deserializeProperty<P>(
      int id, IsarBinaryReader reader, int propertyIndex, int offset) {
    switch (propertyIndex) {
      case -1:
        return id as P;
      case 0:
        return (reader.readStringOrNull(offset)) as P;
      case 1:
        return (reader.readStringList(offset)) as P;
      case 2:
        return (reader.readStringOrNull(offset)) as P;
      case 3:
        return (reader.readLongOrNull(offset)) as P;
      case 4:
        return (reader.readLongOrNull(offset)) as P;
      case 5:
        return (reader.readStringList(offset)) as P;
      case 6:
        return (reader.readStringOrNull(offset)) as P;
      case 7:
        return (reader.readStringOrNull(offset)) as P;
      case 8:
        return (reader.readStringList(offset)) as P;
      case 9:
        return (reader.readStringOrNull(offset)) as P;
      case 10:
        return (reader.readBoolOrNull(offset)) as P;
      case 11:
        return (reader.readBoolOrNull(offset)) as P;
      case 12:
        return (reader.readStringOrNull(offset)) as P;
      case 13:
        return (reader.readStringOrNull(offset)) as P;
      case 14:
        return (reader.readStringOrNull(offset)) as P;
      case 15:
        return (reader.readStringOrNull(offset)) as P;
      case 16:
        return (reader.readStringOrNull(offset)) as P;
      case 17:
        return (reader.readBoolOrNull(offset)) as P;
      case 18:
        return (reader.readBoolOrNull(offset)) as P;
      case 19:
        return (reader.readStringOrNull(offset)) as P;
      default:
        throw 'Illegal propertyIndex';
    }
  }

  @override
  void attachLinks(Isar isar, int id, MessageConversation object) {}
}

extension MessageConversationQueryWhereSort
    on QueryBuilder<MessageConversation, MessageConversation, QWhere> {
  QueryBuilder<MessageConversation, MessageConversation, QAfterWhere>
      anyLocalId() {
    return addWhereClauseInternal(const WhereClause(indexName: null));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterWhere>
      anyConversationId() {
    return addWhereClauseInternal(
        const WhereClause(indexName: 'conversationId'));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterWhere> anyId() {
    return addWhereClauseInternal(const WhereClause(indexName: 'id'));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterWhere>
      anyMessageParse() {
    return addWhereClauseInternal(const WhereClause(indexName: 'messageParse'));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterWhere>
      anyParentIdConversationId() {
    return addWhereClauseInternal(
        const WhereClause(indexName: 'parentId_conversationId'));
  }
}

extension MessageConversationQueryWhere
    on QueryBuilder<MessageConversation, MessageConversation, QWhereClause> {
  QueryBuilder<MessageConversation, MessageConversation, QAfterWhereClause>
      localIdEqualTo(int? localId) {
    return addWhereClauseInternal(WhereClause(
      indexName: null,
      lower: [localId],
      includeLower: true,
      upper: [localId],
      includeUpper: true,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterWhereClause>
      localIdNotEqualTo(int? localId) {
    if (whereSortInternal == Sort.asc) {
      return addWhereClauseInternal(WhereClause(
        indexName: null,
        upper: [localId],
        includeUpper: false,
      )).addWhereClauseInternal(WhereClause(
        indexName: null,
        lower: [localId],
        includeLower: false,
      ));
    } else {
      return addWhereClauseInternal(WhereClause(
        indexName: null,
        lower: [localId],
        includeLower: false,
      )).addWhereClauseInternal(WhereClause(
        indexName: null,
        upper: [localId],
        includeUpper: false,
      ));
    }
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterWhereClause>
      localIdGreaterThan(
    int? localId, {
    bool include = false,
  }) {
    return addWhereClauseInternal(WhereClause(
      indexName: null,
      lower: [localId],
      includeLower: include,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterWhereClause>
      localIdLessThan(
    int? localId, {
    bool include = false,
  }) {
    return addWhereClauseInternal(WhereClause(
      indexName: null,
      upper: [localId],
      includeUpper: include,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterWhereClause>
      localIdBetween(
    int? lowerLocalId,
    int? upperLocalId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return addWhereClauseInternal(WhereClause(
      indexName: null,
      lower: [lowerLocalId],
      includeLower: includeLower,
      upper: [upperLocalId],
      includeUpper: includeUpper,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterWhereClause>
      conversationIdEqualTo(String? conversationId) {
    return addWhereClauseInternal(WhereClause(
      indexName: 'conversationId',
      lower: [conversationId],
      includeLower: true,
      upper: [conversationId],
      includeUpper: true,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterWhereClause>
      conversationIdNotEqualTo(String? conversationId) {
    if (whereSortInternal == Sort.asc) {
      return addWhereClauseInternal(WhereClause(
        indexName: 'conversationId',
        upper: [conversationId],
        includeUpper: false,
      )).addWhereClauseInternal(WhereClause(
        indexName: 'conversationId',
        lower: [conversationId],
        includeLower: false,
      ));
    } else {
      return addWhereClauseInternal(WhereClause(
        indexName: 'conversationId',
        lower: [conversationId],
        includeLower: false,
      )).addWhereClauseInternal(WhereClause(
        indexName: 'conversationId',
        upper: [conversationId],
        includeUpper: false,
      ));
    }
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterWhereClause>
      conversationIdIsNull() {
    return addWhereClauseInternal(const WhereClause(
      indexName: 'conversationId',
      upper: [null],
      includeUpper: true,
      lower: [null],
      includeLower: true,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterWhereClause>
      conversationIdIsNotNull() {
    return addWhereClauseInternal(const WhereClause(
      indexName: 'conversationId',
      lower: [null],
      includeLower: false,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterWhereClause>
      idEqualTo(String? id) {
    return addWhereClauseInternal(WhereClause(
      indexName: 'id',
      lower: [id],
      includeLower: true,
      upper: [id],
      includeUpper: true,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterWhereClause>
      idNotEqualTo(String? id) {
    if (whereSortInternal == Sort.asc) {
      return addWhereClauseInternal(WhereClause(
        indexName: 'id',
        upper: [id],
        includeUpper: false,
      )).addWhereClauseInternal(WhereClause(
        indexName: 'id',
        lower: [id],
        includeLower: false,
      ));
    } else {
      return addWhereClauseInternal(WhereClause(
        indexName: 'id',
        lower: [id],
        includeLower: false,
      )).addWhereClauseInternal(WhereClause(
        indexName: 'id',
        upper: [id],
        includeUpper: false,
      ));
    }
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterWhereClause>
      idIsNull() {
    return addWhereClauseInternal(const WhereClause(
      indexName: 'id',
      upper: [null],
      includeUpper: true,
      lower: [null],
      includeLower: true,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterWhereClause>
      idIsNotNull() {
    return addWhereClauseInternal(const WhereClause(
      indexName: 'id',
      lower: [null],
      includeLower: false,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterWhereClause>
      messageParseEqualTo(String? messageParse) {
    return addWhereClauseInternal(WhereClause(
      indexName: 'messageParse',
      lower: [messageParse],
      includeLower: true,
      upper: [messageParse],
      includeUpper: true,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterWhereClause>
      messageParseNotEqualTo(String? messageParse) {
    if (whereSortInternal == Sort.asc) {
      return addWhereClauseInternal(WhereClause(
        indexName: 'messageParse',
        upper: [messageParse],
        includeUpper: false,
      )).addWhereClauseInternal(WhereClause(
        indexName: 'messageParse',
        lower: [messageParse],
        includeLower: false,
      ));
    } else {
      return addWhereClauseInternal(WhereClause(
        indexName: 'messageParse',
        lower: [messageParse],
        includeLower: false,
      )).addWhereClauseInternal(WhereClause(
        indexName: 'messageParse',
        upper: [messageParse],
        includeUpper: false,
      ));
    }
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterWhereClause>
      messageParseIsNull() {
    return addWhereClauseInternal(const WhereClause(
      indexName: 'messageParse',
      upper: [null],
      includeUpper: true,
      lower: [null],
      includeLower: true,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterWhereClause>
      messageParseIsNotNull() {
    return addWhereClauseInternal(const WhereClause(
      indexName: 'messageParse',
      lower: [null],
      includeLower: false,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterWhereClause>
      messageParseGreaterThan(
    String? messageParse, {
    bool include = false,
  }) {
    return addWhereClauseInternal(WhereClause(
      indexName: 'messageParse',
      lower: [messageParse],
      includeLower: include,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterWhereClause>
      messageParseLessThan(
    String? messageParse, {
    bool include = false,
  }) {
    return addWhereClauseInternal(WhereClause(
      indexName: 'messageParse',
      upper: [messageParse],
      includeUpper: include,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterWhereClause>
      messageParseBetween(
    String? lowerMessageParse,
    String? upperMessageParse, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return addWhereClauseInternal(WhereClause(
      indexName: 'messageParse',
      lower: [lowerMessageParse],
      includeLower: includeLower,
      upper: [upperMessageParse],
      includeUpper: includeUpper,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterWhereClause>
      messageParseStartsWith(String? MessageParsePrefix) {
    return addWhereClauseInternal(WhereClause(
      indexName: 'messageParse',
      lower: [MessageParsePrefix],
      includeLower: true,
      upper: ['$MessageParsePrefix\u{FFFFF}'],
      includeUpper: true,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterWhereClause>
      parentIdEqualTo(String? parentId) {
    return addWhereClauseInternal(WhereClause(
      indexName: 'parentId_conversationId',
      lower: [parentId],
      includeLower: true,
      upper: [parentId],
      includeUpper: true,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterWhereClause>
      parentIdNotEqualTo(String? parentId) {
    if (whereSortInternal == Sort.asc) {
      return addWhereClauseInternal(WhereClause(
        indexName: 'parentId_conversationId',
        upper: [parentId],
        includeUpper: false,
      )).addWhereClauseInternal(WhereClause(
        indexName: 'parentId_conversationId',
        lower: [parentId],
        includeLower: false,
      ));
    } else {
      return addWhereClauseInternal(WhereClause(
        indexName: 'parentId_conversationId',
        lower: [parentId],
        includeLower: false,
      )).addWhereClauseInternal(WhereClause(
        indexName: 'parentId_conversationId',
        upper: [parentId],
        includeUpper: false,
      ));
    }
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterWhereClause>
      parentIdConversationIdEqualTo(String? parentId, String? conversationId) {
    return addWhereClauseInternal(WhereClause(
      indexName: 'parentId_conversationId',
      lower: [parentId, conversationId],
      includeLower: true,
      upper: [parentId, conversationId],
      includeUpper: true,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterWhereClause>
      parentIdConversationIdNotEqualTo(
          String? parentId, String? conversationId) {
    if (whereSortInternal == Sort.asc) {
      return addWhereClauseInternal(WhereClause(
        indexName: 'parentId_conversationId',
        upper: [parentId, conversationId],
        includeUpper: false,
      )).addWhereClauseInternal(WhereClause(
        indexName: 'parentId_conversationId',
        lower: [parentId, conversationId],
        includeLower: false,
      ));
    } else {
      return addWhereClauseInternal(WhereClause(
        indexName: 'parentId_conversationId',
        lower: [parentId, conversationId],
        includeLower: false,
      )).addWhereClauseInternal(WhereClause(
        indexName: 'parentId_conversationId',
        upper: [parentId, conversationId],
        includeUpper: false,
      ));
    }
  }
}

extension MessageConversationQueryFilter on QueryBuilder<MessageConversation,
    MessageConversation, QFilterCondition> {
  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      actionIsNull() {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.isNull,
      property: 'action',
      value: null,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      actionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.eq,
      property: 'action',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      actionGreaterThan(
    String? value, {
    bool caseSensitive = true,
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.gt,
      include: include,
      property: 'action',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      actionLessThan(
    String? value, {
    bool caseSensitive = true,
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.lt,
      include: include,
      property: 'action',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      actionBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return addFilterConditionInternal(FilterCondition.between(
      property: 'action',
      lower: lower,
      includeLower: includeLower,
      upper: upper,
      includeUpper: includeUpper,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      actionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.startsWith,
      property: 'action',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      actionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.endsWith,
      property: 'action',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      actionContains(String value, {bool caseSensitive = true}) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.contains,
      property: 'action',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      actionMatches(String pattern, {bool caseSensitive = true}) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.matches,
      property: 'action',
      value: pattern,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      attachmentsIsNull() {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.isNull,
      property: 'attachments',
      value: null,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      attachmentsAnyIsNull() {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.eq,
      property: 'attachments',
      value: null,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      attachmentsAnyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.eq,
      property: 'attachments',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      attachmentsAnyGreaterThan(
    String? value, {
    bool caseSensitive = true,
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.gt,
      include: include,
      property: 'attachments',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      attachmentsAnyLessThan(
    String? value, {
    bool caseSensitive = true,
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.lt,
      include: include,
      property: 'attachments',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      attachmentsAnyBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return addFilterConditionInternal(FilterCondition.between(
      property: 'attachments',
      lower: lower,
      includeLower: includeLower,
      upper: upper,
      includeUpper: includeUpper,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      attachmentsAnyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.startsWith,
      property: 'attachments',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      attachmentsAnyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.endsWith,
      property: 'attachments',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      attachmentsAnyContains(String value, {bool caseSensitive = true}) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.contains,
      property: 'attachments',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      attachmentsAnyMatches(String pattern, {bool caseSensitive = true}) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.matches,
      property: 'attachments',
      value: pattern,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      conversationIdIsNull() {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.isNull,
      property: 'conversationId',
      value: null,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      conversationIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.eq,
      property: 'conversationId',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      conversationIdGreaterThan(
    String? value, {
    bool caseSensitive = true,
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.gt,
      include: include,
      property: 'conversationId',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      conversationIdLessThan(
    String? value, {
    bool caseSensitive = true,
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.lt,
      include: include,
      property: 'conversationId',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      conversationIdBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return addFilterConditionInternal(FilterCondition.between(
      property: 'conversationId',
      lower: lower,
      includeLower: includeLower,
      upper: upper,
      includeUpper: includeUpper,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      conversationIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.startsWith,
      property: 'conversationId',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      conversationIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.endsWith,
      property: 'conversationId',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      conversationIdContains(String value, {bool caseSensitive = true}) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.contains,
      property: 'conversationId',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      conversationIdMatches(String pattern, {bool caseSensitive = true}) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.matches,
      property: 'conversationId',
      value: pattern,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      countIsNull() {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.isNull,
      property: 'count',
      value: null,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      countEqualTo(int? value) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.eq,
      property: 'count',
      value: value,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      countGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.gt,
      include: include,
      property: 'count',
      value: value,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      countLessThan(
    int? value, {
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.lt,
      include: include,
      property: 'count',
      value: value,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      countBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return addFilterConditionInternal(FilterCondition.between(
      property: 'count',
      lower: lower,
      includeLower: includeLower,
      upper: upper,
      includeUpper: includeUpper,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      currentTimeIsNull() {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.isNull,
      property: 'currentTime',
      value: null,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      currentTimeEqualTo(int? value) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.eq,
      property: 'currentTime',
      value: value,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      currentTimeGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.gt,
      include: include,
      property: 'currentTime',
      value: value,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      currentTimeLessThan(
    int? value, {
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.lt,
      include: include,
      property: 'currentTime',
      value: value,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      currentTimeBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return addFilterConditionInternal(FilterCondition.between(
      property: 'currentTime',
      lower: lower,
      includeLower: includeLower,
      upper: upper,
      includeUpper: includeUpper,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      dataReadIsNull() {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.isNull,
      property: 'dataRead',
      value: null,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      dataReadAnyIsNull() {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.eq,
      property: 'dataRead',
      value: null,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      dataReadAnyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.eq,
      property: 'dataRead',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      dataReadAnyGreaterThan(
    String? value, {
    bool caseSensitive = true,
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.gt,
      include: include,
      property: 'dataRead',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      dataReadAnyLessThan(
    String? value, {
    bool caseSensitive = true,
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.lt,
      include: include,
      property: 'dataRead',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      dataReadAnyBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return addFilterConditionInternal(FilterCondition.between(
      property: 'dataRead',
      lower: lower,
      includeLower: includeLower,
      upper: upper,
      includeUpper: includeUpper,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      dataReadAnyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.startsWith,
      property: 'dataRead',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      dataReadAnyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.endsWith,
      property: 'dataRead',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      dataReadAnyContains(String value, {bool caseSensitive = true}) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.contains,
      property: 'dataRead',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      dataReadAnyMatches(String pattern, {bool caseSensitive = true}) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.matches,
      property: 'dataRead',
      value: pattern,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      fakeIdIsNull() {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.isNull,
      property: 'fakeId',
      value: null,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      fakeIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.eq,
      property: 'fakeId',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      fakeIdGreaterThan(
    String? value, {
    bool caseSensitive = true,
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.gt,
      include: include,
      property: 'fakeId',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      fakeIdLessThan(
    String? value, {
    bool caseSensitive = true,
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.lt,
      include: include,
      property: 'fakeId',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      fakeIdBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return addFilterConditionInternal(FilterCondition.between(
      property: 'fakeId',
      lower: lower,
      includeLower: includeLower,
      upper: upper,
      includeUpper: includeUpper,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      fakeIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.startsWith,
      property: 'fakeId',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      fakeIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.endsWith,
      property: 'fakeId',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      fakeIdContains(String value, {bool caseSensitive = true}) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.contains,
      property: 'fakeId',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      fakeIdMatches(String pattern, {bool caseSensitive = true}) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.matches,
      property: 'fakeId',
      value: pattern,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      idIsNull() {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.isNull,
      property: 'id',
      value: null,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      idEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.eq,
      property: 'id',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      idGreaterThan(
    String? value, {
    bool caseSensitive = true,
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.gt,
      include: include,
      property: 'id',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      idLessThan(
    String? value, {
    bool caseSensitive = true,
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.lt,
      include: include,
      property: 'id',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      idBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return addFilterConditionInternal(FilterCondition.between(
      property: 'id',
      lower: lower,
      includeLower: includeLower,
      upper: upper,
      includeUpper: includeUpper,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.startsWith,
      property: 'id',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.endsWith,
      property: 'id',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      idContains(String value, {bool caseSensitive = true}) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.contains,
      property: 'id',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      idMatches(String pattern, {bool caseSensitive = true}) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.matches,
      property: 'id',
      value: pattern,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      infoThreadIsNull() {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.isNull,
      property: 'infoThread',
      value: null,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      infoThreadAnyIsNull() {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.eq,
      property: 'infoThread',
      value: null,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      infoThreadAnyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.eq,
      property: 'infoThread',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      infoThreadAnyGreaterThan(
    String? value, {
    bool caseSensitive = true,
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.gt,
      include: include,
      property: 'infoThread',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      infoThreadAnyLessThan(
    String? value, {
    bool caseSensitive = true,
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.lt,
      include: include,
      property: 'infoThread',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      infoThreadAnyBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return addFilterConditionInternal(FilterCondition.between(
      property: 'infoThread',
      lower: lower,
      includeLower: includeLower,
      upper: upper,
      includeUpper: includeUpper,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      infoThreadAnyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.startsWith,
      property: 'infoThread',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      infoThreadAnyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.endsWith,
      property: 'infoThread',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      infoThreadAnyContains(String value, {bool caseSensitive = true}) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.contains,
      property: 'infoThread',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      infoThreadAnyMatches(String pattern, {bool caseSensitive = true}) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.matches,
      property: 'infoThread',
      value: pattern,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      insertedAtIsNull() {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.isNull,
      property: 'insertedAt',
      value: null,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      insertedAtEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.eq,
      property: 'insertedAt',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      insertedAtGreaterThan(
    String? value, {
    bool caseSensitive = true,
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.gt,
      include: include,
      property: 'insertedAt',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      insertedAtLessThan(
    String? value, {
    bool caseSensitive = true,
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.lt,
      include: include,
      property: 'insertedAt',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      insertedAtBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return addFilterConditionInternal(FilterCondition.between(
      property: 'insertedAt',
      lower: lower,
      includeLower: includeLower,
      upper: upper,
      includeUpper: includeUpper,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      insertedAtStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.startsWith,
      property: 'insertedAt',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      insertedAtEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.endsWith,
      property: 'insertedAt',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      insertedAtContains(String value, {bool caseSensitive = true}) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.contains,
      property: 'insertedAt',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      insertedAtMatches(String pattern, {bool caseSensitive = true}) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.matches,
      property: 'insertedAt',
      value: pattern,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      isBlurIsNull() {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.isNull,
      property: 'isBlur',
      value: null,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      isBlurEqualTo(bool? value) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.eq,
      property: 'isBlur',
      value: value,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      isSystemMessageIsNull() {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.isNull,
      property: 'isSystemMessage',
      value: null,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      isSystemMessageEqualTo(bool? value) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.eq,
      property: 'isSystemMessage',
      value: value,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      lastEditedAtIsNull() {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.isNull,
      property: 'lastEditedAt',
      value: null,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      lastEditedAtEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.eq,
      property: 'lastEditedAt',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      lastEditedAtGreaterThan(
    String? value, {
    bool caseSensitive = true,
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.gt,
      include: include,
      property: 'lastEditedAt',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      lastEditedAtLessThan(
    String? value, {
    bool caseSensitive = true,
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.lt,
      include: include,
      property: 'lastEditedAt',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      lastEditedAtBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return addFilterConditionInternal(FilterCondition.between(
      property: 'lastEditedAt',
      lower: lower,
      includeLower: includeLower,
      upper: upper,
      includeUpper: includeUpper,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      lastEditedAtStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.startsWith,
      property: 'lastEditedAt',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      lastEditedAtEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.endsWith,
      property: 'lastEditedAt',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      lastEditedAtContains(String value, {bool caseSensitive = true}) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.contains,
      property: 'lastEditedAt',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      lastEditedAtMatches(String pattern, {bool caseSensitive = true}) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.matches,
      property: 'lastEditedAt',
      value: pattern,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      localIdIsNull() {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.isNull,
      property: 'localId',
      value: null,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      localIdEqualTo(int? value) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.eq,
      property: 'localId',
      value: value,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      localIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.gt,
      include: include,
      property: 'localId',
      value: value,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      localIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.lt,
      include: include,
      property: 'localId',
      value: value,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      localIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return addFilterConditionInternal(FilterCondition.between(
      property: 'localId',
      lower: lower,
      includeLower: includeLower,
      upper: upper,
      includeUpper: includeUpper,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      messageIsNull() {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.isNull,
      property: 'message',
      value: null,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      messageEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.eq,
      property: 'message',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      messageGreaterThan(
    String? value, {
    bool caseSensitive = true,
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.gt,
      include: include,
      property: 'message',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      messageLessThan(
    String? value, {
    bool caseSensitive = true,
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.lt,
      include: include,
      property: 'message',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      messageBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return addFilterConditionInternal(FilterCondition.between(
      property: 'message',
      lower: lower,
      includeLower: includeLower,
      upper: upper,
      includeUpper: includeUpper,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      messageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.startsWith,
      property: 'message',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      messageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.endsWith,
      property: 'message',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      messageContains(String value, {bool caseSensitive = true}) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.contains,
      property: 'message',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      messageMatches(String pattern, {bool caseSensitive = true}) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.matches,
      property: 'message',
      value: pattern,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      messageParseIsNull() {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.isNull,
      property: 'messageParse',
      value: null,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      messageParseEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.eq,
      property: 'messageParse',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      messageParseGreaterThan(
    String? value, {
    bool caseSensitive = true,
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.gt,
      include: include,
      property: 'messageParse',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      messageParseLessThan(
    String? value, {
    bool caseSensitive = true,
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.lt,
      include: include,
      property: 'messageParse',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      messageParseBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return addFilterConditionInternal(FilterCondition.between(
      property: 'messageParse',
      lower: lower,
      includeLower: includeLower,
      upper: upper,
      includeUpper: includeUpper,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      messageParseStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.startsWith,
      property: 'messageParse',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      messageParseEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.endsWith,
      property: 'messageParse',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      messageParseContains(String value, {bool caseSensitive = true}) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.contains,
      property: 'messageParse',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      messageParseMatches(String pattern, {bool caseSensitive = true}) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.matches,
      property: 'messageParse',
      value: pattern,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      parentIdIsNull() {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.isNull,
      property: 'parentId',
      value: null,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      parentIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.eq,
      property: 'parentId',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      parentIdGreaterThan(
    String? value, {
    bool caseSensitive = true,
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.gt,
      include: include,
      property: 'parentId',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      parentIdLessThan(
    String? value, {
    bool caseSensitive = true,
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.lt,
      include: include,
      property: 'parentId',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      parentIdBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return addFilterConditionInternal(FilterCondition.between(
      property: 'parentId',
      lower: lower,
      includeLower: includeLower,
      upper: upper,
      includeUpper: includeUpper,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      parentIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.startsWith,
      property: 'parentId',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      parentIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.endsWith,
      property: 'parentId',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      parentIdContains(String value, {bool caseSensitive = true}) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.contains,
      property: 'parentId',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      parentIdMatches(String pattern, {bool caseSensitive = true}) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.matches,
      property: 'parentId',
      value: pattern,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      publicKeySenderIsNull() {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.isNull,
      property: 'publicKeySender',
      value: null,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      publicKeySenderEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.eq,
      property: 'publicKeySender',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      publicKeySenderGreaterThan(
    String? value, {
    bool caseSensitive = true,
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.gt,
      include: include,
      property: 'publicKeySender',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      publicKeySenderLessThan(
    String? value, {
    bool caseSensitive = true,
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.lt,
      include: include,
      property: 'publicKeySender',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      publicKeySenderBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return addFilterConditionInternal(FilterCondition.between(
      property: 'publicKeySender',
      lower: lower,
      includeLower: includeLower,
      upper: upper,
      includeUpper: includeUpper,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      publicKeySenderStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.startsWith,
      property: 'publicKeySender',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      publicKeySenderEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.endsWith,
      property: 'publicKeySender',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      publicKeySenderContains(String value, {bool caseSensitive = true}) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.contains,
      property: 'publicKeySender',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      publicKeySenderMatches(String pattern, {bool caseSensitive = true}) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.matches,
      property: 'publicKeySender',
      value: pattern,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      sendingIsNull() {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.isNull,
      property: 'sending',
      value: null,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      sendingEqualTo(bool? value) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.eq,
      property: 'sending',
      value: value,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      successIsNull() {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.isNull,
      property: 'success',
      value: null,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      successEqualTo(bool? value) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.eq,
      property: 'success',
      value: value,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      userIdIsNull() {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.isNull,
      property: 'userId',
      value: null,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      userIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.eq,
      property: 'userId',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      userIdGreaterThan(
    String? value, {
    bool caseSensitive = true,
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.gt,
      include: include,
      property: 'userId',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      userIdLessThan(
    String? value, {
    bool caseSensitive = true,
    bool include = false,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.lt,
      include: include,
      property: 'userId',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      userIdBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return addFilterConditionInternal(FilterCondition.between(
      property: 'userId',
      lower: lower,
      includeLower: includeLower,
      upper: upper,
      includeUpper: includeUpper,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      userIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.startsWith,
      property: 'userId',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      userIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.endsWith,
      property: 'userId',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      userIdContains(String value, {bool caseSensitive = true}) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.contains,
      property: 'userId',
      value: value,
      caseSensitive: caseSensitive,
    ));
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterFilterCondition>
      userIdMatches(String pattern, {bool caseSensitive = true}) {
    return addFilterConditionInternal(FilterCondition(
      type: ConditionType.matches,
      property: 'userId',
      value: pattern,
      caseSensitive: caseSensitive,
    ));
  }
}

extension MessageConversationQueryLinks on QueryBuilder<MessageConversation,
    MessageConversation, QFilterCondition> {}

extension MessageConversationQueryWhereSortBy
    on QueryBuilder<MessageConversation, MessageConversation, QSortBy> {
  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      sortByAction() {
    return addSortByInternal('action', Sort.asc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      sortByActionDesc() {
    return addSortByInternal('action', Sort.desc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      sortByConversationId() {
    return addSortByInternal('conversationId', Sort.asc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      sortByConversationIdDesc() {
    return addSortByInternal('conversationId', Sort.desc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      sortByCount() {
    return addSortByInternal('count', Sort.asc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      sortByCountDesc() {
    return addSortByInternal('count', Sort.desc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      sortByCurrentTime() {
    return addSortByInternal('currentTime', Sort.asc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      sortByCurrentTimeDesc() {
    return addSortByInternal('currentTime', Sort.desc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      sortByFakeId() {
    return addSortByInternal('fakeId', Sort.asc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      sortByFakeIdDesc() {
    return addSortByInternal('fakeId', Sort.desc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      sortById() {
    return addSortByInternal('id', Sort.asc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      sortByIdDesc() {
    return addSortByInternal('id', Sort.desc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      sortByInsertedAt() {
    return addSortByInternal('insertedAt', Sort.asc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      sortByInsertedAtDesc() {
    return addSortByInternal('insertedAt', Sort.desc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      sortByIsBlur() {
    return addSortByInternal('isBlur', Sort.asc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      sortByIsBlurDesc() {
    return addSortByInternal('isBlur', Sort.desc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      sortByIsSystemMessage() {
    return addSortByInternal('isSystemMessage', Sort.asc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      sortByIsSystemMessageDesc() {
    return addSortByInternal('isSystemMessage', Sort.desc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      sortByLastEditedAt() {
    return addSortByInternal('lastEditedAt', Sort.asc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      sortByLastEditedAtDesc() {
    return addSortByInternal('lastEditedAt', Sort.desc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      sortByLocalId() {
    return addSortByInternal('localId', Sort.asc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      sortByLocalIdDesc() {
    return addSortByInternal('localId', Sort.desc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      sortByMessage() {
    return addSortByInternal('message', Sort.asc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      sortByMessageDesc() {
    return addSortByInternal('message', Sort.desc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      sortByMessageParse() {
    return addSortByInternal('messageParse', Sort.asc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      sortByMessageParseDesc() {
    return addSortByInternal('messageParse', Sort.desc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      sortByParentId() {
    return addSortByInternal('parentId', Sort.asc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      sortByParentIdDesc() {
    return addSortByInternal('parentId', Sort.desc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      sortByPublicKeySender() {
    return addSortByInternal('publicKeySender', Sort.asc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      sortByPublicKeySenderDesc() {
    return addSortByInternal('publicKeySender', Sort.desc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      sortBySending() {
    return addSortByInternal('sending', Sort.asc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      sortBySendingDesc() {
    return addSortByInternal('sending', Sort.desc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      sortBySuccess() {
    return addSortByInternal('success', Sort.asc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      sortBySuccessDesc() {
    return addSortByInternal('success', Sort.desc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      sortByUserId() {
    return addSortByInternal('userId', Sort.asc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      sortByUserIdDesc() {
    return addSortByInternal('userId', Sort.desc);
  }
}

extension MessageConversationQueryWhereSortThenBy
    on QueryBuilder<MessageConversation, MessageConversation, QSortThenBy> {
  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      thenByAction() {
    return addSortByInternal('action', Sort.asc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      thenByActionDesc() {
    return addSortByInternal('action', Sort.desc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      thenByConversationId() {
    return addSortByInternal('conversationId', Sort.asc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      thenByConversationIdDesc() {
    return addSortByInternal('conversationId', Sort.desc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      thenByCount() {
    return addSortByInternal('count', Sort.asc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      thenByCountDesc() {
    return addSortByInternal('count', Sort.desc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      thenByCurrentTime() {
    return addSortByInternal('currentTime', Sort.asc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      thenByCurrentTimeDesc() {
    return addSortByInternal('currentTime', Sort.desc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      thenByFakeId() {
    return addSortByInternal('fakeId', Sort.asc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      thenByFakeIdDesc() {
    return addSortByInternal('fakeId', Sort.desc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      thenById() {
    return addSortByInternal('id', Sort.asc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      thenByIdDesc() {
    return addSortByInternal('id', Sort.desc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      thenByInsertedAt() {
    return addSortByInternal('insertedAt', Sort.asc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      thenByInsertedAtDesc() {
    return addSortByInternal('insertedAt', Sort.desc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      thenByIsBlur() {
    return addSortByInternal('isBlur', Sort.asc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      thenByIsBlurDesc() {
    return addSortByInternal('isBlur', Sort.desc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      thenByIsSystemMessage() {
    return addSortByInternal('isSystemMessage', Sort.asc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      thenByIsSystemMessageDesc() {
    return addSortByInternal('isSystemMessage', Sort.desc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      thenByLastEditedAt() {
    return addSortByInternal('lastEditedAt', Sort.asc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      thenByLastEditedAtDesc() {
    return addSortByInternal('lastEditedAt', Sort.desc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      thenByLocalId() {
    return addSortByInternal('localId', Sort.asc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      thenByLocalIdDesc() {
    return addSortByInternal('localId', Sort.desc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      thenByMessage() {
    return addSortByInternal('message', Sort.asc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      thenByMessageDesc() {
    return addSortByInternal('message', Sort.desc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      thenByMessageParse() {
    return addSortByInternal('messageParse', Sort.asc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      thenByMessageParseDesc() {
    return addSortByInternal('messageParse', Sort.desc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      thenByParentId() {
    return addSortByInternal('parentId', Sort.asc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      thenByParentIdDesc() {
    return addSortByInternal('parentId', Sort.desc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      thenByPublicKeySender() {
    return addSortByInternal('publicKeySender', Sort.asc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      thenByPublicKeySenderDesc() {
    return addSortByInternal('publicKeySender', Sort.desc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      thenBySending() {
    return addSortByInternal('sending', Sort.asc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      thenBySendingDesc() {
    return addSortByInternal('sending', Sort.desc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      thenBySuccess() {
    return addSortByInternal('success', Sort.asc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      thenBySuccessDesc() {
    return addSortByInternal('success', Sort.desc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      thenByUserId() {
    return addSortByInternal('userId', Sort.asc);
  }

  QueryBuilder<MessageConversation, MessageConversation, QAfterSortBy>
      thenByUserIdDesc() {
    return addSortByInternal('userId', Sort.desc);
  }
}

extension MessageConversationQueryWhereDistinct
    on QueryBuilder<MessageConversation, MessageConversation, QDistinct> {
  QueryBuilder<MessageConversation, MessageConversation, QDistinct>
      distinctByAction({bool caseSensitive = true}) {
    return addDistinctByInternal('action', caseSensitive: caseSensitive);
  }

  QueryBuilder<MessageConversation, MessageConversation, QDistinct>
      distinctByConversationId({bool caseSensitive = true}) {
    return addDistinctByInternal('conversationId',
        caseSensitive: caseSensitive);
  }

  QueryBuilder<MessageConversation, MessageConversation, QDistinct>
      distinctByCount() {
    return addDistinctByInternal('count');
  }

  QueryBuilder<MessageConversation, MessageConversation, QDistinct>
      distinctByCurrentTime() {
    return addDistinctByInternal('currentTime');
  }

  QueryBuilder<MessageConversation, MessageConversation, QDistinct>
      distinctByFakeId({bool caseSensitive = true}) {
    return addDistinctByInternal('fakeId', caseSensitive: caseSensitive);
  }

  QueryBuilder<MessageConversation, MessageConversation, QDistinct>
      distinctById({bool caseSensitive = true}) {
    return addDistinctByInternal('id', caseSensitive: caseSensitive);
  }

  QueryBuilder<MessageConversation, MessageConversation, QDistinct>
      distinctByInsertedAt({bool caseSensitive = true}) {
    return addDistinctByInternal('insertedAt', caseSensitive: caseSensitive);
  }

  QueryBuilder<MessageConversation, MessageConversation, QDistinct>
      distinctByIsBlur() {
    return addDistinctByInternal('isBlur');
  }

  QueryBuilder<MessageConversation, MessageConversation, QDistinct>
      distinctByIsSystemMessage() {
    return addDistinctByInternal('isSystemMessage');
  }

  QueryBuilder<MessageConversation, MessageConversation, QDistinct>
      distinctByLastEditedAt({bool caseSensitive = true}) {
    return addDistinctByInternal('lastEditedAt', caseSensitive: caseSensitive);
  }

  QueryBuilder<MessageConversation, MessageConversation, QDistinct>
      distinctByLocalId() {
    return addDistinctByInternal('localId');
  }

  QueryBuilder<MessageConversation, MessageConversation, QDistinct>
      distinctByMessage({bool caseSensitive = true}) {
    return addDistinctByInternal('message', caseSensitive: caseSensitive);
  }

  QueryBuilder<MessageConversation, MessageConversation, QDistinct>
      distinctByMessageParse({bool caseSensitive = true}) {
    return addDistinctByInternal('messageParse', caseSensitive: caseSensitive);
  }

  QueryBuilder<MessageConversation, MessageConversation, QDistinct>
      distinctByParentId({bool caseSensitive = true}) {
    return addDistinctByInternal('parentId', caseSensitive: caseSensitive);
  }

  QueryBuilder<MessageConversation, MessageConversation, QDistinct>
      distinctByPublicKeySender({bool caseSensitive = true}) {
    return addDistinctByInternal('publicKeySender',
        caseSensitive: caseSensitive);
  }

  QueryBuilder<MessageConversation, MessageConversation, QDistinct>
      distinctBySending() {
    return addDistinctByInternal('sending');
  }

  QueryBuilder<MessageConversation, MessageConversation, QDistinct>
      distinctBySuccess() {
    return addDistinctByInternal('success');
  }

  QueryBuilder<MessageConversation, MessageConversation, QDistinct>
      distinctByUserId({bool caseSensitive = true}) {
    return addDistinctByInternal('userId', caseSensitive: caseSensitive);
  }
}

extension MessageConversationQueryProperty
    on QueryBuilder<MessageConversation, MessageConversation, QQueryProperty> {
  QueryBuilder<MessageConversation, String?, QQueryOperations>
      actionProperty() {
    return addPropertyNameInternal('action');
  }

  QueryBuilder<MessageConversation, List<String>?, QQueryOperations>
      attachmentsProperty() {
    return addPropertyNameInternal('attachments');
  }

  QueryBuilder<MessageConversation, String?, QQueryOperations>
      conversationIdProperty() {
    return addPropertyNameInternal('conversationId');
  }

  QueryBuilder<MessageConversation, int?, QQueryOperations> countProperty() {
    return addPropertyNameInternal('count');
  }

  QueryBuilder<MessageConversation, int?, QQueryOperations>
      currentTimeProperty() {
    return addPropertyNameInternal('currentTime');
  }

  QueryBuilder<MessageConversation, List<String>?, QQueryOperations>
      dataReadProperty() {
    return addPropertyNameInternal('dataRead');
  }

  QueryBuilder<MessageConversation, String?, QQueryOperations>
      fakeIdProperty() {
    return addPropertyNameInternal('fakeId');
  }

  QueryBuilder<MessageConversation, String?, QQueryOperations> idProperty() {
    return addPropertyNameInternal('id');
  }

  QueryBuilder<MessageConversation, List<String>?, QQueryOperations>
      infoThreadProperty() {
    return addPropertyNameInternal('infoThread');
  }

  QueryBuilder<MessageConversation, String?, QQueryOperations>
      insertedAtProperty() {
    return addPropertyNameInternal('insertedAt');
  }

  QueryBuilder<MessageConversation, bool?, QQueryOperations> isBlurProperty() {
    return addPropertyNameInternal('isBlur');
  }

  QueryBuilder<MessageConversation, bool?, QQueryOperations>
      isSystemMessageProperty() {
    return addPropertyNameInternal('isSystemMessage');
  }

  QueryBuilder<MessageConversation, String?, QQueryOperations>
      lastEditedAtProperty() {
    return addPropertyNameInternal('lastEditedAt');
  }

  QueryBuilder<MessageConversation, int?, QQueryOperations> localIdProperty() {
    return addPropertyNameInternal('localId');
  }

  QueryBuilder<MessageConversation, String?, QQueryOperations>
      messageProperty() {
    return addPropertyNameInternal('message');
  }

  QueryBuilder<MessageConversation, String?, QQueryOperations>
      messageParseProperty() {
    return addPropertyNameInternal('messageParse');
  }

  QueryBuilder<MessageConversation, String?, QQueryOperations>
      parentIdProperty() {
    return addPropertyNameInternal('parentId');
  }

  QueryBuilder<MessageConversation, String?, QQueryOperations>
      publicKeySenderProperty() {
    return addPropertyNameInternal('publicKeySender');
  }

  QueryBuilder<MessageConversation, bool?, QQueryOperations> sendingProperty() {
    return addPropertyNameInternal('sending');
  }

  QueryBuilder<MessageConversation, bool?, QQueryOperations> successProperty() {
    return addPropertyNameInternal('success');
  }

  QueryBuilder<MessageConversation, String?, QQueryOperations>
      userIdProperty() {
    return addPropertyNameInternal('userId');
  }
}
