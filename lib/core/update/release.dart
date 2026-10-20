/// A version number such as 0.2.0, compared part by part.
class Version implements Comparable<Version> {
  const Version(this.parts);

  /// Reads "0.2.0" or a tag such as "v0.2.0"; null if it isn't one.
  static Version? tryParse(String text) {
    final match = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)$').firstMatch(text.trim());
    if (match == null) return null;
    return Version([for (var i = 1; i <= 3; i++) int.parse(match[i]!)]);
  }

  final List<int> parts;

  @override
  int compareTo(Version other) {
    for (var i = 0; i < 3; i++) {
      final c = parts[i].compareTo(other.parts[i]);
      if (c != 0) return c;
    }
    return 0;
  }

  bool operator >(Version other) => compareTo(other) > 0;

  @override
  bool operator ==(Object other) => other is Version && compareTo(other) == 0;

  @override
  int get hashCode => Object.hashAll(parts);

  @override
  String toString() => parts.join('.');
}

/// A file attached to a [Release].
class ReleaseAsset {
  const ReleaseAsset({
    required this.name,
    required this.url,
    required this.size,
    this.sha256,
  });

  final String name;
  final Uri url;
  final int size;

  /// The SHA-256 GitHub reports for the file, in hex, when it has one.
  final String? sha256;
}

/// A published version of the app on GitHub.
class Release {
  const Release({
    required this.version,
    required this.page,
    required this.notes,
    required this.assets,
  });

  final Version version;

  /// The release's web page, for downloading by hand.
  final Uri page;

  /// What changed, as Markdown.
  final String notes;
  final List<ReleaseAsset> assets;

  /// The attached file whose name ends with [suffix], such as
  /// "-windows-setup.exe".
  ReleaseAsset? asset(String suffix) {
    for (final a in assets) {
      if (a.name.endsWith(suffix)) return a;
    }
    return null;
  }

  /// [notes] as plain text for a dialog: no headings, bold or code marks.
  String get plainNotes => notes
      .split('\n')
      .where((line) => !line.trimLeft().startsWith('|'))
      .map(
        (line) => line
            .replaceFirst(RegExp(r'^#+\s*'), '')
            .replaceFirst(RegExp(r'^- '), '• ')
            .replaceAll('**', '')
            .replaceAll('`', ''),
      )
      .join('\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

/// The newest published release in a GitHub "list releases" response,
/// counting pre-releases (every 0.x version is one) but not drafts.
Release? newestRelease(List<dynamic> json) {
  Release? newest;
  for (final item in json) {
    if (item is! Map || item['draft'] == true) continue;
    final version = Version.tryParse(item['tag_name'] as String? ?? '');
    final page = Uri.tryParse(item['html_url'] as String? ?? '');
    if (version == null || page == null) continue;
    if (newest != null && !(version > newest.version)) continue;
    newest = Release(
      version: version,
      page: page,
      notes: item['body'] as String? ?? '',
      assets: [for (final a in item['assets'] as List? ?? const []) ?_asset(a)],
    );
  }
  return newest;
}

ReleaseAsset? _asset(Object? json) {
  if (json is! Map) return null;
  final url = Uri.tryParse(json['browser_download_url'] as String? ?? '');
  if (url == null) return null;
  return ReleaseAsset(
    name: json['name'] as String? ?? '',
    url: url,
    size: json['size'] as int? ?? 0,
    sha256: switch (json['digest']) {
      final String d when d.startsWith('sha256:') => d.substring(7),
      _ => null,
    },
  );
}
