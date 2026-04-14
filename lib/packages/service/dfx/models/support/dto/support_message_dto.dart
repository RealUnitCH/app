class SupportMessageDto {
  final int id;
  final String? author;
  final DateTime created;
  final String? message;
  final String? fileName;

  const SupportMessageDto({
    required this.id,
    this.author,
    required this.created,
    this.message,
    this.fileName,
  });

  factory SupportMessageDto.fromJson(Map<String, dynamic> json) {
    return SupportMessageDto(
      id: json['id'] as int,
      author: json['author'] as String?,
      created: DateTime.parse(json['created'] as String),
      message: json['message'] as String?,
      fileName: json['fileName'] as String?,
    );
  }

}
