import 'package:cross_file/cross_file.dart' show XFile;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:tus_client/tus_client.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TUS Client Upload Demo',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: UploadPage(),
    );
  }
}

class UploadPage extends StatefulWidget {
  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  double _progress = 0;
  XFile _file;
  TusClient _client;
  Uri _fileUrl;
  bool canMove = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TUS Client Upload Demo'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Text(
                "This demo uses TUS client to upload a file",
                style: TextStyle(fontSize: 18),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Card(
                color: Colors.teal,
                child: InkWell(
                  onTap: () async {
                    _file =
                        await _getXFile(await FilePicker.platform.pickFiles());
                    setState(() {
                      _progress = 0;
                      _fileUrl = null;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: <Widget>[
                        Icon(Icons.cloud_upload, color: Colors.white, size: 60),
                        Text(
                          "Upload a file",
                          style: TextStyle(fontSize: 25, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _file == null
                          ? null
                          : () async {
                              // Create a client
                              print("Create a client");
                              final size = await _file.length();
                              print("Video size: $size");
                              _client = TusClient(
                                  Uri.parse("https://api.vimeo.com/me/videos"),
                                  _file,
                                  headers: {
                                    "Accept":
                                        "application/vnd.vimeo.*+json;version=3.4",
                                    "Content-Type": "application/json",
                                  },
                                  token: "b96100dcf50481656483e351a07d28c3",
                                  body: {
                                    "upload": {
                                      "approach": "tus",
                                      "size": size.toString(),
                                    },
                                    "name": "Random Name",
                                    "description": "Random Desc",
                                    "privacy": {
                                      "embed": "private",
                                    }
                                  });

                              print("Starting upload");
                              await _client.upload(
                                onComplete: () async {
                                  print("Completed!");
                                  print(_client.vimeoDetails.body);
                                  // _client.vimeoDetails;
                                  setState(() {
                                    canMove = true;
                                    _fileUrl = _client.uploadUrl;
                                  });
                                },
                                onProgress: (progress) {
                                  print("Progress: $progress");
                                  setState(() => _progress = progress);
                                },
                              );
                            },
                      child: Text("Upload"),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _progress == 0
                          ? null
                          : () async {
                              // _client.pause();
                            },
                      child: Text("Pause"),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: canMove
                          ? () async {
                              bool result = await _client.moveVideoToFolder(
                                  folderId: "6738893");
                              if (result) {
                                print("Moved to the folder");
                              } else {
                                print("Failed to Moved the folder");
                              }
                            }
                          : null,
                      child: Text("Move to Folder"),
                    ),
                  ),
                ],
              ),
            ),
            Stack(
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(1),
                  color: Colors.grey,
                  width: double.infinity,
                  child: Text(" "),
                ),
                FractionallySizedBox(
                  widthFactor: _progress / 100,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(1),
                    color: Colors.green,
                    child: Text(" "),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(1),
                  width: double.infinity,
                  child: Text("Progress: ${_progress.toStringAsFixed(1)}%"),
                ),
              ],
            ),
            GestureDetector(
              onTap: _progress != 100
                  ? null
                  : () async {
                      await launch(_fileUrl.toString());
                    },
              child: Container(
                color: _progress == 100 ? Colors.green : Colors.grey,
                padding: const EdgeInsets.all(8.0),
                margin: const EdgeInsets.all(8.0),
                child:
                    Text(_progress == 100 ? "Link to view:\n $_fileUrl" : "-"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Copy file to temporary directory before uploading
  Future<XFile> _getXFile(FilePickerResult result) async {
    if (result != null) {
      final chosenFile = result.files.first;
      if (chosenFile.path != null) {
        // Android, iOS, Desktop
        return XFile(chosenFile.path);
      } else {
        // Web
        return XFile.fromData(
          chosenFile.bytes,
          name: chosenFile.name,
        );
      }
    }
    return null;
  }
}
