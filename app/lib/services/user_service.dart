import '../models/user.dart';
import 'api_client.dart';

class UserService {
  final ApiClient _api;
  UserService(this._api);

  Future<List<User>> list() async {
    final data = await _api.get('/users') as List;
    return data.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
  }
}
