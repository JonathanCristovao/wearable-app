import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import 'app_pt_br.dart';
import 'app_en.dart';

class AppLocalizations {
  final String locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Provider.of<LocaleProvider>(context, listen: false)
        .localizations;
  }

  Map<String, String> get _strings =>
      locale == 'en' ? enStrings : ptBrStrings;

  String get(String key) => _strings[key] ?? key;

  // ── Main / App ──────────────────────────────────────────────────────────
  String get appName => get('appName');
  String get home => get('home');
  String get graphs => get('graphs');
  String get settings => get('settings');

  // ── Main Screen - Bluetooth Modal ───────────────────────────────────────
  String get sensorStatus => get('sensorStatus');
  String sensorNumber(int i) => '${get('sensor')} $i';
  String get smartphone => get('smartphone');
  String get active => get('active');
  String get inactive => get('inactive');
  String get close => get('close');
  String get connect => get('connect');
  String get connected => get('connected');

  // ── Home Screen ─────────────────────────────────────────────────────────
  String get welcomeMessage => get('welcomeMessage');
  String get sensors => get('sensors');
  String get sensorsDescription => get('sensorsDescription');
  String get activities => get('activities');
  String get activitiesDescription => get('activitiesDescription');
  String get history => get('history');
  String get historyDescription => get('historyDescription');
  String get analyses => get('analyses');
  String get analysesDescription => get('analysesDescription');
  String get aiSpace => get('aiSpace');
  String get comingSoon => get('comingSoon');
  String get aiDescription => get('aiDescription');
  String get federatedLearning => get('federatedLearning');
  String get federatedLearningDesc => get('federatedLearningDesc');
  String get privacy => get('privacy');
  String get gansTitle => get('gansTitle');
  String get gansDescription => get('gansDescription');
  String get generation => get('generation');
  String get activityClassification => get('activityClassification');
  String get activityClassificationDesc => get('activityClassificationDesc');
  String get classification => get('classification');
  String get llmContext => get('llmContext');
  String get llmContextDesc => get('llmContextDesc');
  String get newLabel => get('newLabel');
  String featureUnavailable(String feature) =>
      'A funcionalidade "$feature" estará disponível em breve.';

  // ── Settings Screen ─────────────────────────────────────────────────────
  String get smartphoneSensors => get('smartphoneSensors');
  String get noSensorEnabled => get('noSensorEnabled');
  String get accelerometer => get('accelerometer');
  String get gyroscope => get('gyroscope');
  String get magnetometer => get('magnetometer');
  String get gps => get('gps');
  String get barometer => get('barometer');
  String get about => get('about');
  String get application => get('application');
  String get version => get('version');
  String get sensor => get('sensor');
  String get battery => get('battery');
  String get disconnect => get('disconnect');
  String sensorDisconnected(int i) => '${get('sensor')} $i ${get('disconnected')}';
  String get language => get('language');
  String get languageDescription => get('languageDescription');
  String get portuguese => get('portuguese');
  String get english => get('english');
  String get device => get('device');

  // ── Trash / Lixeira ────────────────────────────────────────────────────
  String get trash => get('trash');
  String get trashEmpty => get('trashEmpty');
  String get clearTrash => get('clearTrash');
  String get clearTrashConfirm => get('clearTrashConfirm');
  String get clearTrashConfirmSingle => get('clearTrashConfirmSingle');
  String get restore => get('restore');
  String get restoredSuccessfully => get('restoredSuccessfully');
  String get trashClearedSuccessfully => get('trashClearedSuccessfully');
  String get itemsInTrash => get('itemsInTrash');
  String get deletedAt => get('deletedAt');
  String get movedToTrash => get('movedToTrash');
  String get selectSensor => get('selectSensor');
  String get accelerationG => get('accelerationG');
  String get angularVelocity => get('angularVelocity');
  String get angles => get('angles');
  String get accelerometerMs2 => get('accelerometerMs2');
  String get gyroscopeRads => get('gyroscopeRads');
  String get magnetometerUt => get('magnetometerUt');
  String get gpsSpeed => get('gpsSpeed');
  String get barometerHpa => get('barometerHpa');
  String get noPhoneSensorEnabled => get('noPhoneSensorEnabled');
  String get waitingData => get('waitingData');

  // ── Activity Graphs Screen ─────────────────────────────────────────────
  String get gpsMapTab => get('gpsMapTab');
  String get chartsTab => get('chartsTab');
  String get noData => get('noData');
  String get phoneAcceleration => get('phoneAcceleration');
  String get phoneGyroscope => get('phoneGyroscope');
  String get gpsSpeedLabel => get('gpsSpeedLabel');
  String get gpsAltitude => get('gpsAltitude');
  String get barometricPressure => get('barometricPressure');
  String get noPhoneSensorTabData => get('noPhoneSensorTabData');
  String get distanceLabel => get('distanceLabel');
  String get avgSpeedLabel => get('avgSpeedLabel');
  String get altitudeGain => get('altitudeGain');

  // ── Activities Screen ───────────────────────────────────────────────────
  String get chooseActivity => get('chooseActivity');
  String get selectActivityType => get('selectActivityType');
  String get standardActivities => get('standardActivities');
  String get myActivities => get('myActivities');
  String get newActivity => get('newActivity');
  String get configureNewActivity => get('configureNewActivity');
  String get createCustomActivity => get('createCustomActivity');
  String get outdoorWalking => get('outdoorWalking');
  String get indoorRunning => get('indoorRunning');
  String get indoorCycling => get('indoorCycling');
  String get sensorsRequired => get('sensorsRequired');
  String get noSensorsConfigured => get('noSensorsConfigured');
  String get edit => get('edit');
  String get duplicate => get('duplicate');
  String get delete => get('delete');
  String get deleteActivity => get('deleteActivity');
  String deleteActivityConfirm(String name) =>
      'Deseja excluir "$name"? Esta ação não pode ser desfeita.';
  String get cancel => get('cancel');
  String activityCreated(String name) => 'Atividade "$name" criada';

  // ── Activity Config Screen ──────────────────────────────────────────────
  String get editActivity => get('editActivity');
  String get newActivityTitle => get('newActivityTitle');
  String get identification => get('identification');
  String get chooseEmoji => get('chooseEmoji');
  String get changeEmoji => get('changeEmoji');
  String get activityName => get('activityName');
  String get activityNameHint => get('activityNameHint');
  String get enterActivityName => get('enterActivityName');
  String get nameTooShort => get('nameTooShort');
  String get requiredSensors => get('requiredSensors');
  String get add => get('add');
  String get addSensor => get('addSensor');
  String get addAnotherSensor => get('addAnotherSensor');
  String get noSensorAdded => get('noSensorAdded');
  String get saveChanges => get('saveChanges');
  String get createActivity => get('createActivity');
  String get position => get('position');
  String get positionHint => get('positionHint');
  String get enterPosition => get('enterPosition');
  String get quickPositions => get('quickPositions');
  String get removeSensor => get('removeSensor');
  String get addAtLeastOneSensor => get('addAtLeastOneSensor');
  String errorSaving(String e) => 'Erro ao salvar: $e';

  // ── Activity Running Screen ─────────────────────────────────────────────
  String get paused => get('paused');
  String get inProgress => get('inProgress');
  String get resume => get('resume');
  String get pause => get('pause');
  String get finish => get('finish');
  String get dataPoints => get('dataPoints');
  String get activeSensors => get('activeSensors');
  String get realtimeSensors => get('realtimeSensors');
  String get waitingPhoneData => get('waitingPhoneData');
  String get checkpoint => get('checkpoint');
  String get fatigueLevel => get('fatigueLevel');
  String get saveCheckpoint => get('saveCheckpoint');
  String get selectActivityToSave => get('selectActivityToSave');
  String get currentActivity => get('currentActivity');
  String checkpointSaved(String name) => 'Checkpoint salvo: $name';
  String errorSavingCheckpoint(String e) => 'Erro ao salvar checkpoint: $e';
  String get selectFatigueLevel => get('selectFatigueLevel');
  String fatigueMarked(int level, int points) =>
      'Fadiga nível $level marcada em $points pontos';
  String get fatigueAlreadyMarked => get('fatigueAlreadyMarked');
  String errorSavingActivity(String e) => 'Erro ao salvar atividade: $e';
  String get exitActivity => get('exitActivity');
  String get exitActivityConfirm => get('exitActivityConfirm');
  String get exit => get('exit');

  // ── Activity Summary Screen ─────────────────────────────────────────────
  String get activitySummary => get('activitySummary');
  String get activityCompleted => get('activityCompleted');
  String get totalDuration => get('totalDuration');
  String get start => get('start');
  String get end => get('end');
  String get seeDetailedAnalysis => get('seeDetailedAnalysis');
  String get seeHistory => get('seeHistory');
  String get backToHome => get('backToHome');

  // ── Activity Detail Screen ──────────────────────────────────────────────
  String get activityDetails => get('activityDetails');
  String get seeGraphs => get('seeGraphs');
  String get exportCSV => get('exportCSV');
  String get seeDetailedAnalysisShort => get('seeDetailedAnalysisShort');
  String get seeTable => get('seeTable');
  String get dataSummary => get('dataSummary');
  String get avgRoll => get('avgRoll');
  String get avgPitch => get('avgPitch');
  String get avgYaw => get('avgYaw');
  String get maxAcceleration => get('maxAcceleration');
  String get maxAccelX => get('maxAccelX');
  String get maxAccelY => get('maxAccelY');
  String get maxAccelZ => get('maxAccelZ');
  String get avgGyroX => get('avgGyroX');
  String get avgGyroY => get('avgGyroY');
  String get avgGyroZ => get('avgGyroZ');
  String get avgGpsSpeed => get('avgGpsSpeed');
  String get storagePermissionDenied => get('storagePermissionDenied');
  String get csvSavedToDownload => get('csvSavedToDownload');
  String get csvExported => get('csvExported');
  String get copy => get('copy');
  String errorExportingCsv(String e) => 'Erro ao exportar CSV: $e';
  String get cannotAccessStorage => get('cannotAccessStorage');

  // ── Activity Analysis Screen ────────────────────────────────────────────
  String get activityAnalysis => get('activityAnalysis');
  String get noDataForAnalysis => get('noDataForAnalysis');
  String get overallMetrics => get('overallMetrics');
  String get averageIntensity => get('averageIntensity');
  String get movementQuality => get('movementQuality');
  String get basedOnSmoothness => get('basedOnSmoothness');
  String get detectedPeaks => get('detectedPeaks');
  String get intenseMovements => get('intenseMovements');
  String get dataQuality => get('dataQuality');
  String get validPoints => get('validPoints');
  String sensorAnalysis(int id) => 'Análise do Sensor $id';
  String get intensity => get('intensity');
  String get peaks => get('peaks');
  String get smoothness => get('smoothness');
  String get acceleration => get('acceleration');
  String get gyroscopeLabel => get('gyroscopeLabel');
  String get orientation => get('orientation');
  String get accelDistribution => get('accelDistribution');
  String get min => get('min');
  String get avg => get('avg');
  String get max => get('max');
  String get median => get('median');
  String get stdDev => get('stdDev');
  String get noPhoneSensorActivated => get('noPhoneSensorActivated');

  // ── Activity Graphs Screen ──────────────────────────────────────────────
  String get activityGraphs => get('activityGraphs');
  String get wearable => get('wearable');
  String get gpsMap => get('gpsMap');
  String get noDataAvailable => get('noDataAvailable');
  String get noPhoneSensorDataAvailable => get('noPhoneSensorDataAvailable');
  String get altitudeProfile => get('altitudeProfile');
  String get distance => get('distance');
  String get avgSpeed => get('avgSpeed');
  String get altGain => get('altGain');
  String get eulerAngles => get('eulerAngles');

  // ── Activity Check Screen ───────────────────────────────────────────────
  String get allSensorsConnected => get('allSensorsConnected');
  String get connectRequiredSensors => get('connectRequiredSensors');
  String get connectionStatus => get('connectionStatus');
  String get startActivity => get('startActivity');
  String get sensorPlacement => get('sensorPlacement');
  String get connectedLabel => get('connectedLabel');
  String get disconnectedLabel => get('disconnectedLabel');
  String get waiting => get('waiting');
  String get available => get('available');
  String get wantToConnectSensor => get('wantToConnectSensor');
  String connectSensorTitle(int i) => '${get('connectSensor')} $i';

  // ── Activity Table Screen ───────────────────────────────────────────────
  String get dataTable => get('dataTable');
  String columnsRows(int cols, int rows) => '$cols colunas · $rows linhas';
  String get noDataToDisplay => get('noDataToDisplay');

  // ── History Screen ──────────────────────────────────────────────────────
  String get saveAll => get('saveAll');
  String get all => get('all');
  String get noActivityRecorded => get('noActivityRecorded');
  String get userNoActivities => get('userNoActivities');
  String get completeActivityToSeeHistory => get('completeActivityToSeeHistory');
  String dataPointsCount(int count) => '$count pontos de dados';
  String get viewDetails => get('viewDetails');
  String get sendToFirebase => get('sendToFirebase');
  String get deleteActivityLabel => get('deleteActivityLabel');
  String get sendingToFirebase => get('sendingToFirebase');
  String get activitySentSuccessfully => get('activitySentSuccessfully');
  String errorSending(String e) => 'Erro ao enviar: $e';
  String get generatingZip => get('generatingZip');
  String errorExporting(String e) => 'Erro ao exportar: $e';
  String deleteActivityConfirmTitle(String name) =>
      'Deseja deletar "$name"? Esta ação não pode ser desfeita.';
  String get deleteLabel => get('deleteLabel');
  String get unauthenticatedUser => get('unauthenticatedUser');

  // ── LLM Chat Screen ────────────────────────────────────────────────────
  String get llmContextTitle => get('llmContextTitle');
  String get noRecordedActivities => get('noRecordedActivities');
  String get selectActivity => get('selectActivity');
  String get generalSummary => get('generalSummary');
  String get detectProblems => get('detectProblems');
  String get movementAnalysis => get('movementAnalysis');
  String get trainingQuality => get('trainingQuality');
  String get peaksAndValleys => get('peaksAndValleys');
  String get compareSensors => get('compareSensors');
  String get overlaidChart => get('overlaidChart');
  String get chartLabel => get('chartLabel');
  String get analyzing => get('analyzing');
  String get selectActivityAbove => get('selectActivityAbove');
  String get askAboutActivity => get('askAboutActivity');
  String get selectActivityToStartAnalysis => get('selectActivityToStartAnalysis');
  String get askAboutSelectedActivity => get('askAboutSelectedActivity');
  String get selectActivityFirst => get('selectActivityFirst');
  String get askModel => get('askModel');
  String errorContactingModel(String e) => '❌ Erro ao contactar o modelo: $e';
  String allSensorsLabel(String metric) => '$metric — todos os sensores';
  String singleSensorLabel(String metric, String sensor) => '$metric — $sensor';
  String chartInfo(String unit, int count, String time) =>
      'Unidade: $unit · $count sensor(es) · ${time}s';

  // ── Scanner Screen ──────────────────────────────────────────────────────
  String connectSensorLabel(int i) => '${get('connectSensor')} $i';
  String get stopScanning => get('stopScanning');
  String get scan => get('scan');
  String get noDeviceFound => get('noDeviceFound');
  String get rssi => get('rssi');
  String get connecting => get('connecting');
  String connectedToSensor(String name, int i) => '$name ${get('connectedToSensor')} $i';
  String get connectError => get('connectError');

  // ── Universal Scanner Screen ────────────────────────────────────────────
  String get scanSensors => get('scanSensors');
  String get selectSensorAutoConnect => get('selectSensorAutoConnect');
  String get pressScanToStart => get('pressScanToStart');
  String slotNumberLabel(int n) => '→ Slot $n';
  String connectingToSlot(String name, int slot) =>
      '${get('connecting')} $name ${get('toSlot')} $slot...';
  String connectedToSensorLabel(String name, int i) =>
      '$name ${get('connectedToSensor')} $i!';
  String get connectErrorTryAgain => get('connectErrorTryAgain');

  // ── Phone Sensors Screen ────────────────────────────────────────────────
  String get phoneSensorsTitle => get('phoneSensorsTitle');
  String get status => get('status');
  String get enableSensorsBelow => get('enableSensorsBelow');
  String get enableAtLeastOne => get('enableAtLeastOne');
  String get magnetometerCompass => get('magnetometerCompass');
  String get accelerometerSubtitle => get('accelerometerSubtitle');
  String get gyroscopeSubtitle => get('gyroscopeSubtitle');
  String get magnetometerSubtitle => get('magnetometerSubtitle');
  String get gpsSubtitle => get('gpsSubtitle');
  String get barometerSubtitle => get('barometerSubtitle');
  String get realtimeData => get('realtimeData');
  String get phoneSensorsEnabled => get('phoneSensorsEnabled');
  String get phoneSensorsDisabled => get('phoneSensorsDisabled');

  // ── User Profile Screen ─────────────────────────────────────────────────
  String get users => get('users');
  String get noUserRegistered => get('noUserRegistered');
  String get tapToAddUser => get('tapToAddUser');
  String get addUser => get('addUser');
  String get deleteUser => get('deleteUser');
  String deleteUserConfirm(String name) => 'Deseja excluir "$name"?';
  String get newUser => get('newUser');
  String get editUser => get('editUser');
  String get name => get('name');
  String get nameRequired => get('nameRequired');
  String get age => get('age');
  String get years => get('years');
  String get invalidAge => get('invalidAge');
  String get weight => get('weight');
  String get kg => get('kg');
  String get invalidWeight => get('invalidWeight');
  String get height => get('height');
  String get cm => get('cm');
  String get invalidHeight => get('invalidHeight');
  String get activityFrequency => get('activityFrequency');
  String get injury => get('injury');
  String get disease => get('disease');
  String get createUser => get('createUser');
  String get saveChangesLabel => get('saveChangesLabel');
  String get userCreatedSuccess => get('userCreatedSuccess');
  String get userUpdated => get('userUpdated');
  String errorSavingUser(String e) => 'Erro ao salvar: $e';
  String get deselect => get('deselect');
  String get selectLabel => get('selectLabel');
  String diseaseLabel(String d) => 'Doença: $d';
  String injuryLabel(String i) => 'Lesão: $i';
  String frequencyLabel(String f) => 'Freq. atividade: $f';

  // ── Body Positions ──────────────────────────────────────────────────────
  String get positionThorax => get('positionThorax');
  String get positionAbdomen => get('positionAbdomen');
  String get positionBack => get('positionBack');
  String get positionHead => get('positionHead');
  String get positionLeftShoulder => get('positionLeftShoulder');
  String get positionRightShoulder => get('positionRightShoulder');
  String get positionLeftArm => get('positionLeftArm');
  String get positionRightArm => get('positionRightArm');
  String get positionLeftForearm => get('positionLeftForearm');
  String get positionRightForearm => get('positionRightForearm');
  String get positionLeftWrist => get('positionLeftWrist');
  String get positionRightWrist => get('positionRightWrist');
  String get positionLeftThigh => get('positionLeftThigh');
  String get positionRightThigh => get('positionRightThigh');
  String get positionLeftShin => get('positionLeftShin');
  String get positionRightShin => get('positionRightShin');
  String get positionLeftCalf => get('positionLeftCalf');
  String get positionRightCalf => get('positionRightCalf');
  String get positionLeftAnkle => get('positionLeftAnkle');
  String get positionRightAnkle => get('positionRightAnkle');
  String get positionLeftFoot => get('positionLeftFoot');
  String get positionRightFoot => get('positionRightFoot');
}
