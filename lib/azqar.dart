import 'package:azqar/Constants.dart';
import 'package:azqar/Settings.dart';
import 'package:flutter/material.dart';
import 'azqarLists.dart';

class Azqar extends StatefulWidget {
  static const String id = 'Azqar';

  @override
  _AzqarState createState() => _AzqarState();
}

class _AzqarState extends State<Azqar> {
  @override
  Widget build(BuildContext context) {
    double fontSize = ModalRoute.of(context).settings.arguments;
    return DefaultTabController(
      length: cats.length,
      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              onPressed: () => Navigator.pushNamed(context, Settings.id),
              icon: Icon(Icons.settings),
            )
          ],
          title: Text('الأذكار'),
          centerTitle: true,
          backgroundColor: Theme.of(context).accentColor,
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
        backgroundColor: Theme.of(context).backgroundColor,
        body: TabBarView(children: [
          ListView(children: [
            Column(
              children: morningAzqarList
                  .map((zeqr) => ZeqrCard(
                        fontSize: fontSize,
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
                        fontSize: fontSize,
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
                        fontSize: fontSize,
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

class ZeqrCard extends StatefulWidget {
  final Zeqr zeqr;
  final Function reduce;
  final double fontSize;
  ZeqrCard({this.zeqr, this.reduce, this.fontSize});
  @override
  _ZeqrCardState createState() => _ZeqrCardState();
}

class _ZeqrCardState extends State<ZeqrCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Text(
                widget.zeqr.text,
                style:
                    TextStyle(fontSize: widget.fontSize, color: kMainTextColor),
                textAlign: TextAlign.right,
              ),
            ),
            SizedBox(
              height: 10.0,
            ),
            Text(
              'عدد المرات المتبقية: ${widget.zeqr.count}'.toString(),
              style: TextStyle(fontSize: 15, color: kCounterColor),
              textAlign: TextAlign.right,
            ),
            SizedBox(
              height: 6.0,
            ),
            RaisedButton(
                color: Theme.of(context).buttonColor,
                onPressed: widget.reduce,
                child: widget.zeqr.count == 1
                    ? Text(
                        'اتممت',
                        style: TextStyle(fontSize: 17),
                      )
                    : Text('اتممت مرة'))
          ],
        ),
      ),
    );
  }
}
