import 'dart:async';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:gbk_codec/gbk_codec.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart';

Future<List<String>> fetchPrices(Client client) async {
  Response resp = await client.get('http://www.62422.cn/search.asp?cataid=77');
  var document = parse(gbk_bytes.decode(resp.bodyBytes));
  List<dom.Element> links = document.querySelectorAll('a[href^=look]');
  String urlPath = links.where((it) => it.text.contains('山东')).first.attributes['href'];

  //String urlPath = "look.asp?id=372975";
  resp = await client.get('http://www.62422.cn/${urlPath}');
  document = parse(gbk_bytes.decode(resp.bodyBytes));
  String title = document.querySelector('title').text.split(':')[0];
  String location = title.split('地区')[0].split('日')[1];
  List<String> data = document.body.text
      .split('点此查看会员收费标准与办理方式')[1]
      .split('\n')[0]
      .split(new RegExp("(?=${location})"))
      .where((it) => it.startsWith(location))
      .map((it) => it.trim())
      .toList();
  data.insert(0, title);
  return data;
}

class PricesList extends StatelessWidget {
  final List<String> prices;
  final ScrollController controller = ScrollController();

  PricesList({Key key, this.prices}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollbar.rrect(
    //return Scrollbar(
      controller: controller,
      child: ListView.builder(
        controller: controller,
        itemCount: prices.length,
        itemBuilder: (BuildContext ctx, int index) {
          if (index == 0) {
            return Card(
              child: Padding(
                padding: EdgeInsets.all(10.0),
                child: Text(
                  prices[index],
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return Card(
            child: Padding(
                padding: EdgeInsets.all(10.0), child: Text(prices[index])),
          );
        },
      ),
    );
  }
}

void main() => runApp(MyApp(prices: fetchPrices(Client())));

class MyApp extends StatelessWidget {
  final Future<List<String>> prices;

  MyApp({Key key, this.prices}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Data Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        //appBar: AppBar(
        //  title: Text('本日山东地区花生价格'),
        //),
        body: FutureBuilder<List<String>>(
          future: prices,
          builder: (context, snapshot) {
            if (snapshot.hasError) print(snapshot.error);
            return snapshot.hasData
                ? PricesList(prices: snapshot.data)
                : Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}
