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
    return GridView.extent(
      maxCrossAxisExtent: 100,
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
                        ...(e["category2_name"] != null
                            ? [
                                Text(
                                  e["category2_name"],
                                  style: TextStyle(
                                      color: e["id"] != selectedItem
                                          ? getColor()
                                          : Colors.white),
                                  textScaleFactor: 0.8,
                                )
                              ]
                            : [])
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

class NoteForm extends StatefulWidget {
  final dynamic categories;
  final int type;
  final dynamic item;

  NoteForm(this.categories, this.type, this.item);

  @override
  State<StatefulWidget> createState() {
    return _NoteFormState(categories, type, item);
  }
}

class _NoteFormState extends State<NoteForm> {
  Map<String, TextEditingController> _controllers = {
    "cash": TextEditingController(),
    "date": TextEditingController(),
    "comment": TextEditingController()
  };
  PersistentBottomSheetController _subCategoryBottomSheetController;
  dynamic categories;
  dynamic displayCategories;
  int type;
  dynamic item;
  //表单数据
  double _cash;
  DateTime _date;
  dynamic _selectedCategory1;
  dynamic _selectedCategory2;
  String _comment;

  _NoteFormState(this.categories, this.type, this.item) {
    displayCategories = [
      ...categories.where((r) => r["type"] == type && r["parentId"] == null)
    ];

    if (item == null) {
      _initialData();
    } else {
      _selectedCategory1 =
          categories.firstWhere((r) => r["id"] == item["category1Id"]);
      _selectedCategory2 = categories.firstWhere(
          (r) => r["id"] == item["category2Id"],
          orElse: () => null);
      _cash = item["cash"];
      _date = DateTime.parse(item["date"]);
      _comment = item["comment"];
    }
    _renderForm();
  }

  void _initialData() {
    _selectedCategory1 =
        displayCategories.length > 0 ? displayCategories[0] : null;

    _cash = 0;
    var now = DateTime.now().toLocal();
    _date = DateTime(now.year, now.month, now.day);
    _comment = "";
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

  void _setCategory(dynamic category1, dynamic category2) {
    setState(() {
      _selectedCategory1 = category1;
      _selectedCategory2 = category2;
    });
  }

  void _handleCategoryPress(e) {
    if (e["haveChildren"]) {
      _showSubCategory(e);
    } else {
      _setCategory(e, null);
    }
  }

  void _handleSubCategoryPress(category1, category2) {
    _setCategory(category1, category2);
    _subCategoryBottomSheetController.close();
  }

  void _showSubCategory(parent) {
    var subCategories = [
      ...categories.where((item) => item["parentId"] == parent["id"])
    ];
    var subCategoryWidgets = subCategories.map((item) => ListTile(
          title: Text(item["name"]),
          onTap: () => _handleSubCategoryPress(parent, item),
        ));
    var parentCategoryWidget = ListTile(
      title: Text(parent["name"]),
      onTap: () => _handleSubCategoryPress(parent, item),
    );
    _subCategoryBottomSheetController =
        Scaffold.of(context).showBottomSheet((context) {
      return Container(
          child: ListView(
        children: <Widget>[parentCategoryWidget, ...subCategoryWidgets],
      ));
    });
  }

  void _handleNote(int type, {bool isNoteMore = false}) async {
    _updateData();
    try {
      Response<dynamic> res;
      if (item == null) {
        res = await api("/item/", method: "POST", data: {
          "date": _date.toIso8601String(),
          "cash": _cash,
          "type": type,
          "category1Id": _selectedCategory1["id"],
          "category2Id":
              _selectedCategory2 != null ? _selectedCategory2["id"] : null,
          "comment": _comment
        });
      } else {
        res = await api("/item/" + item["id"].toString(), method: "PUT", data: {
          "id": item["id"],
          "date": _date.toIso8601String(),
          "cash": _cash,
          "type": type,
          "category1Id": _selectedCategory1["id"],
          "category2Id":
              _selectedCategory2 != null ? _selectedCategory2["id"] : null,
          "comment": _comment
        });
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("保存成功")));
      if (isNoteMore) {
        _initialData();
        _renderForm();
      } else {
        Navigator.of(context).pop({"operation": "save", "item": res.data});
      }
    } on DioError catch (e) {
      handleError(context, e);
    }
  }

  void _handleDelete() async {
    try {
      await api("/item/" + item["id"].toString(), method: "DELETE");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("删除成功")));
      Navigator.of(context).pop({"operation": "delete", "item": item});
    } on DioError catch (e) {
      handleError(context, e);
    }
  }

  Widget _buildNoteButton() =>
      TextButton(child: Text("保存"), onPressed: () => _handleNote(type));

  Widget _buildNoteMoreButton() => TextButton(
        child: Text("再记一笔"),
        onPressed: () => _handleNote(type, isNoteMore: true),
      );

  Widget _buildDeleteButton() => TextButton(
        child: Text("删除"),
        style:
            ButtonStyle(foregroundColor: MaterialStateProperty.all(Colors.red)),
        onPressed: () => _handleDelete(),
      );

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
              categories: [
                ...displayCategories.map((i) {
                  if (i["id"] == _selectedCategory1["id"] &&
                      _selectedCategory2 != null) {
                    return {...i, "category2_name": _selectedCategory2["name"]};
                  } else {
                    return i;
                  }
                })
              ],
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
              child: Row(children: [
                Expanded(child: _buildNoteButton()),
                Expanded(
                    child: item == null
                        ? _buildNoteMoreButton()
                        : _buildDeleteButton())
              ]))
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
  final dynamic onItemTap;

  ItemListView({this.items, this.onLoadMore, this.onItemTap});

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
        onTap: () async => onItemTap != null ? await onItemTap(r) : null,
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
