import 'package:accountbook_mobile/widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'api.dart';

class HomeView extends StatefulWidget {
  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  Future<dynamic> _staticsFuture;
  Future<dynamic> _lastestFuture;
  List<dynamic> _lastestItems;

  _HomeViewState() {
    _staticsFuture = _refreshStatics();
    _lastestFuture = _refreshLastest(20, 0);
  }

  String _getCurrentMonth(String format) {
    return DateFormat(format)
        .format(new DateTime(DateTime.now().year, DateTime.now().month, 1));
  }

  Future<dynamic> _refreshStatics() async {
    var currentMonth = _getCurrentMonth("yyyy-MM-dd");
    var resIncome = await api(
        "/statics/monthlyincome/?beginDate=$currentMonth&endDate=$currentMonth");
    var resPayout = await api(
        "/statics/monthlypayout/?beginDate=$currentMonth&endDate=$currentMonth");
    return [resIncome.data, resPayout.data];
  }

  Future<dynamic> _refreshLastest(int take, int skip) async {
    var res = await api("/item/?take=$take&skip=$skip");
    var data = res.data;
    if (_lastestItems == null) {
      _lastestItems = data;
    } else {
      _lastestItems.addAll(data);
    }
    return _lastestItems;
  }

  Widget _buildStaticsBar() {
    return Container(
        decoration: BoxDecoration(color: Colors.blue),
        child: Column(children: [
          Padding(
              padding: EdgeInsets.all(20),
              child: FutureBuilder(
                  future: _staticsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasData && !snapshot.hasError) {
                      var income = snapshot.data[0][_getCurrentMonth("yyyyMM")];
                      var payout = snapshot.data[1][_getCurrentMonth("yyyyMM")];
                      return Row(
                        children: [
                          Expanded(
                              child: MainMoneyBox(
                                  title: "本月支出", money: payout, hasData: true)),
                          Expanded(
                              child: MainMoneyBox(
                                  title: "本月收入", money: income, hasData: true)),
                        ],
                      );
                    } else {
                      return Row(
                        children: [
                          Expanded(
                              child: MainMoneyBox(
                                  title: "本月支出", money: 0, hasData: false)),
                          Expanded(
                              child: MainMoneyBox(
                                  title: "本月收入", money: 0, hasData: false)),
                        ],
                      );
                    }
                  })),
          Padding(
              padding: EdgeInsets.all(10),
              child: Center(
                  child: TextButton(
                child: Text(
                  "记一笔",
                  textScaleFactor: 1.25,
                ),
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.white),
                    padding: MaterialStateProperty.all(
                        EdgeInsets.fromLTRB(50, 10, 50, 10)),
                    textStyle: MaterialStateProperty.all(
                        TextStyle(color: Colors.white))),
                onPressed: () async {
                  await Navigator.of(context).pushNamed("Note", arguments: {});
                  setState(() {
                    _staticsFuture = _refreshStatics();
                    _lastestItems = null;
                    _lastestFuture = _refreshLastest(20, 0);
                  });
                },
              )))
        ]));
  }

  Widget _buildLastestItemBar() {
    return Expanded(
        child: FutureBuilder(
            future: _lastestFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                var data = snapshot.data;
                return ItemListView(
                  items: data,
                  onLoadMore: _handleLoadMore,
                );
              } else if (snapshot.hasError) {
                if (_lastestItems != null) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text("数据加载失败")));
                  return ItemListView(
                    items: _lastestItems,
                    onLoadMore: _handleLoadMore,
                  );
                } else {
                  return Center(
                    child: Text("数据加载失败"),
                  );
                }
              } else {
                return Container();
              }
            }));
  }

  void _handleLoadMore() {
    setState(() {
      _lastestFuture = _refreshLastest(20, _lastestItems.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    var staticsbar = _buildStaticsBar();
    var lastestItemBar = _buildLastestItemBar();
    return Column(
      children: [staticsbar, lastestItemBar],
    );
  }
}

class SettingView extends StatefulWidget {
  @override
  _SettingViewState createState() => _SettingViewState();
}

class _SettingViewState extends State<SettingView> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          title: Text("收支分类"),
          onTap: () {
            Navigator.pushNamed(context, "CategorySetting");
          },
        )
      ],
    );
  }
}
