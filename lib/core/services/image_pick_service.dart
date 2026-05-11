import 'dart:io';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Picks an image from [source], opens a locked-square crop UI,
/// saves the result to the app's persistent image dir, and returns the path.
/// Returns null if the user cancelled at any step.
Future<String?> pickAndCropSquare(ImageSource source) async {
  final picked = await ImagePicker()
      .pickImage(source: source, imageQuality: 90);
  if (picked == null) return null;

  final cropped = await ImageCropper().cropImage(
    sourcePath: picked.path,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Crop photo',
        lockAspectRatio: true,
        initAspectRatio: CropAspectRatioPreset.square,
        hideBottomControls: true,
      ),
      IOSUiSettings(
        title: 'Crop photo',
        aspectRatioLockEnabled: true,
        resetAspectRatioEnabled: false,
        aspectRatioPickerButtonHidden: true,
      ),
    ],
  );
  if (cropped == null) return null;

  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory(p.join(docs.path, 'shredify', 'images'));
  if (!dir.existsSync()) dir.createSync(recursive: true);
  final ext = p.extension(cropped.path).isNotEmpty
      ? p.extension(cropped.path)
      : '.jpg';
  final dest = p.join(dir.path, '${const Uuid().v4()}$ext');
  await File(cropped.path).copy(dest);
  return dest;
}
