import 'package:flutter_auth_ui/flutter_auth_ui.dart';

class LoginPage {
  static Future<bool> login() async {
    final providers = [
      // AuthUiProvider.anonymous,
      AuthUiProvider.email,
      // AuthUiProvider.phone,
    ];

    bool result = await FlutterAuthUi.startUi(
      items: providers,
      autoUpgradeAnonymousUsers: true,
      tosAndPrivacyPolicy: TosAndPrivacyPolicy(
        tosUrl: "https://efato132.web.app/",
        privacyPolicyUrl: "https://efato132.web.app/",
      ),
      androidOption: AndroidOption(
        enableSmartLock: false, // default true
        showLogo: true, // default false
        overrideTheme: true, // default false
      ),
      emailAuthOption: EmailAuthOption(
        requireDisplayName: true, // default true
        enableMailLink: false, // default false
        handleURL: '',
        androidPackageName: '',
        androidMinimumVersion: '',
      ),
    );

    return result;
  }
}