// utils/check_user_logged_in.dart
import '../app_write_service.dart';

// Synchronous check for user login status
bool checkUserLoggedInSync() {
  try {
    account?.get(); // Sync check (ensure this is called appropriately)
    return true;
  } catch (e) {
    return false;
  }
}
