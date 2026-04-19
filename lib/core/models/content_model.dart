import 'package:freezed_annotation/freezed_annotation.dart';

part 'content_model.freezed.dart';
part 'content_model.g.dart';

enum ContentType {
  @JsonValue('post')
  post,
  @JsonValue('reel')
  reel,
  @JsonValue('story')
  story,
  @JsonValue('thread')
  thread,
  @JsonValue('carousel')
  carousel,
  @JsonValue('tweet')
  tweet,
  @JsonValue('youtube_short')
  youtubeShort,
  @JsonValue('blog')
  blog,
}

enum ContentStatus {
  @JsonValue('draft')
  draft,
  @JsonValue('generated')
  generated,
  @JsonValue('scheduled')
  scheduled,
  @JsonValue('published')
  published,
  @JsonValue('failed')
  failed,
}

enum Platform {
  @JsonValue('instagram')
  instagram,
  @JsonValue('youtube')
  youtube,
  @JsonValue('twitter')
  twitter,
  @JsonValue('linkedin')
  linkedin,
  @JsonValue('facebook')
  facebook,
  @JsonValue('tiktok')
  tiktok,
}

@freezed
class ContentModel with _$ContentModel {
  const factory ContentModel({
    required String id,
    required String userId,
    required String title,
    @Default('') String caption,
    @Default([]) List<String> hashtags,
    @Default('') String imageUrl,
    @Default('') String videoUrl,
    @Default('') String aiPrompt,
    required ContentType contentType,
    @Default(ContentStatus.draft) ContentStatus status,
    @Default([]) List<Platform> platforms,
    DateTime? scheduledAt,
    DateTime? publishedAt,
    @Default(0) int likes,
    @Default(0) int shares,
    @Default(0) int views,
    @Default(0) int comments,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _ContentModel;

  factory ContentModel.fromJson(Map<String, dynamic> json) =>
      _$ContentModelFromJson(json);
}