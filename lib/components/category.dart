import 'dart:async';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'package:flutter/material.dart' hide Element;
import 'package:gbk_codec/gbk_codec.dart';
import 'package:html/dom.dart' hide Text;
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'price.dart' show PricesWidget;

Future<Map<String, String>> fetchCategories() async {
  Client client = Client();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  Response resp = await client.get('http://www.62422.cn/search.asp?cataid=77');
  String body = gbk_bytes.decode(resp.bodyBytes);
  String lastBody = prefs.getString('catagory');
  if (lastBody != body) {
    prefs.clear();
    prefs.setString('catagory', body);
  }
  Document document = parse(body);
  List<Element> links = document.querySelectorAll('a[href^=look]');
  Map<String, String> result = new Map();
  for (var link in links) {
    result[link.text] = link.attributes['href'];
  }
  return result;
}

class CategoriesList extends StatelessWidget {
  final Map<String, String> categories;
  final ScrollController controller = ScrollController();

  CategoriesList({Key key, this.categories}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var categoriesList = categories.keys.toList();
    return DraggableScrollbar.rrect(
      controller: controller,
      child: ListView.builder(
        controller: controller,
        itemCount: categories.length,
        itemBuilder: (BuildContext ctx, int index) {
          String title = categoriesList[index];
          return Card(
              child: ListTile(
            title: Text(title, textAlign: TextAlign.center),
            trailing: Icon(Icons.keyboard_arrow_right),
            onTap: () {
              Navigator.of(context).push(
                  CupertinoPageRoute<void>(builder: (BuildContext context) {
                return PricesWidget(title: title, urlPath: categories[title]);
              }));
            },
          ));
        },
      ),
    );
  }
}

class CategoriesWidget extends StatelessWidget {
  final Future<Map<String, String>> categories;

  CategoriesWidget({Key key, this.categories}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('中国花生价格行情', textAlign: TextAlign.center),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, String>>(
        future: categories,
        builder: (context, snapshot) {
          if (snapshot.hasError) print(snapshot.error);
          return snapshot.hasData
              ? CategoriesList(categories: snapshot.data)
              : Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
