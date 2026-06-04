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
  static const String confirmed = 'Confirmé';

  // Splash
  static const String splashLoading = 'Initialisation…';
  static const String smartAttendance = 'Système de présence intelligent';

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
  static const String cameraErrorLabel = 'Erreur';

  // Validation
  static const String validateAttendance = 'Valider la présence';
  static const String firstName = 'Prénom';
  static const String lastName = 'Nom';
  static const String codeMassar = 'Code Massar';
  static const String submitAttendance = 'Confirmer la présence';
  static const String validating = 'Validation en cours…';
  static const String qrDetected = 'Code QR détecté';
  static const String noToken = 'Aucun jeton';
  static const String valid = 'Valide';
  static const String studentInformation = 'Informations étudiant';
  static const String verifyDetailsHint =
      'Vérifiez que vos informations correspondent aux données de l\'établissement.';
  static const String firstNameHint = 'ex. Mohammed';
  static const String lastNameHint = 'ex. Alaoui';
  static const String codeMassarHint = 'ex. M123456789';
  static const String codeMassarHelper =
      'Votre code d\'identification officiel';
  static const String noQrToken = 'Aucun code QR. Veuillez scanner à nouveau.';
  static const String scanDifferentQr = 'Scanner un autre code QR';

  // Succès
  static const String attendanceRegistered = 'Présence enregistrée !';
  static const String attendanceRegisteredDesc =
      'Votre présence a bien été enregistrée\npour cette séance.';
  static const String attendanceReceipt = 'Reçu de présence';
  static const String attendanceId = 'ID de présence';
  static const String backToHome = 'Retour à l\'accueil';

  // Erreurs — titres
  static const String errorOccurred = 'Une erreur est survenue';
  static const String unexpectedError =
      'Une erreur inattendue s\'est produite. Réessayez.';
  static const String whatToDoNext = 'Que faire ensuite';
  static const String errorCodeLabel = 'Code d\'erreur';
  static const String scanQrAgain = 'Scanner à nouveau';
  static const String noInternet = 'Pas de connexion Internet.';
  static const String requestTimeout = 'Délai de la requête dépassé.';
  static const String errQrExpired = 'QR expiré';
  static const String errDuplicate = 'Déjà enregistré';
  static const String errInvalidToken = 'QR invalide';
  static const String errSessionInactive = 'Séance fermée';
  static const String errStudentNotFound = 'Étudiant introuvable';
  static const String errNameMismatch = 'Nom incorrect';
  static const String errNoInternet = 'Pas de réseau';
  static const String errTimeout = 'Délai dépassé';
  static const String errUnknown = 'Erreur inconnue';

  // Erreurs — conseils
  static const List<String> tipsExpired = [
    'Demandez à votre enseignant de générer un nouveau code QR.',
    'Les codes QR sont limités dans le temps. Scannez rapidement.',
    'Vérifiez l\'heure de votre appareil.',
  ];
  static const List<String> tipsAlreadyValidated = [
    'Votre présence est déjà enregistrée. Aucune action requise.',
    'Chaque étudiant ne peut s\'enregistrer qu\'une fois par séance.',
    'Contactez votre enseignant en cas d\'erreur.',
  ];
  static const List<String> tipsInvalidQr = [
    'Scannez le code QR de présence affiché par l\'enseignant.',
    'N\'utilisez pas de codes QR d\'autres applications.',
    'Demandez à l\'enseignant d\'afficher le code clairement.',
  ];
  static const List<String> tipsSessionClosed = [
    'L\'enseignant a fermé la fenêtre de présence pour cette séance.',
    'Arrivez à l\'heure pour les prochaines séances.',
    'Contactez l\'enseignant si vous étiez présent sans pouvoir scanner.',
  ];
  static const List<String> tipsStudentNotFound = [
    'Vérifiez que votre code Massar est correct.',
    'Assurez-vous d\'être inscrit à ce cours.',
    'Contactez l\'administration si votre compte est absent.',
  ];
  static const List<String> tipsNameMismatch = [
    'Vérifiez que votre prénom et nom correspondent aux registres.',
    'Contrôlez l\'orthographe et les espaces.',
    'Utilisez le nom officiel, pas un surnom.',
  ];
  static const List<String> tipsNoInternet = [
    'Vérifiez votre connexion Wi‑Fi ou données mobiles.',
    'Déplacez-vous vers une zone avec meilleur réseau.',
    'Désactivez puis réactivez le Wi‑Fi ou les données.',
  ];
  static const List<String> tipsTimeout = [
    'Si vous utilisez Render, ouvrez l\'URL de l\'API dans le navigateur puis réessayez.',
    'Vérifiez le réseau et réessayez après 30 à 60 secondes.',
    'En local : lancez Django avec runserver 0.0.0.0:8000 et DEV_HOST = IP du PC.',
  ];
  static const List<String> tipsUnknown = [
    'Réessayez en scannant depuis l\'accueil.',
    'Assurez-vous que l\'application est à jour.',
    'Si le problème persiste, contactez l\'enseignant ou le support.',
  ];
}
