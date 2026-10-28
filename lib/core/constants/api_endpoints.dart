class ApiEndpoints {
  ApiEndpoints._();

  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String authLogout = '/auth/logout';
  static const String authRefresh = '/auth/refresh';

  static const String historyList = '/history/list';
  static const String historyDetail = '/history/detail';
  static const String historyDelete = '/history/delete';

  static const String sensorReadingList = '/sensor-reading/list';
  static const String sensorReadingDetail = '/sensor-reading/detail';
  static const String sensorsKey = '/sensors/key';
  // Bare JSON: list -> [rule, ...], save -> 204 no body.
  static const String alertRuleList = '/alerts/rules/list';
  static const String alertRuleSave = '/alerts/rules/save';

  // Area routes are plural and answer with bare JSON, not the usual envelope:
  //   /areas/list   -> [{"id":1,"name":"Area Uji"}]
  //   /areas/create -> {"id":7} (201)
  //   /areas/update, /areas/delete -> {"message":...}; 404 {"error":"area not found"}
  static const String areaList = '/areas/list';
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
