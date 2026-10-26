import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// Embedded or fallback video section supporting offline gracefully.
class LessonVideoSection extends StatefulWidget {
  final String? videoUrl;
  final String language;

  const LessonVideoSection({
    super.key,
    required this.videoUrl,
    this.language = 'en',
  });

  @override
  State<LessonVideoSection> createState() => _LessonVideoSectionState();
}

class _LessonVideoSectionState extends State<LessonVideoSection> {
  YoutubePlayerController? _controller;
  bool _isCheckingConnectivity = true;
  bool _isOnline = false;
  bool _hasError = false;
  bool _isPlayingInline = false;
  String? _videoId;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final url = widget.videoUrl;
    if (url == null || url.isEmpty) {
      if (mounted) setState(() => _isCheckingConnectivity = false);
      return;
    }

    _videoId = YoutubePlayerController.convertUrlToId(url);

    // Check network connectivity
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasConnection = connectivityResult.any(
        (result) =>
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.ethernet,
      );

      if (mounted) {
        setState(() {
          _isOnline = hasConnection;
          _isCheckingConnectivity = false;
        });
      }
    } catch (_) {
      // If connectivity check fails, default to online attempt
      if (mounted) {
        setState(() {
          _isOnline = true;
          _isCheckingConnectivity = false;
        });
      }
    }
  }

  void _startInlinePlayer() {
    if (_videoId == null) return;
    try {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: _videoId!,
        autoPlay: true,
        params: const YoutubePlayerParams(showFullscreenButton: true),
      );
      setState(() {
        _isPlayingInline = true;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
      });
    }
  }

  Future<void> _openExternalYouTube() async {
    final url = widget.videoUrl;
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videoUrl == null || widget.videoUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isTl = widget.language == 'tl';

    if (_isCheckingConnectivity) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // 1. Offline fallback state
    if (!_isOnline) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                color: theme.colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTl
                        ? 'Kailangan ng internet ang video.'
                        : 'Video requires an internet connection.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isTl
                        ? 'Maaari mo pa ring basahin ang buong aralin sa ibaba.'
                        : 'You can still read the full written lesson below.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 2. Playback error state
    if (_hasError) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: theme.colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isTl
                        ? 'Hindi ma-load ang video. Maaari mong ipagpatuloy ang pagbabasa sa ibaba.'
                        : "We couldn't load the video. You can continue reading the lesson below.",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _openExternalYouTube,
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: Text(isTl ? 'Buksan sa YouTube' : 'Open in YouTube'),
            ),
          ],
        ),
      );
    }

    // 3. Active inline video playback
    if (_isPlayingInline && _controller != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            YoutubePlayer(controller: _controller!),
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: _openExternalYouTube,
              icon: const Icon(Icons.open_in_new_rounded, size: 14),
              label: Text(
                isTl ? 'Buksan sa YouTube app' : 'Open in YouTube app',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    // 4. Online preview / "Watch Video" card
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 30,
              ),
              onPressed: _startInlinePlayer,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTl ? 'Panoorin ang Video' : 'Watch Video',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isTl
                      ? 'Opsyonal na karagdagang impormasyon mula sa YouTube'
                      : 'Optional supplementary video resource',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: _openExternalYouTube,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(isTl ? 'YouTube' : 'YouTube'),
          ),
        ],
      ),
    );
  }
}
