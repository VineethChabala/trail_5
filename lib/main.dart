import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:easy_folder_picker/DirectoryList.dart';
import 'package:collection/collection.dart';
import 'package:easy_folder_picker/FolderPicker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const MyApp());
}

Future<void> requestStoragePermission() async {
  final status = await Permission.storage.request();

  if (status == PermissionStatus.granted) {
    // Permission was granted
  } else {
    // Permission was denied
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zixtractor',
      theme: ThemeData(
        primarySwatch: Colors.grey,
      ),
      home: const MyHomePage(title: 'Zixtractor'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {


  Future<Directory?> getOtherDirectory() async {
  
    return null;
  }

  Future<void> extractZipFile(File file, BuildContext context) async {
    Directory? directory = await getExternalStorageDirectory();

    // Directory? root =
    //   Directory("${directory!.path}/Downloads");

    Future<Directory?> diretory = getOtherDirectory();

    // ignore: unnecessary_null_comparison
    if (directory == null) {
      return;
    }
    await requestStoragePermission();
    // ignore: use_build_context_synchronously
    Directory? newDirectory = await FolderPicker.pick(
      allowFolderCreation: true,
      context: context,
      rootDirectory: directory ,
    );

    if (newDirectory == null) {
      return;
    }

    final targetPath = newDirectory.path;

    try {
      List<int> bytes = await file.readAsBytes();
      Archive archive = ZipDecoder().decodeBytes(bytes);

      String dirPath = join(targetPath, 'Extracted');
      Directory extractedDirectory = Directory(dirPath);
      if (await extractedDirectory.exists()) {
        bool allFilesSame = true;
        for (ArchiveFile archiveFile in archive) {
          String fileName = archiveFile.name;
          List<int> data = archiveFile.content;

          File extractedFile = File(join(dirPath, fileName));
          if (!await extractedFile.exists() ||
              !const ListEquality()
                  .equals(await extractedFile.readAsBytes(), data)) {
            allFilesSame = false;
            break;
          }
        }
        if (allFilesSame) {
          // ignore: use_build_context_synchronously
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Aborting Extraction'),
                content:
                    const Text('All files are already present in the folder'),
                actions: [
                  FloatingActionButton.extended(
                    label: const Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
          return;
        }
      } else {
        await extractedDirectory.create(recursive: true);
      }

      for (ArchiveFile archiveFile in archive) {
        String fileName = archiveFile.name;
        List<int> data = archiveFile.content;

        File(join(dirPath, fileName))
          ..createSync(recursive: true)
          ..writeAsBytesSync(data);
      }
      // ignore: use_build_context_synchronously
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Zip Extraction Completed'),
            content: const Text('The extraction process is completed'),
            actions: [
              FloatingActionButton.extended(
                label: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      print("An error occurred during the extraction: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Zixtractor"),
      ),
      body: Center(
        child: FloatingActionButton.extended(
          label: const Text("Select Zip File"),
          icon: const Icon(Icons.folder_zip),
          onPressed: () async {
            FilePickerResult? file = await FilePicker.platform.pickFiles();
            if (file == null) return;
            await requestStoragePermission();
            File zipFile = File((file.paths.first).toString());
            // ignore: use_build_context_synchronously
            extractZipFile(zipFile, context);
          },
        ),
      ),
    );
  }
}
