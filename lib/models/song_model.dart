class SongModel {
  final int songid;
  final String songtitle;
  final String songsinger;
  final String songurl;
  final int songcategory;
  final String? songnada;
  final String? songduration;

  const SongModel({
    required this.songid,
    required this.songtitle,
    required this.songsinger,
    required this.songurl,
    required this.songcategory,
    this.songnada,
    this.songduration,
  });

  SongModel copyWith({
    int? songid,
    String? songtitle,
    String? songsinger,
    String? songurl,
    int? songcategory,
    String? songnada,
    String? songduration,
  }) {
    return SongModel(
      songid: songid ?? this.songid,
      songtitle: songtitle ?? this.songtitle,
      songsinger: songsinger ?? this.songsinger,
      songurl: songurl ?? this.songurl,
      songcategory: songcategory ?? this.songcategory,
      songnada: songnada ?? this.songnada,
      songduration: songduration ?? this.songduration,
    );
  }

  factory SongModel.fromJson(Map<String, dynamic> json) {
    return SongModel(
      songid: json['songid'] is int
          ? json['songid'] as int
          : int.tryParse(json['songid']?.toString() ?? '0') ?? 0,
      songtitle: json['songtitle'] as String? ?? '',
      songsinger: json['songsinger'] as String? ?? '',
      songurl: json['songurl'] as String? ?? '',
      songcategory: json['songcategory'] is int
          ? json['songcategory'] as int
          : int.tryParse(json['songcategory']?.toString() ?? '1') ?? 1,
      songnada: json['songnada'] as String?,
      songduration: json['songduration'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'songid': songid,
      'songtitle': songtitle,
      'songsinger': songsinger,
      'songurl': songurl,
      'songcategory': songcategory,
      'songnada': songnada,
      'songduration': songduration,
    };
  }
}
