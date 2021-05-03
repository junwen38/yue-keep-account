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

  _HomeViewState() {
    _staticsFuture = _refresh();
  }

  String _getCurrentMonth(String format) {
    return DateFormat(format)
        .format(new DateTime(DateTime.now().year, DateTime.now().month, 1));
  }

  Future<dynamic> _refresh() async {
    var currentMonth = _getCurrentMonth("yyyy-MM-dd");
    var incomeFuture = api(
        "/statics/monthlyincome/?beginDate=$currentMonth&endDate=$currentMonth");
    var payoutFuture = api(
        "/statics/monthlypayout/?beginDate=$currentMonth&endDate=$currentMonth");
    return Future.wait([incomeFuture, payoutFuture]);
  }

  @override
  Widget build(BuildContext context) {
    var staticsbar = Container(
        decoration: BoxDecoration(color: Colors.blue),
        child: Column(children: [
          Padding(
              padding: EdgeInsets.all(20),
              child: FutureBuilder(
                  future: _staticsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasData && !snapshot.hasError) {
                      var income =
                          snapshot.data[0].data[_getCurrentMonth("yyyyMM")];
                      var payout =
                          snapshot.data[1].data[_getCurrentMonth("yyyyMM")];
                      return Row(
                        children: [
                          Expanded(child: MainMoneyBox("本月支出", payout)),
                          Expanded(child: MainMoneyBox("本月收入", income)),
                        ],
                      );
                    } else {
                      return Row(
                        children: [
                          Expanded(child: MainMoneyBox("本月支出", 0)),
                          Expanded(child: MainMoneyBox("本月收入", 0)),
                        ],
                      );
                    }
                  })),
          Padding(
              padding: EdgeInsets.all(10),
              child: Center(
                  child: TextButton(
                child: Text("记一笔"),
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.white),
                    padding: MaterialStateProperty.all(
                        EdgeInsets.fromLTRB(50, 10, 50, 10)),
                    textStyle: MaterialStateProperty.all(
                        TextStyle(color: Colors.white))),
                onPressed: () async {
                  await Navigator.of(context).pushNamed("Note", arguments: {});
                  setState(() {
                    _staticsFuture = _refresh();
                  });
                },
              )))
        ]));
    return Column(
      children: [staticsbar],
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
