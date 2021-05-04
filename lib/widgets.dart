import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'api.dart';

class CategoryGridView extends StatelessWidget {
  final Function onPress;
  final Function onLongPress;
  final Function onAdditionPress;
  final List<dynamic> categories;
  final int type;
  final int selectedItem;

  CategoryGridView(
      {this.onPress,
      this.onLongPress,
      this.onAdditionPress,
      this.categories,
      this.type,
      this.selectedItem});

  MaterialColor getColor() {
    if (type == 0)
      return Colors.red;
    else
      return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    var moreWidget = Align(
      alignment: Alignment.topRight,
      child: Container(
        padding: EdgeInsets.all(5),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            color: Colors.black26),
        child: Text(
          "...",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
    return GridView.count(
      crossAxisCount: 5,
      children: [
        ...categories.map(
          (e) => TextButton(
              style: ButtonStyle(
                  backgroundColor: e["id"] != selectedItem
                      ? MaterialStateProperty.all(Colors.white)
                      : MaterialStateProperty.all(getColor())),
              onPressed: () async => await onPress(e),
              onLongPress: () async => await onLongPress(e),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Flex(
                      mainAxisAlignment: MainAxisAlignment.center,
                      direction: Axis.vertical,
                      children: [
                        Icon(
                          Icons.grade,
                          color: e["id"] != selectedItem
                              ? getColor()
                              : Colors.white,
                          size: 40,
                        ),
                        Text(
                          e["name"],
                          style: TextStyle(
                              color: e["id"] != selectedItem
                                  ? getColor()
                                  : Colors.white),
                        ),
                      ]),
                  ...(e["haveChildren"] ? [moreWidget] : [])
                ],
              )),
        ),
        ...(onAdditionPress != null
            ? [
                TextButton(
                  onPressed: onAdditionPress,
                  child: Flex(
                    mainAxisAlignment: MainAxisAlignment.center,
                    direction: Axis.vertical,
                    children: [
                      Icon(Icons.add, color: getColor(), size: 40),
                    ],
                  ),
                )
              ]
            : []),
      ],
    );
  }
}

class PayoutForm extends StatefulWidget {
  final dynamic categories;
  final int type;

  PayoutForm(this.categories, this.type);

  @override
  State<StatefulWidget> createState() {
    return _PayoutFormState(categories, type);
  }
}

class _PayoutFormState extends State<PayoutForm> {
  Map<String, TextEditingController> _controllers = {
    "cash": TextEditingController(),
    "date": TextEditingController(),
    "comment": TextEditingController()
  };
  dynamic categories;
  dynamic displayCategories;
  int type;
  //表单数据
  double _cash;
  DateTime _date;
  dynamic _selectedCategory1;
  dynamic _selectedCategory2;
  String _comment;

  _PayoutFormState(this.categories, this.type) {
    displayCategories = [...categories.where((r) => r["type"] == type)];
    _selectedCategory1 =
        displayCategories.length > 0 ? displayCategories[0] : null;

    _cash = 0;
    var now = DateTime.now().toLocal();
    _date = DateTime(now.year, now.month, now.day);
    _comment = "";
    _renderForm();
  }

  //从表单数据更新Widget
  void _renderForm() {
    _controllers["cash"].text = _cash.toString();
    _controllers["date"].text = DateFormat("yyyy-MM-dd").format(_date);
    _controllers["comment"].text = _comment;
  }

  //从Widget更新表单数据
  void _updateData() {
    _cash = double.parse(_controllers["cash"].text);
    _date = DateTime.parse(_controllers["date"].text);
    _comment = _controllers["comment"].text;
  }

  void _handleCategoryPress(e) {
    setState(() {
      _selectedCategory1 = e;
    });
  }

  void _handleNote(int type) async {
    _updateData();
    try {
      await api("/item/", method: "POST", data: {
        "date": _date.toIso8601String(),
        "cash": _cash,
        "type": type,
        "category1Id": _selectedCategory1["id"],
        "comment": _comment
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("保存成功")));
      Navigator.of(context).pop();
    } on DioError catch (e) {
      handleError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    const fieldMargin = EdgeInsets.fromLTRB(0, 0, 0, 10);
    return Form(
      child: ListView(
        children: [
          Container(
            margin: fieldMargin,
            child: TextFormField(
              controller: _controllers["cash"],
              decoration: InputDecoration(labelText: "金额"),
              keyboardType: TextInputType.number,
            ),
          ),
          Container(
            height: 78.5 * 2,
            margin: fieldMargin,
            child: CategoryGridView(
              categories: [...displayCategories],
              type: type,
              selectedItem:
                  _selectedCategory1 != null ? _selectedCategory1["id"] : null,
              onPress: _handleCategoryPress,
            ),
          ),
          Container(
            margin: fieldMargin,
            child: TextFormField(
              controller: _controllers["date"],
              decoration: InputDecoration(labelText: "日期"),
              keyboardType: TextInputType.numberWithOptions(),
              readOnly: true,
              onTap: () async {
                var date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.parse("1900-01-01T00:00:00.000Z"),
                    lastDate: DateTime.parse("2050-12-31T23:59:59.999Z"));
                _controllers["date"].text =
                    DateFormat("yyyy-MM-dd").format(date);
              },
            ),
          ),
          Container(
            margin: fieldMargin,
            child: TextFormField(
              controller: _controllers["comment"],
              decoration: InputDecoration(labelText: "注释"),
              keyboardType: TextInputType.text,
            ),
          ),
          Container(
              margin: fieldMargin,
              child: TextButton(
                  child: Text("记一笔"), onPressed: () => _handleNote(type)))
        ],
      ),
    );
  }
}

class MainMoneyBox extends StatelessWidget {
  final String title;
  final dynamic money;
  final bool hasData;

  MainMoneyBox({this.title, this.money, this.hasData});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(hasData ? this.money.toString() : "--",
            textScaleFactor: 2, style: TextStyle(color: Colors.white)),
        Text(this.title,
            textScaleFactor: 1, style: TextStyle(color: Colors.white))
      ],
    );
  }
}

class ItemListView extends StatelessWidget {
  final dynamic items;
  final dynamic onLoadMore;

  ItemListView({this.items, this.onLoadMore});

  Widget _getTileTitle(dynamic item) {
    var title = item["category1"]["name"];
    if (item["category2"] != null) {
      title += "-";
      title += item["category2"]["name"];
    }
    return Text(
      title,
      textScaleFactor: 1.25,
    );
  }

  Widget _getTrailing(dynamic item) {
    MaterialColor color;
    if (item["type"] == 0) {
      color = Colors.red;
    } else if (item["type"] == 1) {
      color = Colors.green;
    } else {
      color = Colors.black;
    }

    return Text(item["cash"].toString(),
        textScaleFactor: 1.5, style: TextStyle(color: color));
  }

  @override
  Widget build(BuildContext context) {
    items.sort((r1, r2) {
      var d1 = DateTime.parse(r1["date"]);
      var d2 = DateTime.parse(r2["date"]);
      return d1.compareTo(d2);
    });
    DateTime currentDate;
    var widgets = <Widget>[];
    for (var r in items.reversed) {
      if (DateTime.parse(r["date"]) != currentDate) {
        currentDate = DateTime.parse(r["date"]);
        widgets.add(Container(
          padding: EdgeInsets.all(5),
          child: Text(
            DateFormat("yyyy年MM月dd日").format(currentDate),
            style: TextStyle(color: Colors.black54),
          ),
        ));
      }
      widgets.add(ListTile(
        title: _getTileTitle(r),
        subtitle: r["comment"] != "" ? Text(r["comment"]) : null,
        trailing: _getTrailing(r),
      ));
    }
    widgets.add(ListTile(
      title: Center(
          child: Text(
        "加载更多",
        style: TextStyle(color: Colors.black54),
      )),
      onTap: onLoadMore,
    ));
    return ListView(
      children: widgets,
    );
  }
}
