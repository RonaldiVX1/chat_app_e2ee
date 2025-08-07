import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepository = AuthRepository();
  
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  
  final isLoading = false.obs;
  final currentUser = Rxn<UserModel>();

  @override
  void onInit() {
    super.onInit();
    checkUserLoggedIn();
  }

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  Future<void> checkUserLoggedIn() async {
    isLoading.value = true;
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        currentUser.value = user;
        Get.offAllNamed(AppRoutes.home);
      }
    } catch (e) {
      print('Error checking logged in user: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register() async {
    if (_validateInputs() == false) return;
    
    isLoading.value = true;
    try {
      final user = await _authRepository.register(
        usernameController.text.trim(),
        passwordController.text.trim(),
      );
      
      if (user != null) {
        currentUser.value = user;
        _clearInputs();
        Get.offAllNamed(AppRoutes.home);
        Fluttertoast.showToast(msg: 'Registration successful');
      } else {
        Fluttertoast.showToast(msg: 'Registration failed');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> login() async {
    if (_validateInputs() == false) return;
    
    isLoading.value = true;
    try {
      final user = await _authRepository.login(
        usernameController.text.trim(),
        passwordController.text.trim(),
      );
      
      if (user != null) {
        currentUser.value = user;
        _clearInputs();
        Get.offAllNamed(AppRoutes.home);
        Fluttertoast.showToast(msg: 'Login successful');
      } else {
        Fluttertoast.showToast(msg: 'Login failed. Check your credentials.');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    isLoading.value = true;
    try {
      await _authRepository.logout();
      currentUser.value = null;
      Get.offAllNamed(AppRoutes.login);
      Fluttertoast.showToast(msg: 'Logged out successfully');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error logging out: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  bool _validateInputs() {
    if (usernameController.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: 'Username cannot be empty');
      return false;
    }
    
    if (passwordController.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: 'Password cannot be empty');
      return false;
    }
    
    
    return true;
  }

  void _clearInputs() {
    usernameController.clear();
    passwordController.clear();
  }
}