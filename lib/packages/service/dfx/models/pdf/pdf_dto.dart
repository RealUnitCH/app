class PdfDto {
  final String pdfData;

  const PdfDto({
    required this.pdfData,
  });

  factory PdfDto.fromJson(Map<String, dynamic> json) {
    return PdfDto(
      pdfData: json['pdfData'] as String,
    );
  }
}
