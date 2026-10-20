class ApiEndpoints {
  ApiEndpoints._();

  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String authLogout = '/auth/logout';

  static const String historyList = '/history/list';
  static const String historyDetail = '/history/detail';
  static const String historyDelete = '/history/delete';

  static const String sensorReadingList = '/sensor-reading/list';
  static const String sensorReadingDetail = '/sensor-reading/detail';
  static const String sensorsKey = '/sensors/key';
  static const String alertRuleList = '/sensor-rule/list';
  static const String alertRuleSave = '/sensor-rule/save';

  // Area routes are plural and answer with bare JSON, not the usual envelope:
  //   /areas/list   -> [{"id":1,"name":"Area Uji"}]
  //   /areas/create -> {"id":7} (201)
  // `/areas/update` and `/areas/delete` are declared but still 404 on the
  // server; AreaService maps that to a "belum tersedia" message.
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
