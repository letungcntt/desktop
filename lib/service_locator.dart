import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:stacked_services/stacked_services.dart';

import 'models/models.dart';
import 'services/sharedprefsutil.dart';

GetIt sl = GetIt.instance;

void setupServiceLocator() {
  sl.registerLazySingleton<SharedPrefsUtil>(() => SharedPrefsUtil());
  sl.registerLazySingleton<Logger>(() => Logger(printer: PrettyPrinter()));
  sl.registerLazySingleton<Auth>(() => Auth());
  sl.registerLazySingleton<DialogService>(() => DialogService());
  sl.registerLazySingleton<NavigationService>(() => NavigationService());
}