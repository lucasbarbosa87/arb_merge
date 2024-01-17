import 'dart:convert';
import 'dart:io';

import 'package:arb_merger/arb_merger.dart';
import 'package:arb_merger/src/models/arb_model.dart';

class ArbMerger {
  Future<void> merge(PackageSettings packageSettings) async {
    final List<File> arbFiles = [];
    for (String locale in packageSettings.supportedLocales) {
      String inputPath = "${packageSettings.inputFilePath}/$locale";
      await checkIfInputPathHasFiles(inputPath);
      final outputFile = getOutputArbFile(packageSettings, locale);
      final mergedArbFile = await createArbFileIfNotExits(outputFile);
      arbFiles.addAll(await readAllArbs(inputPath));
      arbFiles.removeWhere((element) => element.uri == mergedArbFile.uri);
      ArbModel mergedArb = ArbModel.empty();
      for (var element in arbFiles) {
        final Map<String, dynamic> arbMap =
            json.decode(element.readAsStringSync());
        final arb = ArbModel.fromArb(arbMap);
        print(arb.toString());
      }
    }
  }

  Future<List<File>> readAllArbs(String inputPath) async {
    final List<File> inputArbFiles = [];
    final inputDirectory = Directory(inputPath);
    if (inputDirectory.path.contains(".arb")) {
      inputArbFiles.add(File(inputDirectory.path));
      return inputArbFiles;
    }
    for (var element in inputDirectory.listSync()) {
      final tempDirectory = Directory(element.path);
      if (tempDirectory.path.contains(".arb")) {
        inputArbFiles.add(File(tempDirectory.path));
        continue;
      }
      inputArbFiles.addAll((await tempDirectory.list().toList())
          .where((element) => element.path.contains(".arb"))
          .map((e) => File(e.path)));
    }
    return inputArbFiles;
  }

  Future<File> createArbFileIfNotExits(String path) async {
    var file = File(path);
    if (await file.exists()) {
      return file;
    }
    var directory = file.parent;
    if (!await directory.exists()) {
      await directory.create();
      // return;
    }
    await file.create(recursive: true);
    return file;
  }

  Future<void> checkIfInputPathHasFiles(String inputPath) async {
    final directory = Directory(inputPath);
    if (!await directory.exists()) {
      print("a pasta $inputPath não existe");
      exit(1);
    }
    final files = await directory.list().toList();
    if (files.isEmpty) {
      print("a pasta $inputPath esta vazia");
      exit(0);
    }
  }

  String getOutputArbFile(PackageSettings packageSettings, String locale) {
    if (packageSettings.outputFileName != null) {
      return "${packageSettings.outputFilePath}/${packageSettings.outputFileName}_$locale.arb";
    }
    return "${packageSettings.outputFilePath}/$locale.arb";
  }
}
