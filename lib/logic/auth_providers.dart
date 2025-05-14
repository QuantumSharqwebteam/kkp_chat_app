import 'package:kkpchatapp/logic/auth/login_provider.dart';
import 'package:provider/provider.dart';

final List<ChangeNotifierProvider> authProviders = [
  ChangeNotifierProvider(create: (context) => LoginProvider()),
];
