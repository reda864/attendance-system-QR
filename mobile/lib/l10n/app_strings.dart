/// Textes de l'application en français.
abstract final class AppStrings {
  static const String appName = 'PrésenceQR';
  static const String appTagline = 'Système de présence par QR';

  // Commun
  static const String cancel = 'Annuler';
  static const String retry = 'Réessayer';
  static const String refresh = 'Actualiser';
  static const String or = 'ou';
  static const String loading = 'Chargement…';
  static const String present = 'Présent';
  static const String student = 'Étudiant';
  static const String guest = 'Invité';

  // Splash
  static const String splashLoading = 'Chargement…';

  // Connexion
  static const String welcomeBack = 'Bon retour';
  static const String signInSubtitle = 'Connectez-vous pour enregistrer votre présence';
  static const String email = 'Adresse e-mail';
  static const String emailHint = 'etudiant@exemple.ma';
  static const String password = 'Mot de passe';
  static const String passwordHint = 'Saisissez votre mot de passe';
  static const String rememberMe = 'Se souvenir de moi';
  static const String signIn = 'Se connecter';
  static const String continueAsGuest = 'Continuer en invité';
  static const String loginInfo =
      'Utilisez votre e-mail institutionnel et votre mot de passe';
  static const String loginFailed = 'Échec de la connexion. Réessayez.';

  // Accueil
  static const String signOut = 'Déconnexion';
  static const String signOutConfirm =
      'Voulez-vous vraiment vous déconnecter ?';
  static const String toggleTheme = 'Changer le thème';
  static const String signInAction = 'Connexion';
  static const String recentActivity = 'Activité récente';
  static const String scanQr = 'Scanner le QR';
  static const String goodMorning = 'Bonjour';
  static const String goodAfternoon = 'Bon après-midi';
  static const String goodEvening = 'Bonsoir';
  static const String readyToScan = 'Prêt à scanner';
  static const String scanQrCode = 'Scanner le code QR';
  static const String scanQrHint =
      'Pointez la caméra vers le QR\nde l\'enseignant pour marquer la présence';
  static const String tapToOpenScanner = 'Appuyez pour ouvrir le scanner';
  static const String tipConnected = 'Restez connecté';
  static const String tipConnectedDesc =
      'Assurez-vous d\'avoir une connexion Internet';
  static const String tipOnTime = 'Scannez à l\'heure';
  static const String tipOnTimeDesc =
      'Les codes QR expirent après la séance';
  static const String tipOneScan = 'Un scan par séance';
  static const String tipOneScanDesc = 'Les scans en double sont bloqués';
  static const String historyLoadError =
      'Impossible de charger l\'historique de présence.';
  static const String codeLabel = 'Code';
  static const String sessionLabel = 'Séance';
  static const String noAttendanceYet = 'Aucune présence enregistrée';
  static const String noAttendanceHint =
      'Scannez un code QR pour enregistrer\nvotre première présence';
  static const String couldNotLoadHistory = 'Impossible de charger l\'historique';
  static const String tryAgain = 'Réessayer';

  // Scanner QR
  static const String scanQrTitle = 'Scanner le QR';
  static const String invalidQr =
      'Code QR invalide. Scannez le QR de présence de l\'enseignant.';
  static const String alignQr = 'Alignez le code QR dans le cadre';
  static const String toggleFlash = 'Activer la lampe';
  static const String flipCamera = 'Changer de caméra';
  static const String processingQr = 'Traitement du code QR…';
  static const String cameraUnavailable = 'Caméra indisponible';
  static const String cameraPermission =
      'Impossible d\'accéder à la caméra.\n'
      'Autorisez l\'accès à la caméra dans les paramètres.';

  // Validation
  static const String validateAttendance = 'Valider la présence';
  static const String firstName = 'Prénom';
  static const String lastName = 'Nom';
  static const String codeMassar = 'Code Massar';
  static const String submitAttendance = 'Confirmer la présence';
  static const String validating = 'Validation en cours…';

  // Succès
  static const String attendanceRegistered = 'Présence enregistrée !';
  static const String attendanceRegisteredDesc =
      'Votre présence a bien été enregistrée\npour cette séance.';
  static const String attendanceReceipt = 'Reçu de présence';
  static const String attendanceId = 'ID de présence';
  static const String backToHome = 'Retour à l\'accueil';

  // Erreurs
  static const String errorOccurred = 'Une erreur est survenue';
  static const String unexpectedError =
      'Une erreur inattendue s\'est produite. Réessayez.';
  static const String whatToDoNext = 'Que faire ensuite';
  static const String errorCode = 'Code d\'erreur';
  static const String scanQrAgain = 'Scanner à nouveau';
  static const String noInternet = 'Pas de connexion Internet.';
  static const String requestTimeout = 'Délai de la requête dépassé.';
}
