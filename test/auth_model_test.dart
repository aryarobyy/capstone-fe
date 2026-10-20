import 'package:flutter_test/flutter_test.dart';
import 'package:tanipintar/modules/auth/models/auth_model.dart';

void main() {
  test('login response parses flat user fields', () {
    // Real shape from POST /api/auth/login
    final data = AuthResponseData.fromJson({
      'refresh_token': 'ref123',
      'id': 12,
      'name': 'Uji Coba',
      'email': 'ujicoba991@mail.com',
      'msisdn': '081234567891',
      'access_token': 'acc123',
      'token_type': 'Bearer',
      'expires_in': 604800,
    });

    expect(data.accessToken, 'acc123');
    expect(data.refreshToken, 'ref123');
    expect(data.user.id, 12);
    expect(data.user.name, 'Uji Coba');
    expect(data.user.msisdn, '081234567891');
  });

  test('login response still parses nested user', () {
    final data = AuthResponseData.fromJson({
      'access_token': 'acc',
      'user': {'id': 1, 'name': 'A', 'email': 'a@b.com'},
    });

    expect(data.user.id, 1);
    expect(data.user.msisdn, '');
  });

  test('register request includes msisdn', () {
    const req = RegisterRequest(
      name: 'A',
      email: 'a@b.com',
      msisdn: '08123456789',
      password: 'rahasia123',
    );

    expect(req.toJson(), {
      'name': 'A',
      'email': 'a@b.com',
      'msisdn': '08123456789',
      'password': 'rahasia123',
    });
  });
}
