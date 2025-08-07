import 'package:get/get.dart';
import '../modules/auth/bindings/auth_binding.dart';
import '../modules/auth/views/login_view.dart';
import '../modules/auth/views/register_view.dart';
import '../modules/chat/bindings/chat_binding.dart';
import '../modules/chat/views/chat_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';

class AppRoutes {
  static const String initial = '/login';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String chat = '/chat';

  static final routes = [
    GetPage(
      name: login,
      page: () => LoginView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: register,
      page: () => RegisterView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: home,
      page: () => HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: chat,
      page: () => ChatView(),
      binding: ChatBinding(),
    ),
  ];
}