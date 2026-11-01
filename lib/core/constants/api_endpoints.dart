class ApiEndpoints {
  ApiEndpoints._();

  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String authLogout = '/auth/logout';
  static const String authRefresh = '/auth/refresh';

  static const String historyList = '/history/list';
  static const String historyDetail = '/history/detail';
  static const String historyDelete = '/history/delete';
  // Server-Sent Events: anomalies recorded after `after_id` (0 = from now).
  static const String historyStream = '/history/stream';

  static const String sensorReadingList = '/sensor-reading/list';
  static const String sensorReadingDetail = '/sensor-reading/detail';
  // Server-Sent Events: backlog of recent readings, then each new one.
  static const String sensorReadingStream = '/sensor-reading/stream';
  static const String sensorsKey = '/sensors/key';
  // Bare JSON: list -> [rule, ...], save -> 204 no body.
  static const String alertRuleList = '/alerts/rules/list';
  static const String alertRuleSave = '/alerts/rules/save';

  // RPC-over-POST, standard {success, message, data} envelope. An area is only
  // {id, name}: any other field sent is accepted and silently dropped.
  static const String areaList = '/areas/list';
  static const String areaDetail = '/areas/detail';
  static const String areaCreate = '/areas/create';
  static const String areaUpdate = '/areas/update';
  static const String areaDelete = '/areas/delete';

  static const String sensorList = '/sensor/list';
  static const String sensorDetail = '/sensor/detail';
  static const String sensorCreate = '/sensor/create';
  static const String sensorUpdate = '/sensor/update';
  static const String sensorDelete = '/sensor/delete';

  static const String userDetail = '/user/detail';
  static const String userUpdate = '/user/update';
}
