import 'package:get_it/get_it.dart';
import '../external_services/secure_storage.dart';
import '../external_services/supabase_auth_service.dart';
import '../features/auth/services/auth_services.dart';
import '../features/pets/services/pet_service.dart';
import '../features/sign_in/sign_in_controller.dart';
import '../features/sign_up/sign_up_controller.dart';
import '../services/connectivity_service.dart';
import '../features/home/timeline/services/post_service.dart';
import '../features/notifications/notifications.dart';
import '../features/home/timeline/services/story_service.dart';
import '../features/family/services/family_service.dart';
import '../features/pets/services/follow_service.dart';
import 'package:patas_web_app/src/features/auth/services/user_database_service.dart';
import '../features/splash/splash_controller.dart';
import 'package:patas_web_app/src/features/ongs_corp/services/ong_service.dart';
import 'package:patas_web_app/src/features/ongs_corp/services/corp_service.dart';

final locator = GetIt.instance;

void setupDependencies() {
  locator.registerLazySingleton<SecureStorage>(() => const SecureStorage());
  locator
      .registerLazySingleton<UserDatabaseService>(() => UserDatabaseService());

  locator.registerLazySingleton<ConnectivityService>(
    () => ConnectivityService(),
  );

  locator.registerFactory<AuthService>(
    () => SupabaseAuthService(), // Changed to SupabaseAuthService
  );

  locator.registerFactory<SignInController>(
    () => SignInController(
      authService: locator.get<AuthService>(),
      secureStorage: locator.get<SecureStorage>(),
    ),
  );

  locator.registerFactory<SignUpController>(
    () => SignUpController(
      authService: locator.get<AuthService>(),
      secureStorage: locator.get<SecureStorage>(),
    ),
  );

  locator.registerFactory<SplashController>(
    () => SplashController(
      secureStorage: locator.get<SecureStorage>(),
      petServiceCallback: (userId) => PetService().getPetsByUserId(userId),
      ongServiceCallback: (userId) => OngService().getUserOngProfiles(userId),
      corpServiceCallback: (userId) =>
          CorpService().getUserCorpProfiles(userId),
      connectivityService: locator.get<ConnectivityService>(),
    ),
  );

  // Registering Services
  locator.registerLazySingleton<PetService>(() => PetService());
  locator.registerLazySingleton<PostService>(() => PostService());
  locator.registerLazySingleton<StoryService>(() => StoryService());
  locator.registerLazySingleton<FamilyService>(() => FamilyService());
  locator.registerLazySingleton<FollowService>(() => FollowService());
  locator
      .registerLazySingleton<NotificationService>(() => NotificationService());
}
