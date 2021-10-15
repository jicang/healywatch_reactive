class FirmwareData {
  late String url;
  late String version;

  FirmwareData({required this.url, required this.version});

  FirmwareData.fromJson(Map<String, dynamic> json) {
    url = json['url'] as String;
    version = json['version'] as String;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['url'] = url;
    data['version'] = version;
    return data;
  }
}
