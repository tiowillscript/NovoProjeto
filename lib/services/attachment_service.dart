import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AttachmentService {
  Future<List<File>> pickAndCopy() async {
    final result=await FilePicker.platform.pickFiles(allowMultiple:true,withData:false);
    if(result==null) return [];
    final base=Directory(p.join((await getApplicationDocumentsDirectory()).path,'attachments'));
    await base.create(recursive:true);
    final out=<File>[];
    for(final item in result.files){
      if(item.path==null) continue;
      final src=File(item.path!);
      final safe='${DateTime.now().microsecondsSinceEpoch}_${item.name}';
      out.add(await src.copy(p.join(base.path,safe)));
    }
    return out;
  }
}
