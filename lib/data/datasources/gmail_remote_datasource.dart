import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;

class GmailMessageSnippet {
  final String id;
  final String threadId;
  final String from;
  final String subject;
  final String snippet;
  final DateTime internalDate;

  GmailMessageSnippet({
    required this.id,
    required this.threadId,
    required this.from,
    required this.subject,
    required this.snippet,
    required this.internalDate,
  });

  String toPromptSummary() {
    return 'Email ID: $id | From: $from | Subject: "$subject" | Date: ${internalDate.toIso8601String()}\nSnippet: $snippet';
  }
}

class GmailRemoteDatasource {
  final auth.AuthClient authClient;
  late final gmail.GmailApi _gmailApi;

  GmailRemoteDatasource(this.authClient) {
    _gmailApi = gmail.GmailApi(authClient);
  }

  Future<List<GmailMessageSnippet>> fetchUnreadEmails({int maxResults = 10}) async {
    final listResponse = await _gmailApi.users.messages.list(
      'me',
      q: 'is:unread label:INBOX',
      maxResults: maxResults,
    );

    final messages = listResponse.messages;
    if (messages == null || messages.isEmpty) {
      return [];
    }

    final List<GmailMessageSnippet> snippets = [];

    for (final msg in messages) {
      final msgId = msg.id;
      if (msgId == null) continue;

      try {
        final detail = await _gmailApi.users.messages.get(
          'me',
          msgId,
          format: 'metadata',
          metadataHeaders: ['From', 'Subject', 'Date'],
        );

        String from = 'Unknown';
        String subject = 'No Subject';

        final headers = detail.payload?.headers;
        if (headers != null) {
          for (final h in headers) {
            if (h.name?.toLowerCase() == 'from') {
              from = h.value ?? from;
            } else if (h.name?.toLowerCase() == 'subject') {
              subject = h.value ?? subject;
            }
          }
        }

        final internalDateMs = int.tryParse(detail.internalDate ?? '') ?? DateTime.now().millisecondsSinceEpoch;
        final date = DateTime.fromMillisecondsSinceEpoch(internalDateMs);

        snippets.add(
          GmailMessageSnippet(
            id: msgId,
            threadId: detail.threadId ?? msgId,
            from: from,
            subject: subject,
            snippet: detail.snippet ?? '',
            internalDate: date,
          ),
        );
      } catch (_) {}
    }

    return snippets;
  }
}
