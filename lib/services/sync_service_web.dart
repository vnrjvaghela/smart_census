/// Web stub: image upload via dart:io is not supported on the web.
/// Returns null so the caller gracefully skips image upload.
Future<String?> uploadImage(String filePath, String surveyId) async {
  // dart:io File API does not exist on web.
  // Image upload is intentionally skipped; the survey text data is still synced.
  return null;
}
