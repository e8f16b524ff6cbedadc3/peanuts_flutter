import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:gbk_codec/gbk_codec.dart';
import 'package:html/parser.dart' show parse;

Future<List<String>> fetchPrices(Client client) async {
  Response resp = await client.get('http://www.62422.cn/look.asp?id=372975');
  var document = parse(gbk_bytes.decode(resp.bodyBytes));
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

  PricesList({Key key, this.prices}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
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
