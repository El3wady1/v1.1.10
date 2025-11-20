import 'package:image_picker/image_picker.dart';

Pickimage(ImageSource source) async {
  final ImagePicker _imagepicker = ImagePicker();

  XFile? _file = await _imagepicker.pickImage(source: source);
  if (_file != null) {
    return await _file.readAsBytes();
  }

  return print("No image Selected");
}
