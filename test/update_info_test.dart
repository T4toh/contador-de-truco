import 'package:flutter_test/flutter_test.dart';
import 'package:contador_de_truco/update/update_info.dart';

void main() {
  group('Version.parse', () {
    test('acepta v1.0.1, 1.0.1 y 1.0.1+3', () {
      expect(Version.parse('v1.0.1'), const Version(1, 0, 1));
      expect(Version.parse('1.0.1'), const Version(1, 0, 1));
      expect(Version.parse('1.0.1+3'), const Version(1, 0, 1));
    });

    test('rechaza lo que no sea X.Y.Z', () {
      expect(Version.parse('latest'), isNull);
      expect(Version.parse('v1.0'), isNull);
      expect(Version.parse('v1.0.1.2'), isNull);
      expect(Version.parse(''), isNull);
    });

    test('compara numéricamente, no como texto', () {
      expect(const Version(1, 0, 10) > const Version(1, 0, 9), isTrue);
      expect(const Version(1, 1, 0) > const Version(1, 0, 99), isTrue);
      expect(const Version(2, 0, 0) > const Version(1, 9, 9), isTrue);
      expect(const Version(1, 0, 0) > const Version(1, 0, 0), isFalse);
      expect(const Version(0, 0, 2) > const Version(1, 0, 0), isFalse);
    });
  });

  group('UpdateInfo.fromReleaseJson', () {
    const release = {
      'tag_name': 'v1.0.1',
      'assets': [
        {
          'name': 'versionCode.txt',
          'browser_download_url': 'https://example.com/versionCode.txt',
          'digest': 'sha256:0000',
        },
        {
          'name': 'contador-de-truco-1.0.1.apk',
          'browser_download_url': 'https://example.com/app.apk',
          'digest': 'sha256:954C2BAB',
        },
      ],
    };

    test('saca versión, url del .apk y sha256 sin prefijo y en minúsculas', () {
      final info = UpdateInfo.fromReleaseJson(release)!;
      expect(info.version, const Version(1, 0, 1));
      expect(info.apkUrl, Uri.parse('https://example.com/app.apk'));
      expect(info.sha256, '954c2bab');
    });

    test('sin asset .apk devuelve null', () {
      final sinApk = Map<String, dynamic>.from(release)..['assets'] = [];
      expect(UpdateInfo.fromReleaseJson(sinApk), isNull);
    });

    test('con tag que no parsea devuelve null', () {
      final tagRaro = Map<String, dynamic>.from(release)..['tag_name'] = 'latest';
      expect(UpdateInfo.fromReleaseJson(tagRaro), isNull);
    });

    test('sin digest devuelve null: sin hash no se instala nada', () {
      final sinDigest = Map<String, dynamic>.from(release)
        ..['assets'] = [
          {
            'name': 'app.apk',
            'browser_download_url': 'https://example.com/app.apk',
          },
        ];
      expect(UpdateInfo.fromReleaseJson(sinDigest), isNull);
    });
  });
}
