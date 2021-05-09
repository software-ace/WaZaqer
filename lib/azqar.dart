import 'package:flutter/material.dart';
import 'Constants.dart';
import 'Settings.dart';
import 'azqarLists.dart';
import 'package:share/share.dart';

import 'model/zeqr.dart';

class Azqar extends StatefulWidget {
  static const String id = 'Azqar';
  @override
  _AzqarState createState() => _AzqarState();
}

class _AzqarState extends State<Azqar> {
  @override
  Widget build(BuildContext context) {
    double _width = MediaQuery.of(context).size.width;
    double _fontSize = _width * 0.05;

    return DefaultTabController(
      length: zeqrTypes.length,
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
            tabs: zeqrTypes.map<Widget>((ZeqrType zeqrType) {
              return Tab(
                text: zeqrType.title,
              );
            }).toList(),
          ),
        ),
        backgroundColor: Theme.of(context).backgroundColor,
        body: TabBarView(children: [
          ListView(
            children: azqarList
                .where((element) => element.zeqrType == 'afterprayer')
                .map((zeqr) => ZeqrCard(
                      fontSize: _fontSize,
                      zeqr: zeqr,
                      reduce: () {
                        setState(() {
                          zeqr.count -= 1;
                          if (zeqr.count == 0) {
                            azqarList.remove(zeqr);
                          }
                        });
                      },
                      fav: () {
                        setState(() {
                          if (zeqr.isFavorite == false) {
                            zeqr.isFavorite = !zeqr.isFavorite;
                            favs.add(zeqr);
                            print('add');
                          } else if (zeqr.isFavorite == true) {
                            zeqr.isFavorite = !zeqr.isFavorite;
                            favs.remove(zeqr);
                            print('del');
                          }
                        });
                      },
                    ))
                .toList(),
          ),
          ListView(
            children: azqarList
                .where((element) => element.zeqrType == 'morning')
                .map((zeqr) => ZeqrCard(
                      fontSize: _fontSize,
                      zeqr: zeqr,
                      reduce: () {
                        setState(() {
                          zeqr.count -= 1;
                          if (zeqr.count == 0) {
                            azqarList.remove(zeqr);
                          }
                        });
                      },
                      fav: () {
                        setState(() {
                          if (zeqr.isFavorite == false) {
                            zeqr.isFavorite = !zeqr.isFavorite;
                            favs.add(zeqr);
                            print('add');
                          } else if (zeqr.isFavorite == true) {
                            zeqr.isFavorite = !zeqr.isFavorite;
                            favs.remove(zeqr);
                            print('del');
                          }
                        });
                      },
                    ))
                .toList(),
          ),
          ListView(
            children: azqarList
                .where((element) => element.zeqrType == 'night')
                .map((zeqr) => ZeqrCard(
                      fontSize: _fontSize,
                      zeqr: zeqr,
                      reduce: () {
                        setState(() {
                          zeqr.count -= 1;
                          if (zeqr.count == 0) {
                            azqarList.remove(zeqr);
                          }
                        });
                      },
                      fav: () {
                        setState(() {
                          if (zeqr.isFavorite == false) {
                            zeqr.isFavorite = !zeqr.isFavorite;
                            favs.add(zeqr);
                            print('add');
                          } else if (zeqr.isFavorite == true) {
                            zeqr.isFavorite = !zeqr.isFavorite;
                            favs.remove(zeqr);
                            print('del');
                          }
                        });
                      },
                    ))
                .toList(),
          ),
          ListView(
            children: azqarList
                .where((element) => element.zeqrType == 'sleep')
                .map((zeqr) => ZeqrCard(
                      fontSize: _fontSize,
                      zeqr: zeqr,
                      reduce: () {
                        setState(() {
                          zeqr.count -= 1;
                          if (zeqr.count == 0) {
                            azqarList.remove(zeqr);
                          }
                        });
                      },
                      fav: () {
                        setState(() {
                          if (zeqr.isFavorite == false) {
                            zeqr.isFavorite = !zeqr.isFavorite;
                            favs.add(zeqr);
                            print('add');
                          } else if (zeqr.isFavorite == true) {
                            zeqr.isFavorite = !zeqr.isFavorite;
                            favs.remove(zeqr);
                            print('del');
                          }
                        });
                      },
                    ))
                .toList(),
          ),
          ListView(
            children: azqarList
                .where((element) => element.isFavorite == true)
                .map((zeqr) => ZeqrCard(
                      fontSize: _fontSize,
                      zeqr: zeqr,
                      reduce: () {
                        setState(() {
                          zeqr.count -= 1;
                          if (zeqr.count == 0) {
                            azqarList.remove(zeqr);
                          }
                        });
                      },
                      fav: () {
                        setState(() {
                          if (zeqr.isFavorite == false) {
                            zeqr.isFavorite = !zeqr.isFavorite;
                            favs.add(zeqr);
                            print('add');
                          } else if (zeqr.isFavorite == true) {
                            zeqr.isFavorite = !zeqr.isFavorite;
                            favs.remove(zeqr);
                            print('del');
                          }
                        });
                      },
                    ))
                .toList(),
          ),
        ]),
      ),
    );
  }
}

class ZeqrCard extends StatefulWidget {
  final Zeqr zeqr;
  final VoidCallback reduce;
  final Function fav;
  final double fontSize;
  ZeqrCard(
      {required this.zeqr,
      required this.reduce,
      required this.fontSize,
      required this.fav});
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                    icon: widget.zeqr.isFavorite
                        ? Icon(Icons.favorite)
                        : Icon(Icons.favorite_border),
                    tooltip: 'Favorite',
                    color: Theme.of(context).buttonColor,
                    onPressed: () {
                      widget.fav();
                    }),
                Builder(builder: (BuildContext context) {
                  return IconButton(
                      icon: Icon(Icons.share),
                      tooltip: 'Share',
                      color: Theme.of(context).buttonColor,
                      onPressed: () {
                        Share.share(widget.zeqr.text);
                      });
                }),
                ElevatedButton(
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                            Theme.of(context).buttonColor)),
                    onPressed: widget.reduce,
                    child: widget.zeqr.count == 1
                        ? Text(
                            'اتممت',
                            style: TextStyle(fontSize: 17),
                          )
                        : Text('اتممت مرة')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
