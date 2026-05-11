import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiConstants {
  ApiConstants._();

  // Injected at build/run time via:
  //   flutter run  --dart-define=API_BASE_URL=http://10.0.2.2:5000/api/v1   (Android emulator)
  //   flutter run  --dart-define=API_BASE_URL=http://192.168.x.x:5000/api/v1 (physical device)
  //   flutter build apk --dart-define=API_BASE_URL=https://your-server.com/api/v1
  //
  // Falls back to localhost for Windows desktop development when no flag is passed.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, dynamic> decodeResponse(http.Response response) {
    return json.decode(response.body);
  }

  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  static const String blasts = '/blasts';
  static const String blastNextNumber = '/blasts/next-number';
  static const String blastActive = '/blasts/active';
  static const String blastTrips = '/blasts/trips';
  static const String blastExpenses = '/blasts/expenses';

  static const String vehicles = '/vehicles';
  static const String vehicleExpiries = '/vehicles/expiries';
  static const String vehicleUsage = '/vehicles/usage';
  static const String vehicleDailyUsage = '/vehicles/usage/daily';

  static const String diesel = '/diesel';
  static const String dieselStock = '/diesel/stock';
  static const String dieselPurchases = '/diesel/purchases';
  static const String dieselConsumption = '/diesel/consumption';
  static const String dieselVehicleWise = '/diesel/consumption/vehicle-wise';
  static const String dieselPumpWise = '/diesel/pump-wise';

  static const String settings = '/settings';
  static const String settingsBulk = '/settings/bulk';
  static const String settingsExport = '/settings/export';
  static const String settingsImport = '/settings/import';
  static const String settingsReset = '/settings/reset';
  static const String settingsCompany = '/settings/company';
  static const String settingsInvoice = '/settings/invoice';
  static const String settingsAlerts = '/settings/alerts';

  static const int connectTimeout = 10000;
  static const int receiveTimeout = 15000;
}
