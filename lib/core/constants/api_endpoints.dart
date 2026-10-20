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

  static const String areaList = '/area/list';
  static const String areaDetail = '/area/detail';
  static const String areaCreate = '/area/create';
  static const String areaUpdate = '/area/update';
  static const String areaDelete = '/area/delete';
  static const String areaList = '/areas/list';
  static const String areaCreate = '/areas/create';

  static const String sensorList = '/sensor/list';
  static const String sensorDetail = '/sensor/detail';
  static const String sensorCreate = '/sensor/create';
  static const String sensorUpdate = '/sensor/update';
  static const String sensorDelete = '/sensor/delete';

  static const String userDetail = '/user/detail';
  static const String userUpdate = '/user/update';
}
