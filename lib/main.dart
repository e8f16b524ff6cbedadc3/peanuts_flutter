import 'dart:async';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'package:flutter/material.dart' hide Element;
import 'package:gbk_codec/gbk_codec.dart';
import 'package:html/dom.dart' hide Text;
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

Future<List<String>> fetchPrices(String urlPath) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String> data;
  if (prefs.containsKey(urlPath)) {
    data = prefs.getStringList(urlPath);
  } else {
    Client client = Client();
    Response resp = await client.get('http://www.62422.cn/$urlPath');
    var document = parse(gbk_bytes.decode(resp.bodyBytes));
    String title = document.querySelector('title').text.split(':')[0];
    String location = title.split('地区')[0].split('日')[1];
    data = document.body.text
        .split('点此查看会员收费标准与办理方式')[1]
        .split('\n')[0]
        .split(new RegExp("(?=$location)"))
        .where((it) => it.startsWith(location))
        .map((it) => it.trim())
        .toList();
    prefs.setStringList(urlPath, data);
  }
  return data;
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
          return Card(
              child: ListTile(
            title: Text(categoriesList[index], textAlign: TextAlign.center),
            trailing: Icon(Icons.keyboard_arrow_right),
            onTap: () {
              Navigator.of(context).push(
                  CupertinoPageRoute<void>(builder: (BuildContext context) {
                return Scaffold(
                  appBar: AppBar(
                    title: Text(categoriesList[index],
                        style: TextStyle(fontSize: 17)),
                  ),
                  body: FutureBuilder<List<String>>(
                    future: fetchPrices(categories[categoriesList[index]]),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) print(snapshot.error);
                      return snapshot.hasData
                          ? PricesList(prices: snapshot.data)
                          : Center(child: CircularProgressIndicator());
                    },
                  ),
                );
              }));
            },
          ));
        },
      ),
    );
  }
}

class PricesList extends StatelessWidget {
  final List<String> prices;
  final ScrollController controller = ScrollController();

  PricesList({Key key, this.prices}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollbar.rrect(
      controller: controller,
      child: ListView.builder(
        controller: controller,
        itemCount: prices.length,
        itemBuilder: (BuildContext ctx, int index) {
          return Card(
            child: Padding(
                padding: EdgeInsets.all(10.0), child: Text(prices[index])),
          );
        },
      ),
    );
  }
}

void main() {
  runApp(MyApp(categories: fetchCategories()));
}

class MyApp extends StatelessWidget {
  final Future<Map<String, String>> categories;

  MyApp({Key key, this.categories}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '中国花生价格行情',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
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
      ),
    );
  }
}
