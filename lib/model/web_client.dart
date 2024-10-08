import 'package:http/http.dart' as http;
import 'package:random_app/model/data.dart';
import 'package:random_app/model/display_item.dart';

class WebClient {
  final String baseUrl = 'http://127.0.0.1:8001/';

  Map<String, String> getHeaders() {
    return {
      'Content-Type': 'text/plain',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers':
          'Origin, X-Requested-With, Content-Type, Accept, Content-Length',
    };
  }

  Future<String> get(String path) async {
    var resp =
        await http.get(Uri.parse('$baseUrl$path'), headers: getHeaders());
    if (resp.body == '404') {
      throw Exception('404');
    }
    return resp.body.trim();
  }

  Future<String> put(String path, String body) async {
    var resp = await http.put(Uri.parse('$baseUrl$path'),
        body: body.trim(), headers: getHeaders());
    return resp.body.trim();
  }

  Future<String> delete(String path) async {
    var resp =
        await http.get(Uri.parse('$baseUrl$path'), headers: getHeaders());
    return resp.body.trim();
  }

  Future<void> loadFiles(String path) async {
    var str = await get(path);
    var arr = str.split('\n');
    listList = [];
    listList.addAll(arr.map((e) => DisplayItem(e)));
  }

  Future<void> loadFile(String path) async {
    var str = await get(path);
    var arr = str.split('\n');
    displayList = [];
    displayList.addAll(arr.map((e) => DisplayItem(e)));
  }

  Future<void> writeFile(String path, String body) async {
    await put(path, body);
    var str = await get(path);
    var arr = str.split('\n');
    displayList = [];
    displayList.addAll(arr.map((e) => DisplayItem(e)));
  }
}
