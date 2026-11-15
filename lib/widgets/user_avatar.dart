import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/config.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';

/// Buong URL ng avatar galing sa API (relative path ang laman ng database).
String? avatarFullUrl(dynamic path) {
  final s = '${path ?? ''}'.trim();
  if (s.isEmpty || s == 'null') return null;
  return s.startsWith('http') ? s : '${AppConfig.baseUrl}/$s';
}

/// Profile picture. Kapag walang litrato, ipapakita ang unang letra ng pangalan.
class UserAvatar extends StatelessWidget {
  final String name;
  final String? url; // buong URL (gamitin ang avatarFullUrl)
  final double size;
  final double radius; // sulok; size/2 = bilog
  final double fontSize;
  const UserAvatar({
    super.key,
    required this.name,
    this.url,
    this.size = 88,
    this.radius = 30,
    this.fontSize = 38,
  });

  @override
  Widget build(BuildContext context) {
    final initial = Text(
      name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase(),
      style: TextStyle(
          color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.w800),
    );
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            colors: [AppColors.accent, AppColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
      ),
      child: initial,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: url == null
            ? fallback
            : Image.network(
                url!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => fallback,
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : fallback,
              ),
      ),
    );
  }
}

/// UserAvatar na may maliit na camera button. Pindutin para pumili ng litrato,
/// kumuha ng bago o tanggalin ang kasalukuyan. Para sa Viewer, Owner at Admin.
class EditableAvatar extends StatefulWidget {
  final String name;
  final dynamic avatarPath; // avatar_url galing sa /auth/profile
  final double size;
  final double radius;
  final double fontSize;
  final double badgeSize;
  final ValueChanged<Map<String, dynamic>> onChanged; // bagong profile
  const EditableAvatar({
    super.key,
    required this.name,
    required this.avatarPath,
    required this.onChanged,
    this.size = 88,
    this.radius = 30,
    this.fontSize = 38,
    this.badgeSize = 30,
  });

  @override
  State<EditableAvatar> createState() => _EditableAvatarState();
}

enum _AvatarAction { gallery, camera, remove }

class _EditableAvatarState extends State<EditableAvatar> {
  final _picker = ImagePicker();
  bool _busy = false;

  void _toast(String m) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));

  Future<void> _choose() async {
    if (_busy) return;
    final hasPhoto = avatarFullUrl(widget.avatarPath) != null;
    final action = await showModalBottomSheet<_AvatarAction>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Profile photo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined,
                color: AppColors.primary),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(ctx, _AvatarAction.gallery),
          ),
          if (!kIsWeb)
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined,
                  color: AppColors.primary),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, _AvatarAction.camera),
            ),
          if (hasPhoto)
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Remove photo',
                  style: TextStyle(color: AppColors.error)),
              onTap: () => Navigator.pop(ctx, _AvatarAction.remove),
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (action == null || !mounted) return;
    if (action == _AvatarAction.remove) return _run(() => context.read<AuthService>().removeAvatar());

    final x = await _picker.pickImage(
      source: action == _AvatarAction.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 80,
    );
    if (x == null || !mounted) return;
    final bytes = await x.readAsBytes();
    if (!mounted) return;
    if (bytes.length > 2 * 1024 * 1024) {
      _toast('The photo is too large (2 MB max).');
      return;
    }
    await _run(() => context.read<AuthService>().uploadAvatar(base64Encode(bytes)));
  }

  Future<void> _run(Future<Map<String, dynamic>> Function() job) async {
    setState(() => _busy = true);
    try {
      final profile = await job();
      if (!mounted) return;
      widget.onChanged(profile);
      _toast('Profile photo updated.');
    } catch (e) {
      if (mounted) _toast('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final b = widget.badgeSize;
    return Semantics(
      button: true,
      label: 'Change profile photo',
      child: GestureDetector(
        onTap: _choose,
        child: SizedBox(
          width: s + b / 4,
          height: s + b / 4,
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned(
              left: 0,
              top: 0,
              child: UserAvatar(
                name: widget.name,
                url: avatarFullUrl(widget.avatarPath),
                size: s,
                radius: widget.radius,
                fontSize: widget.fontSize,
              ),
            ),
            if (_busy)
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  width: s,
                  height: s,
                  decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(widget.radius)),
                  child: const Center(
                    child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 3, color: Colors.white)),
                  ),
                ),
              ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: b,
                height: b,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(Icons.photo_camera, size: b * 0.5, color: Colors.white),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
