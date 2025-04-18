import 'dart:async';
import 'package:gsy_github_app_flutter/common/utils/code_utils.dart';

import 'package:flutter/foundation.dart';
import 'package:gsy_github_app_flutter/db/sql_provider.dart';
import 'package:gsy_github_app_flutter/model/event.dart';
import 'package:sqflite/sqflite.dart';

/// 仓库活跃事件表
/// Created by guoshuyu
/// Date: 2018-08-07

class RepositoryEventDbProvider extends BaseDbProvider {
  final String name = 'RepositoryEvent';

  final String columnId = "_id";
  final String columnFullName = "fullName";
  final String columnData = "data";

  int? id;
  String? fullName;
  String? data;

  RepositoryEventDbProvider();

  Map<String, dynamic> toMap(String? fullName, String data) {
    Map<String, dynamic> map = {columnFullName: fullName, columnData: data};
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  RepositoryEventDbProvider.fromMap(Map map) {
    id = map[columnId];
    fullName = map[columnFullName];
    data = map[columnData];
  }

  @override
  tableSqlString() {
    return tableBaseString(name, columnId) +
        '''
        $columnFullName text not null,
        $columnData text not null)
      ''';
  }

  @override
  tableName() {
    return name;
  }

  Future _getProvider(Database db, String? fullName) async {
    List<Map<String, dynamic>> maps = await db.query(name,
        columns: [columnId, columnFullName, columnData],
        where: "$columnFullName = ?",
        whereArgs: [fullName]);
    if (maps.isNotEmpty) {
      RepositoryEventDbProvider provider =
          RepositoryEventDbProvider.fromMap(maps.first);
      return provider;
    }
    return null;
  }

  ///插入到数据库
  Future insert(String? fullName, String dataMapString) async {
    Database db = await getDataBase();
    var provider = await _getProvider(db, fullName);
    if (provider != null) {
      await db
          .delete(name, where: "$columnFullName = ?", whereArgs: [fullName]);
    }
    return await db.insert(name, toMap(fullName, dataMapString));
  }

  ///获取事件数据
  Future<List<Event>?> getEvents(String? fullName) async {
    Database db = await getDataBase();

    var provider = await _getProvider(db, fullName);
    if (provider != null) {
      List<Event> list = [];

      ///使用 compute 的 Isolate 优化 json decode
      List<dynamic> eventMap =
          await compute(CodeUtils.decodeListResult, provider.data as String?);

      if (eventMap.isNotEmpty) {
        for (var item in eventMap) {
          list.add(Event.fromJson(item));
        }
      }
      return list;
    }
    return null;
  }
}
