class PostModel {
  final int postId;
  final int facilityId;
  final int creatorId;
  final String title;
  final String content;
  final String facilityName;
  final String creatorName;

  PostModel({
    required this.postId, required this.facilityId, required this.creatorId,
    required this.title, required this.content, required this.facilityName, required this.creatorName,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      postId: json['post_id'], facilityId: json['facility_id'], creatorId: json['creator_id'],
      title: json['title'], content: json['content'],
      facilityName: json['facility_name'] ?? '', creatorName: json['creator_name'] ?? '',
    );
  }
}