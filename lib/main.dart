import 'dart:async';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:gbk_codec/gbk_codec.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart';

Future<Map<String, String>> fetchLocations(Client client) async {
  Response resp = await client.get('http://www.62422.cn/search.asp?cataid=77');
  var document = parse(gbk_bytes.decode(resp.bodyBytes));
  List<dom.Element> links = document.querySelectorAll('a[href^=look]');
  Map<String, String> result = new Map();
  for (var link in links) {
    result[link.text] = link.attributes['href'];
  }
  return result;
}

Future<List<String>> fetchPrices(Client client, String urlPath) async {
  Response resp = await client.get('http://www.62422.cn/${urlPath}');
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
  return data;
}

class LocationsList extends StatelessWidget {
  final Map<String, String> locations;
  final ScrollController controller = ScrollController();

  LocationsList({Key key, this.locations}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var locationsList = locations.keys.toList();
    return DraggableScrollbar.rrect(
      controller: controller,
      child: ListView.builder(
        controller: controller,
        itemCount: locations.length,
        itemBuilder: (BuildContext ctx, int index) {
          return Card(
              margin: EdgeInsets.all(4.0),
              child: ListTile(
                title: Text(locationsList[index], textAlign: TextAlign.center),
                trailing: Icon(Icons.keyboard_arrow_right),
                onTap: () => {
                      Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (BuildContext context) {
                        return Scaffold(
                          appBar: AppBar(
                            title: Text(locationsList[index]),
                          ),
                          body: FutureBuilder<List<String>>(
                            future: fetchPrices(
                                Client(), locations[locationsList[index]]),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) print(snapshot.error);
                              return snapshot.hasData
                                  ? PricesList(prices: snapshot.data)
                                  : Center(child: CircularProgressIndicator());
                            },
                          ),
                        );
                      }))
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
  runApp(MyApp(locations: fetchLocations(Client())));
}

class MyApp extends StatelessWidget {
  final Future<Map<String, String>> locations;

  MyApp({Key key, this.locations}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Data Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('花生价格行情', textAlign: TextAlign.center),
        ),
        body: FutureBuilder<Map<String, String>>(
          future: locations,
          builder: (context, snapshot) {
            if (snapshot.hasError) print(snapshot.error);
            return snapshot.hasData
                ? LocationsList(locations: snapshot.data)
                : Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}
