import 'package:flutter/material.dart';
import 'azqarLists.dart';

class Azqar extends StatefulWidget {
  @override
  _AzqarState createState() => _AzqarState();
}

class _AzqarState extends State<Azqar> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: cats.length,
      child: Scaffold(
        backgroundColor: Colors.cyan[50],
        appBar: AppBar(
          title: Text('الأذكار'),
          centerTitle: true,
          backgroundColor: Colors.cyan[600],
          elevation: 0.0,
          bottom: TabBar(
            isScrollable: true,
            tabs: cats.map<Widget>((Cats cat) {
              return Tab(
                text: cat.title,
              );
            }).toList(),
          ),
        ),
        body: TabBarView(children: [
          ListView(children: [
            Column(
              children: morningAzqarList
                  .map((zeqr) => ZeqrCard(
                        zeqr: zeqr,
                        reduce: () {
                          setState(() {
                            zeqr.count -= 1;
                            if (zeqr.count == 0) {
                              morningAzqarList.remove(zeqr);
                            }
                          });
                        },
                      ))
                  .toList(),
            ),
          ]),
          ListView(children: [
            Column(
              children: nightAzqarList
                  .map((zeqr) => ZeqrCard(
                        zeqr: zeqr,
                        reduce: () {
                          setState(() {
                            zeqr.count -= 1;
                            if (zeqr.count == 0) {
                              nightAzqarList.remove(zeqr);
                            }
                          });
                        },
                      ))
                  .toList(),
            ),
          ]),
          ListView(children: [
            Column(
              children: sleepAzqarList
                  .map((zeqr) => ZeqrCard(
                        zeqr: zeqr,
                        reduce: () {
                          setState(() {
                            zeqr.count -= 1;
                            if (zeqr.count == 0) {
                              sleepAzqarList.remove(zeqr);
                            }
                          });
                        },
                      ))
                  .toList(),
            ),
          ]),
        ]),
      ),
    );
  }
}

class Zeqr {
  String text;
  int count;

  Zeqr({this.text, this.count});
}

class ZeqrCard extends StatelessWidget {
  final Zeqr zeqr;
  final Function reduce;
  ZeqrCard({this.zeqr, this.reduce});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10),
      color: Colors.blueGrey,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              zeqr.text,
              style: TextStyle(fontSize: 19, color: Colors.white),
            ),
            SizedBox(
              height: 10.0,
            ),
            Text(
              'عدد المرات المتبقية: ${zeqr.count}'.toString(),
              style: TextStyle(fontSize: 15, color: Colors.yellow),
            ),
            SizedBox(
              height: 6.0,
            ),
            RaisedButton(
                color: Colors.cyan[200],
                onPressed: reduce,
                child: Text('اتممت مرة'))
          ],
        ),
      ),
    );
  }
}
