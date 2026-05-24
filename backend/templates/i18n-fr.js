/**
 * Textes français — tableaux de bord web PrésenceQR
 */
window.I18N = {
  appName: 'PrésenceQR',
  appTagline: 'Gestion de présence par QR',
  logout: 'Déconnexion',
  loading: 'Chargement…',
  present: 'Présent',
  live: 'En direct',
  connecting: 'Connexion…',
  disconnected: 'Déconnecté',
  connectionError: 'Erreur de connexion',
  wsUnavailable: 'WebSocket indisponible',
  cancel: 'Annuler',
  create: 'Créer',
  add: 'Ajouter',
  allCourses: 'Tous les cours',
  allSessions: 'Toutes les séances',
  noRecords: 'Aucune présence enregistrée.',
  failedLoad: 'Échec du chargement',
  success: 'Opération réussie',
  students: 'étudiants',
  scans: 'scans',

  // Connexion
  welcomeBack: 'Bon retour',
  signInSubtitle: 'Connectez-vous pour continuer',
  email: 'Adresse e-mail',
  password: 'Mot de passe',
  signIn: 'Se connecter',
  fillBothFields: 'Veuillez remplir tous les champs.',
  welcomeRedirect: 'Bienvenue, {name} ! Redirection…',
  invalidCredentials: 'Identifiants incorrects. Réessayez.',

  // Rôles
  roleAdmin: 'Administrateur',
  roleTeacher: 'Enseignant',
  roleStudent: 'Étudiant',

  // Admin
  adminDashboard: 'Tableau de bord administrateur',
  adminSubtitle: 'Gérez les utilisateurs, étudiants, cours et consultez les présences en direct.',
  tabLiveAttendance: 'Présences en direct',
  tabUsers: 'Utilisateurs',
  tabStudents: 'Étudiants',
  tabCourses: 'Cours',
  allUsers: 'Tous les utilisateurs',
  allStudents: 'Tous les étudiants',
  allCoursesTitle: 'Tous les cours',
  newUser: 'Nouvel utilisateur',
  addStudent: 'Ajouter un étudiant',
  newCourse: 'Nouveau cours',
  statTotal: 'Total des enregistrements',
  statToday: "Aujourd'hui",
  statActiveCourses: 'Cours actifs',
  markedPresent: '{name} marqué présent ({course})',
  deviceAlreadyUsed: 'Cet appareil a déjà été utilisé pour cette séance.',

  // Enseignant
  myCourses: 'Mes cours',
  liveFeed: 'En direct',
  selectSession: 'Sélectionnez une séance',
  selectSessionHint: 'Choisissez un cours et une séance pour gérer les présences et générer un QR.',
  liveAttendance: 'Présences en direct',
  liveAttendanceSub: 'Scans en temps réel sur tous vos cours',
  recentScans: 'Scans récents',
  noAttendanceYet: 'Aucune présence. Sélectionnez une séance et générez un QR.',
  generateQr: 'Générer le QR',
  exportExcel: 'Exporter Excel',
  attendance: 'Présences',
  newSession: 'Nouvelle séance',
  sessionDate: 'Date de la séance',
  qrActive: 'Code QR actif',
  expiresAt: 'Expire à',
  duration: 'Durée',
  minutes20: '20 minutes',
  remaining: 'restant',
  enlargeQr: 'Agrandir le QR',
  regenerate: 'Régénérer',
  qrExpired: 'QR expiré',
  qrGenerated: 'Code QR généré ! (20 min)',
  excelDownloaded: 'Fichier Excel téléchargé !',
  studentScanned: '{name} vient de scanner !',
  noCourses: 'Aucun cours assigné.',
  sessions: 'Séances',
  noSessions: 'Aucune séance. Cliquez sur « + Nouvelle ».',
};

window.t = function (key, vars) {
  let s = window.I18N[key] || key;
  if (vars) {
    Object.keys(vars).forEach((k) => {
      s = s.replace(`{${k}}`, vars[k]);
    });
  }
  return s;
};
