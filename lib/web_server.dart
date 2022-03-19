import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:archive/archive_io.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';


Future<void> run_web_server() async {
  var db;
  try  {
    Directory directory = await getApplicationDocumentsDirectory();
    var dbPath = join(directory.path, "tiles.db");
    var exists = await databaseExists(dbPath);
    if (!exists) {
        var tiles = await rootBundle.load("assets/tiles/mongolia.mbtiles");
        print("Loaded mbtiles with size: ${tiles.lengthInBytes}");
        await File(dbPath).writeAsBytes(tiles.buffer.asUint8List());
    } else {
        print("Database already exists");
    }
    db = await openDatabase(dbPath);
    List<Map<String, Object?>> records = await db.query('metadata');
    for (final record in records) {
        if (record["name"] as String == "bounds") {
            print("Bounds = ${record['value']}");
        }
    }
  } catch(e) {
      print("Can't get asset: $e");
  }

    var fontPath = await getFontsUrl("Roboto");
    print("Roboto path = $fontPath");

    var app = Router();

    app.get('/style.json', (Request request) async {
        var json = await rootBundle.loadString('assets/styles/style.json');
        final headers = {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*"
        };
        var response = Response.ok(json, headers:headers);
        return response;
    });

    app.get('/glyphs/<font>/<range>', (Request request, String font, String range) async {
        String fontName = Uri.decodeQueryComponent(font);
        String fileName = Uri.decodeQueryComponent(range);
        print("Query is for $fontName, $range");
        try {
            File f = File('$fontPath$fontName/$fileName');
            if (! await f.exists()) {
                print("${f.path} doesn't exist");
                return Response.notFound("font not found");
            }
            final byteStream = await f.readAsBytes();
            final headers = {
                "Content-Type": "application/octet-stream",
                "Access-Control-Allow-Origin": "*"
            };
            return Response.ok(byteStream, headers:headers);
        } catch (e) {
            return Response.notFound("Internal error: $e");
        }   
    });

    final spritePath = await downloadSprites();
    app.get('/sprites/<fileName>.json', (Request request, String fileName) async {
        try {
            File f = File('${spritePath}$fileName.json');
            if (! await f.exists()) {
                print("${f.path} doesn't exist");
                return Response.notFound("sprite not found");
            }
            final byteStream = await f.readAsBytes();
            final headers = {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            };
            return Response.ok(byteStream, headers:headers);
        } catch (e) {
            return Response.notFound("Internal error: $e");
        }          
    });

    app.get('/sprites/<fileName>.png', (Request request, String fileName) async {
        try {
            File f = File('${spritePath}$fileName.png');
            if (! await f.exists()) {
                print("${f.path} doesn't exist");
                return Response.notFound("sprite not found");
            }
            final byteStream = await f.readAsBytes();
            final headers = {
                "Content-Type": "image/png",
                "Access-Control-Allow-Origin": "*"
            };
            return Response.ok(byteStream, headers:headers);
        } catch (e) {
            return Response.notFound("Internal error: $e");
        }          
    });

    app.get('/tiles/<zoom>/<col>/<row>.pbf', (Request request, String zoom, String col, String row) async {
        var y = (1 << int.parse(zoom)) - 1 - int.parse(row);
        print("Request is SELECT from tiles WHERE zoom=$zoom AND column=$col (y=$y) AND row=$row");
        var tiles = await db.query('tiles', columns: ['tile_data'], where: 'zoom_level=$zoom AND tile_column=$col AND tile_row=$y');
        if (tiles.length > 0) {
            print("OK");
            final headers = {
                "Content-Type": "application/x-protobuf",
                "content-encoding": "gzip",
                "Access-Control-Allow-Origin": "*"
            };
            return Response.ok(tiles[0]['tile_data'], headers:headers);
        } else {
            print("Not found !!");
            return Response.notFound("tile not found");
        }
    });

    var handler = const Pipeline().addMiddleware(logRequests()).addHandler(_echoRequest);
    var http_server = await shelf_io.serve(app, '127.0.0.1', 8080);
    print('Serving at http://${http_server.address.host}:${http_server.port}');
}
 
Response _echoRequest(Request request) =>
    Response.ok('Request for "${request.url}"');

Future<String> downloadSprites() async {
    final appDirectory = await getApplicationDocumentsDirectory();
    final spriteDir = Directory(join(appDirectory.path, "sprites/"));
    if (! await spriteDir.exists()) {
        print("Downloading sprites");
        await spriteDir.create(recursive: true);
        final spritePath = spriteDir.path;
        try {
            firebase_storage.FirebaseStorage storage = firebase_storage.FirebaseStorage.instance;
            firebase_storage.Reference ref = storage.ref('sprites.json');
            Uint8List? bytes = await ref.getData();
            if (bytes != null) {
                File(join(spriteDir.path, "sprites.json")).writeAsBytesSync(bytes);
            }
            ref = storage.ref('sprites.png');
            bytes = await ref.getData();
            if (bytes != null) {
                File(join(spriteDir.path, "sprites.png")).writeAsBytesSync(bytes);
            }
            ref = storage.ref('osm-liberty@2x.png');
            bytes = await ref.getData();
            if (bytes != null) {
                File(join(spriteDir.path, "sprites@2x.png")).writeAsBytesSync(bytes);
            }
            ref = storage.ref('osm-liberty@2x.json');
            bytes = await ref.getData();
            if (bytes != null) {
                File(join(spriteDir.path, "sprites@2x.json")).writeAsBytesSync(bytes);
            }
        } catch(e) {
            print("Can't get storage reference: $e");
        }
    }
    return spriteDir.path;
}

Future<String> getFontsUrl(String fontname) async {
    final appDirectory = await getApplicationDocumentsDirectory();
    final fontDir = Directory(join(appDirectory.path, "fonts/$fontname/"));
    if (! await fontDir.exists()) {
        await fontDir.create(recursive: true);
        final fontPath = join(fontDir.path, "$fontname");
        try {
            firebase_storage.FirebaseStorage storage = firebase_storage.FirebaseStorage.instance;
            final allFiles = await storage.ref().listAll();
            allFiles.items.forEach((firebase_storage.Reference r) {
                print("Found ${r.toString()}");
            });
            firebase_storage.Reference ref = storage.ref('${fontname}.zip');
            Uint8List? bytes = await ref.getData();
            if (bytes != null) {
                final archive = ZipDecoder().decodeBytes(bytes);
                for (final file in archive) {
                    final filename = file.name;
                    if (file.isFile) {
                    final data = file.content as List<int>;
                    File(join(fontDir.path, filename))
                        ..createSync(recursive: true)
                        ..writeAsBytesSync(data);
                    } else {
                        Directory(join(fontDir.path, filename)).create(recursive: true);
                        print("Create dsirectory $filename");
                    }
                }
                return ref.toString();
            } else {
                print("ref.getData returns null");
            }
            /*
            final zipFile = File(join(appDirectory.path, "$fontname.zip"));
            await ref.writeToFile(zipFile);
            print("Ok, finished writing file");
            return zipFile.path;
            */
        } catch(e) {
            print("Can't get storage reference: $e");
        }
    }
    return fontDir.path;
}