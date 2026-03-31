// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Spetaka';

  @override
  String get navDaily => 'Actions proposées';

  @override
  String get navFriends => 'Amis';

  @override
  String get navSettings => 'Paramètres';

  @override
  String shellPageIndicatorSemantics(String page) {
    return 'Page active : $page. Balayez à gauche ou à droite pour changer de page.';
  }

  @override
  String get actionAdd => 'Ajouter';

  @override
  String get actionSave => 'Enregistrer';

  @override
  String get actionCancel => 'Annuler';

  @override
  String get actionDelete => 'Supprimer';

  @override
  String get actionEdit => 'Modifier';

  @override
  String get actionReset => 'Réinitialiser';

  @override
  String get actionBack => 'Retour';

  @override
  String get actionContinue => 'Continuer';

  @override
  String get actionRename => 'Renommer';

  @override
  String get actionFlag => 'Signaler';

  @override
  String get actionClear => 'Effacer';

  @override
  String get actionConfirm => 'Confirmer';

  @override
  String get somethingWentWrong =>
      'Une erreur s\'est produite. Veuillez réessayer.';

  @override
  String get couldNotSave => 'Impossible d\'enregistrer. Veuillez réessayer.';

  @override
  String get friendsTitle => 'Amis';

  @override
  String get addFriendTooltip => 'Ajouter un ami';

  @override
  String get addFirstFriend => 'Ajouter un premier ami';

  @override
  String get emptyFriendsTitle => 'Pas encore d\'amis.';

  @override
  String get emptyFriendsSubtitle =>
      'Appuyez sur le bouton ci-dessous pour ajouter votre premier ami.';

  @override
  String get addFriendTitle => 'Ajouter un ami';

  @override
  String get editFriendTitle => 'Modifier l\'ami';

  @override
  String get howToAddFriend => 'Comment souhaitez-vous ajouter cet ami ?';

  @override
  String get importFromContacts => 'Importer depuis les contacts';

  @override
  String get enterManually => 'Saisir manuellement';

  @override
  String get enterDetails => 'Saisir les détails';

  @override
  String get categoryTagsLabel => 'Étiquettes de catégorie';

  @override
  String get nameLabel => 'Nom';

  @override
  String get mobileLabel => 'Téléphone';

  @override
  String get mobilePlaceholder => 'ex. 06 12 34 56 78';

  @override
  String get notesLabel => 'Notes';

  @override
  String get optionalContextNotes => 'Notes de contexte (optionnel)…';

  @override
  String get friendTitle => 'Ami';

  @override
  String get fullDetails => 'Détails complets';

  @override
  String fullDetailsSemantics(String name) {
    return 'Détails complets pour $name';
  }

  @override
  String get deleteFriendTitle => 'Supprimer l\'ami ?';

  @override
  String get flagConcernTitle => 'Signaler une préoccupation';

  @override
  String get clearConcernTitle => 'Effacer la préoccupation ?';

  @override
  String get clearConcernAction => 'Effacer';

  @override
  String get concernLabel => 'Préoccupation';

  @override
  String get concernInactiveSummary => 'Aucune préoccupation signalée.';

  @override
  String get concernFlaggedTooltip => 'Préoccupation signalée';

  @override
  String get concernFlaggedSemanticsSuffix => 'préoccupation signalée';

  @override
  String get eventsLabel => 'Événements';

  @override
  String get addEventAction => 'Ajouter un événement';

  @override
  String get contactHistorySection => 'Historique des contacts';

  @override
  String get noContactHistory => 'Pas encore d\'historique de contact.';

  @override
  String get logContactTitle => 'Noter contact';

  @override
  String get confirmContactLog => 'Confirmer la prise de contact';

  @override
  String get howDidItGo => 'Comment ça s\'est passé ?';

  @override
  String get callAction => 'Appeler';

  @override
  String get smsAction => 'SMS';

  @override
  String get whatsappAction => 'WhatsApp';

  @override
  String get savesContactHistory => 'Enregistre dans l\'historique';

  @override
  String get addEventTitle => 'Ajouter un événement';

  @override
  String get editEventTitle => 'Modifier l\'événement';

  @override
  String get invalidEventIdMessage => 'Identifiant d\'événement invalide.';

  @override
  String get couldNotLoadEventMessage => 'Impossible de charger l\'événement.';

  @override
  String get eventNotFoundMessage => 'Événement introuvable.';

  @override
  String get deleteEventTitle => 'Supprimer l\'événement ?';

  @override
  String get eventTypeLabel => 'Type d\'événement';

  @override
  String get dateLabel => 'Date';

  @override
  String get recurringLabel => 'Récurrent';

  @override
  String get checkInCadence => 'Définir une fréquence de contact';

  @override
  String get commentOptional => 'Commentaire (optionnel)';

  @override
  String get addNoteHint => 'Ajouter une note…';

  @override
  String get optionalNoteHint => 'Note optionnelle…';

  @override
  String get everyWeek => 'Chaque semaine';

  @override
  String get every2Weeks => 'Toutes les 2 semaines';

  @override
  String get every3Weeks => 'Toutes les 3 semaines';

  @override
  String get monthly => 'Mensuel';

  @override
  String get every2Months => 'Tous les 2 mois';

  @override
  String get every3Months => 'Tous les 3 mois';

  @override
  String get every6Months => 'Tous les 6 mois';

  @override
  String get everyYear => 'Chaque année';

  @override
  String get couldNotLoadEventTypes =>
      'Impossible de charger les types d\'événements.';

  @override
  String get invalidNameFallback => 'Nom invalide.';

  @override
  String eventTypeInUseNotice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '# événements utilisent ce type — ils conserveront leur libellé actuel.',
      one: '# événement utilise ce type — il conservera son libellé actuel.',
    );
    return '$_temp0';
  }

  @override
  String get eventTypesTitle => 'Types d\'événements';

  @override
  String get newEventTypePlaceholder => 'Nouveau type d\'événement…';

  @override
  String get addTypeTooltip => 'Ajouter un type';

  @override
  String get renameEventTypeTitle => 'Renommer le type d\'événement';

  @override
  String get deleteEventTypeTitle => 'Supprimer le type d\'événement ?';

  @override
  String get noEventTypes => 'Aucun type. Ajoutez-en un ci-dessus.';

  @override
  String deleteEntryConfirm(String name) {
    return 'Supprimer « $name » ?';
  }

  @override
  String get categoryTagsTitle => 'Étiquettes';

  @override
  String get resetToDefaultTagsTooltip => 'Réinitialiser par défaut';

  @override
  String get addTagTooltip => 'Ajouter une étiquette';

  @override
  String get noTagsYet =>
      'Pas encore d\'étiquettes. Appuyez sur + pour en ajouter.';

  @override
  String get tagsWeightHelp =>
      'Les étiquettes contrôlent le score de priorité. Un poids plus élevé = priorité plus haute dans les actions proposées. Faites glisser pour réorganiser.';

  @override
  String get resetToDefaultsTitle => 'Réinitialiser par défaut ?';

  @override
  String get resetToDefaultsContent =>
      'Cela restaurera les 5 étiquettes et pondérations originales. Toute étiquette personnalisée sera perdue.';

  @override
  String get deleteTagTitle => 'Supprimer l\'étiquette ?';

  @override
  String deleteTagContent(String name) {
    return 'Supprimer « $name » ? Les amis ayant cette étiquette la conserveront, mais son score sera celui par défaut.';
  }

  @override
  String get addTagTitle => 'Ajouter une étiquette';

  @override
  String get editTagTitle => 'Modifier l\'étiquette';

  @override
  String get tagNameLabel => 'Nom de l\'étiquette';

  @override
  String get tagNamePlaceholder => 'ex. Famille';

  @override
  String get weightLabel => 'Pondération';

  @override
  String get weightPlaceholder => 'ex. 2.5';

  @override
  String get weightHelperText =>
      'Nombre positif — plus élevé = plus de priorité';

  @override
  String weightValueLabel(String value) {
    return 'Pondération : $value';
  }

  @override
  String dragToReorder(String name) {
    return 'Faire glisser pour réorganiser $name';
  }

  @override
  String editItemSemantics(String name) {
    return 'Modifier $name';
  }

  @override
  String deleteItemSemantics(String name) {
    return 'Supprimer $name';
  }

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get backupSectionTitle => 'Sauvegarde & Restauration';

  @override
  String get backupPassphraseNote =>
      'Votre phrase secrète chiffre votre sauvegarde. Elle n\'est jamais stockée. Si vous la perdez, votre sauvegarde ne pourra pas être récupérée.';

  @override
  String get exportBackupLabel => 'Exporter la sauvegarde';

  @override
  String get importBackupLabel => 'Importer une sauvegarde';

  @override
  String get resetBackupSettingsLabel =>
      'Réinitialiser les paramètres de sauvegarde';

  @override
  String get exportBackupSemantics => 'Exporter la sauvegarde chiffrée';

  @override
  String get importBackupSemantics =>
      'Importer une sauvegarde chiffrée depuis un fichier';

  @override
  String get resetEncryptionKeyTitle => 'Réinitialiser la clé de chiffrement';

  @override
  String get resetEncryptionKeyContent =>
      'Cela va générer une nouvelle clé de chiffrement pour cet appareil et re-chiffrer toutes vos données. Vos fichiers de sauvegarde existants ne sont PAS affectés — ils ont leur propre phrase secrète.';

  @override
  String get displaySectionTitle => 'Affichage';

  @override
  String get compactViewLabel => 'Vue compacte';

  @override
  String get compactViewSubtitle => 'Afficher plus d\'amis à l\'écran';

  @override
  String get compactViewOn => 'Vue compacte, activée';

  @override
  String get compactViewOff => 'Vue compacte, désactivée';

  @override
  String get darkModeLabel => 'Mode sombre';

  @override
  String get fontSizeLabel => 'Taille de police';

  @override
  String get iconSizeLabel => 'Taille des icônes';

  @override
  String get languageLabel => 'Langue';

  @override
  String get sizeSmall => 'Petite';

  @override
  String get sizeMedium => 'Normale';

  @override
  String get sizeLarge => 'Grande';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageEnglish => 'English';

  @override
  String get categoryTagsSectionTitle => 'Étiquettes';

  @override
  String get manageCategoryTagsLabel => 'Gérer les étiquettes';

  @override
  String get editNamesWeightsSubtitle => 'Modifier les noms et pondérations';

  @override
  String get eventTypesSectionTitle => 'Types d\'événements';

  @override
  String get manageEventTypesLabel => 'Gérer les types d\'événements';

  @override
  String get syncSectionTitle => 'Sync & Sauvegarde';

  @override
  String get syncComingSoon => 'Disponible en Phase 2';

  @override
  String get syncSemantics =>
      'Sync & Sauvegarde — Disponible en Phase 2, pas encore disponible';

  @override
  String get passphraseLabel => 'Phrase secrète';

  @override
  String get confirmPassphraseLabel => 'Confirmer la phrase secrète';

  @override
  String get showPassphrase => 'Afficher la phrase secrète';

  @override
  String get hidePassphrase => 'Masquer la phrase secrète';

  @override
  String get exportPassphraseHint =>
      'Choisissez une phrase secrète pour protéger votre sauvegarde. Notez-la dans un endroit sûr — elle ne peut pas être récupérée.';

  @override
  String get importPassphraseHint =>
      'Entrez la phrase secrète utilisée lors de la création de cette sauvegarde.';

  @override
  String get dailyTitle => 'Actions proposées';

  @override
  String get switchToExpandedView => 'Passer à la vue étendue';

  @override
  String get switchToCompactView => 'Passer à la vue compacte';

  @override
  String get expandedViewTooltip => 'Vue étendue';

  @override
  String get compactViewTooltip => 'Vue compacte';

  @override
  String get nothingToday => 'Rien pour aujourd\'hui 🎉\nTout est à jour !';

  @override
  String get backupRestoredSuccess => 'Sauvegarde restaurée avec succès.';

  @override
  String backupSavedTo(String path) {
    return 'Sauvegarde enregistrée dans :\n$path';
  }

  @override
  String get backupSettingsResetSuccess =>
      'Paramètres de sauvegarde réinitialisés.';

  @override
  String get resetExportFailed => 'Exportation échouée. Veuillez réessayer.';

  @override
  String get importFailed =>
      'Importation échouée. Vérifiez votre phrase secrète et votre fichier.';

  @override
  String get resetFailed => 'Réinitialisation échouée. Veuillez réessayer.';

  @override
  String get demoLabel => 'Démo';

  @override
  String get importantLabel => 'Important';

  @override
  String get urgentLabel => 'Urgent';

  @override
  String get tagsSection => 'Tags';

  @override
  String get noTags => 'Pas de tags';

  @override
  String get mobileSection => 'Mobile';

  @override
  String get concernFlagActive => 'Préoccupation active';

  @override
  String get noEventsYet =>
      'Pas encore d\'événements. Appuyez sur + pour en ajouter un.';

  @override
  String get couldNotLoadEvents => 'Impossible de charger les événements.';

  @override
  String get couldNotLoadHistory => 'Impossible de charger l\'historique.';

  @override
  String get markDoneAdvance => 'Marquer fait (avancer)';

  @override
  String get markAsDone => 'Marquer comme fait';

  @override
  String get typeLabel => 'Type';

  @override
  String get noteOptionalLabel => 'Note (optionnel)';

  @override
  String get demoFriendDescription =>
      'Ceci est un ami de démonstration. Ajoutez un vrai contact pour commencer — Sophie sera supprimée automatiquement.';

  @override
  String get feedbackSectionTitle => 'Suggestions';

  @override
  String get feedbackEmailLabel => 'Envoyer vos suggestions';

  @override
  String get friendNotFound => 'Ami introuvable.';

  @override
  String deleteFriendConfirmContent(String name) {
    return 'Supprimer « $name » ? Tout l\'historique des contacts sera définitivement supprimé et ne pourra pas être annulé.';
  }

  @override
  String get clearConcernBody =>
      'Retirer le signal de préoccupation et sa note pour cet ami ?';

  @override
  String deleteEventConfirmContent(String type, String date) {
    return 'Supprimer « $type » du $date ? Cette action est irréversible.';
  }

  @override
  String eventDoneLabel(String date) {
    return 'Réalisé le $date';
  }

  @override
  String get eventActionsTooltip => 'Actions sur l\'événement';

  @override
  String get tierNormal => 'Normal';

  @override
  String get surfacingNoEvent => 'Pas d\'événement prévu';

  @override
  String surfacingOverdueByDays(int days) {
    return 'En retard de $days jours';
  }

  @override
  String get surfacingOverdueByOneDay => 'En retard de 1 jour';

  @override
  String get surfacingDueToday => 'Prévu aujourd\'hui';

  @override
  String get surfacingDueTomorrow => 'Prévu demain';

  @override
  String surfacingDueInDays(int days) {
    return 'Dans $days jours';
  }

  @override
  String get couldNotLoadDailyView =>
      'Impossible de charger les actions proposées.';

  @override
  String get concernActiveSemantics => 'Préoccupation active';

  @override
  String get lastNoteLabel => 'Dernière note';

  @override
  String get contactLoggedFeedback =>
      'Prise de contact réalisée — bien joué 💛';

  @override
  String cadenceEveryNDays(int days) {
    return 'Tous les $days jours';
  }

  @override
  String get heartBriefingTitle => 'Aperçu prioritaire';

  @override
  String get noFriendsWithTagsYet =>
      'Aucun ami avec ces étiquettes pour le moment.';

  @override
  String get searchFriendsByName => 'Rechercher des amis par nom';

  @override
  String noFriendNamedSearch(String query) {
    return 'Aucun ami nommé « $query » dans votre cercle.';
  }

  @override
  String filterByTagSemantics(String tag, String state) {
    return 'Filtrer par $tag, $state';
  }

  @override
  String get chipStateSelected => 'sélectionné';

  @override
  String get chipStateNotSelected => 'non sélectionné';

  @override
  String get concernCadenceSectionTitle => 'Suivi de préoccupation';

  @override
  String get concernCadenceLabel => 'Cadence de suivi';

  @override
  String concernCadenceEveryNDays(int days) {
    return 'Tous les $days jours';
  }

  @override
  String get concernCadenceDefault => 'défaut';

  @override
  String get concernCadenceAppliesNote =>
      'S\'applique aux nouvelles préoccupations — les cadences existantes ne sont pas modifiées.';

  @override
  String concernCadenceSemantics(int days, String state) {
    return 'Cadence de préoccupation : Tous les $days jours, $state';
  }

  @override
  String get draftResumingBanner => 'Reprise de votre brouillon';

  @override
  String lastContactLabel(String date) {
    return 'Dernier contact : $date';
  }

  @override
  String get draftDiscard => 'Annuler';

  @override
  String get modelDownloadTitle => 'Configuration IA';

  @override
  String get modelDownloadStorageRequired =>
      'Cette fonctionnalité nécessite le téléchargement d\'un modèle IA (~2 Go). Assurez-vous d\'avoir suffisamment d\'espace de stockage.';

  @override
  String get modelDownloadButton => 'Télécharger le modèle';

  @override
  String get modelDownloadCancelButton => 'Annuler';

  @override
  String get modelDownloadRetryButton => 'Réessayer';

  @override
  String modelDownloadProgressSemantics(int percent) {
    return 'Téléchargement du modèle IA, $percent pour cent terminé';
  }

  @override
  String modelDownloadErrorMessage(String error) {
    return 'Échec du téléchargement : $error';
  }

  @override
  String get modelDownloadComplete =>
      'Modèle IA prêt — vous pouvez maintenant utiliser les suggestions intelligentes.';

  @override
  String get modelDownloadOkButton => 'Terminer';

  @override
  String get hfTokenSectionTitle => 'Token d\'accès HuggingFace';

  @override
  String get hfTokenExplainer =>
      'Pour télécharger le modèle IA, vous avez besoin d\'un token HuggingFace (compte gratuit). Rendez-vous sur huggingface.co/settings/tokens pour en générer un (accès lecture seule suffisant).';

  @override
  String get hfTokenFieldLabel => 'Token HuggingFace';

  @override
  String get hfTokenSaveAndDownload => 'Enregistrer et télécharger';

  @override
  String get hfTokenErrorEmpty =>
      'Veuillez saisir votre token HuggingFace avant de télécharger.';

  @override
  String get hfTokenHowToTitle => 'Comment obtenir un token HuggingFace';

  @override
  String get hfTokenHowToSteps =>
      '1. Rendez-vous sur huggingface.co et créez un compte gratuit (ou connectez-vous).\n2. Cliquez sur votre avatar → Paramètres → Access Tokens.\n3. Cliquez sur « New token », choisissez le type Read, donnez-lui un nom.\n4. Copiez le token (commence par hf_…) et collez-le ici.';

  @override
  String get hfTokenHowToClose => 'Compris';

  @override
  String get modelInfoTitle => 'Gemma 3n E2B — IA embarquée';

  @override
  String get modelInfoDescription =>
      'Un modèle léger de 2 milliards de paramètres développé par Google, optimisé pour les appareils mobiles. Il fonctionne entièrement sur votre téléphone — aucune connexion internet requise après le téléchargement, vos données ne quittent jamais votre appareil.';

  @override
  String get modelInfoSize => 'Taille : ~2 Go (téléchargement unique)';

  @override
  String get modelInfoButtonTooltip => 'Infos sur le modèle';

  @override
  String get statusFilterTooltip => 'Filtrer par statut';

  @override
  String statusFilterActiveSemantics(int count) {
    return 'Filtrer par statut, $count actif(s)';
  }

  @override
  String get statusFilterSheetTitle => 'Filtrer par statut';

  @override
  String get statusFilterActiveConcern => 'Préoccupation active';

  @override
  String get statusFilterOverdueEvent => 'Événement en retard';

  @override
  String get statusFilterNoRecentContact => 'Pas de contact récent';

  @override
  String get statusFilterClearAll => 'Effacer tous les filtres';

  @override
  String get noFriendsMatchingStatus =>
      'Aucun ami ne correspond aux filtres actifs.';

  @override
  String get suggestMessageAction => 'Suggérer un message';

  @override
  String get draftMessageSheetTitle => 'Suggestions de message';

  @override
  String get draftMessageGenerating => 'Génération en cours...';

  @override
  String draftMessageEventHeader(String name, String eventContext) {
    return 'Pour $name — $eventContext';
  }

  @override
  String draftMessageVariantSemantics(int n, String preview) {
    return 'Option de message $n : $preview';
  }

  @override
  String get draftMessageChannelWhatsApp => 'WhatsApp';

  @override
  String get draftMessageChannelSms => 'SMS';

  @override
  String get draftMessageChannelWhatsAppSemantics => 'Envoyer via WhatsApp';

  @override
  String get draftMessageChannelSmsSemantics => 'Envoyer via SMS';

  @override
  String get draftMessageSendViaWhatsApp => 'Copier et envoyer via WhatsApp';

  @override
  String get draftMessageSendViaSms => 'Copier et envoyer via SMS';

  @override
  String get draftMessageDiscard => 'Annuler';

  @override
  String get draftMessageDiscardSemantics => 'Annuler la suggestion';

  @override
  String get draftMessageError =>
      'Impossible de générer des suggestions pour le moment. Vous pouvez écrire votre message ci-dessous.';

  @override
  String get draftMessageGenerateMore => 'Générer plus';

  @override
  String draftMessageSendSemantics(String channel) {
    return 'Copier et envoyer via $channel';
  }

  @override
  String get suggestMessageDailyAction => '✦ Message';

  @override
  String suggestMessageDailySemantics(String name) {
    return 'Compose un message suggéré pour $name';
  }
}
