import 'dart:async';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:flutter/material.dart' hide Element;
import 'package:gbk_codec/gbk_codec.dart';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class PricesWidget extends StatelessWidget {
  final String title;
  final String urlPath;

  PricesWidget({Key key, this.title, this.urlPath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: TextStyle(fontSize: 17)),
      ),
      body: FutureBuilder<List<String>>(
        future: fetchPrices(urlPath),
        builder: (context, snapshot) {
          if (snapshot.hasError) print(snapshot.error);
          return snapshot.hasData
              ? PricesList(prices: snapshot.data)
              : Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
