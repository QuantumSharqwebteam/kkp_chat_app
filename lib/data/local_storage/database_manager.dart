import 'package:kkpchatapp/data/local_storage/product_database.dart';

class DatabaseManager {
  static final DatabaseManager _instance = DatabaseManager._internal();
  late final ProductDatabase database;

  factory DatabaseManager() {
    return _instance;
  }

  DatabaseManager._internal();

  Future<void> initialize() async {
    database = ProductDatabase();
  }
}
