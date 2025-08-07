import 'package:get/get.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/providers/user_storage.dart';
import '../../../routes/app_routes.dart';

class HomeController extends GetxController {
  final ChatRepository _chatRepository = ChatRepository();
  final UserStorage _userStorage = UserStorage();
  
  final users = <UserModel>[].obs;
  final isLoading = false.obs;
  final currentUser = Rxn<UserModel>();
  
  @override
  void onInit() {
    super.onInit();
    _loadCurrentUser();
    fetchUsers();
  }
  
  Future<void> _loadCurrentUser() async {
    try {
      final user = await _userStorage.getUser();
      if (user != null) {
        currentUser.value = user;
      }
    } catch (e) {
      print('Error loading current user: $e');
    }
  }
  
  Future<void> fetchUsers() async {
    isLoading.value = true;
    try {
      final usersList = await _chatRepository.getUsers();
      users.value = usersList.where((user) => 
        user.id != currentUser.value?.id
      ).toList();
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error fetching users: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
  
  void navigateToChat(UserModel user) {
    Get.toNamed(
      AppRoutes.chat,
      arguments: user,
    );
  }
  
  void logout() {
    _userStorage.clearUser();
    currentUser.value = null;
    Get.offAllNamed(AppRoutes.login);
  }
}