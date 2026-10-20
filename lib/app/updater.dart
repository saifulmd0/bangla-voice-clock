import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import '../core/update/release.dart';
import 'version.dart';

/// Where new versions come from, so tests can stand in for GitHub.
abstract interface class UpdateSource {
  /// The newest published release, or null if there is none.
  Future<Release?> latest();

  /// Whether [install] can replace this copy, rather than the user
  /// downloading the new version by hand.
  bool get canInstall;

  /// Downloads [release]'s installer and starts it; the app should quit
  /// once this returns. [progress] gets 0–1 as the download goes.
  Future<void> install(Release release, {void Function(double)? progress});
}

/// [UpdateSource] backed by the GitHub releases of this repository.
class GitHubUpdates implements UpdateSource {
  GitHubUpdates({HttpClient Function()? client})
    : _client = client ?? HttpClient.new;

  static final _releases = Uri.parse(
    'https://api.github.com/repos/saifulmd0/bangla-voice-clock/releases'
    '?per_page=10',
  );
  static const _setupSuffix = '-windows-setup.exe';

  final HttpClient Function() _client;

  @override
  Future<Release?> latest() async {
    final client = _client()..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.getUrl(_releases);
      request.headers
        ..set(HttpHeaders.acceptHeader, 'application/vnd.github+json')
        ..set(HttpHeaders.userAgentHeader, 'BanglaVoiceClock/$appVersion');
      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('GitHub answered ${response.statusCode}');
      }
      return newestRelease(jsonDecode(body) as List<dynamic>);
    } finally {
      client.close();
    }
  }

  /// Only a copy the Windows setup installed: the Mac app is sandboxed and
  /// can't replace itself, and a portable copy wasn't installed at all.
  @override
  bool get canInstall {
    if (!Platform.isWindows) return false;
    final local = Platform.environment['LOCALAPPDATA'];
    if (local == null) return false;
    final folder = File(Platform.resolvedExecutable).parent.path;
    return folder.toLowerCase() ==
        '$local\\Programs\\Bangla Voice Clock'.toLowerCase();
  }

  @override
  Future<void> install(
    Release release, {
    void Function(double)? progress,
  }) async {
    final asset = release.asset(_setupSuffix);
    if (asset == null) throw StateError('No Windows setup in ${release.page}');
    final file = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}${asset.name}',
    );
    final client = _client()..connectionTimeout = const Duration(seconds: 15);
    try {
      // GitHub redirects the download, which HttpClient follows.
      final response = await (await client.getUrl(asset.url)).close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('Download answered ${response.statusCode}');
      }
      final total = response.contentLength > 0
          ? response.contentLength
          : asset.size;
      var received = 0;
      final sink = file.openWrite();
      try {
        await for (final chunk in response) {
          sink.add(chunk);
          received += chunk.length;
          if (total > 0) progress?.call(received / total);
        }
      } finally {
        await sink.close();
      }
    } finally {
      client.close();
    }
    if (asset.sha256 case final expected?) {
      final actual = sha256.convert(await file.readAsBytes()).toString();
      if (actual != expected) {
        await file.delete();
        throw const FileSystemException('The download was damaged');
      }
    }
    // The setup closes this copy, installs over it with the choices made
    // last time, and opens the new version.
    await Process.start(file.path, const [
      '/SILENT',
      '/SUPPRESSMSGBOXES',
      '/NORESTART',
    ], mode: ProcessStartMode.detached);
  }
}
