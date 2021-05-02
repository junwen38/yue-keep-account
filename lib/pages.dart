import 'package:accountbook_mobile/widgets.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'api.dart';

class CategorySettingPage extends StatefulWidget {
  final Map _args;

  CategorySettingPage(this._args);

  @override
  State<StatefulWidget> createState() {
    return _CategorySettingPageState(_args);
  }
}

class _CategorySettingPageState extends State<CategorySettingPage> {
  Future<dynamic> _ajaxFuture;
  dynamic _parent;

  _CategorySettingPageState(Map args) {
    if (args != null) {
      _parent = args["parent"];
    }
  }

  @override
  void initState() {
    super.initState();
    _ajaxFuture = _refresh();
  }

  Future<dynamic> _refresh() async {
    var query = _parent == null ? "" : "?parentId=${_parent['id']}";
    var res = await api("/category/$query");
    return res.data;
  }

  void _showSubCategory(BuildContext context, dynamic parent) {
    if (this._parent != null) return;
    Navigator.of(context)
        .pushNamed("CategorySetting", arguments: {"parent": parent});
  }

  void _showAdditionForm(BuildContext context, dynamic parent, int type) async {
    await Navigator.of(context).pushNamed("CategoryAddition",
        arguments: {"parent": parent, "type": type});
    setState(() {
      _ajaxFuture = _refresh();
    });
  }

  void _showMenu(BuildContext context, dynamic category) {
    showModalBottomSheet(
        builder: (context) {
          return Container(
              height: 200,
              child: ListView(
                children: [
                  ListTile(
                    title: Text(
                      "重命名",
                    ),
                  ),
                  ListTile(
                    title: Text(
                      "删除",
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () => _onDeleteCategory(category),
                  )
                ],
              ));
        },
        context: context);
  }

  void _onDeleteCategory(dynamic category) async {
    try {
      Navigator.of(context).pop();
      await api("/category/${category["id"]}", method: "DELETE");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("删除成功")));
      setState(() {
        _ajaxFuture = _refresh();
      });
    } on DioError catch (e) {
      handleError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Tab> tabs = [];
    if (_parent == null) {
      tabs.add(Tab(
        text: "支出",
      ));
      tabs.add(Tab(
        text: "收入",
      ));
    } else {
      if (_parent["type"] == 0) {
        tabs.add(Tab(text: "支出"));
      } else {
        tabs.add(Tab(text: "收入"));
      }
    }
    return DefaultTabController(
      length: tabs.length,
      initialIndex: 0,
      child: Scaffold(
          appBar: AppBar(
            title: Text("收支分类"),
            bottom: TabBar(tabs: tabs),
          ),
          body: FutureBuilder(
              future: _ajaxFuture,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return TabBarView(
                    children: [
                      ...tabs.map((item) {
                        switch (item.text) {
                          case "支出":
                            return CategoryGridView(
                              type: 0,
                              categories: [
                                ...snapshot.data.where((i) => i["type"] == 0)
                              ],
                              onPress: (item) =>
                                  _showSubCategory(context, item),
                              onAdditionPress: () =>
                                  _showAdditionForm(context, _parent, 0),
                              onLongPress: (item) => _showMenu(context, item),
                            );
                          case "收入":
                            return CategoryGridView(
                              type: 1,
                              categories: [
                                ...snapshot.data.where((i) => i["type"] == 1)
                              ],
                              onPress: (item) =>
                                  _showSubCategory(context, item),
                              onAdditionPress: () =>
                                  _showAdditionForm(context, _parent, 1),
                            );
                          default:
                            return Center();
                        }
                      })
                    ],
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text("数据加载失败"),
                  );
                } else {
                  return Center(
                    child: Text("Loading..."),
                  );
                }
              })),
    );
  }
}

class CategoryAdditionPage extends StatefulWidget {
  final Map _args;

  CategoryAdditionPage(this._args);

  @override
  State<StatefulWidget> createState() {
    return _CategoryAdditionPageState(_args);
  }
}

class _CategoryAdditionPageState extends State<CategoryAdditionPage> {
  Map<String, TextEditingController> _controllers = {
    "name": TextEditingController()
  };
  Map _args;

  _CategoryAdditionPageState(this._args);

  String getValue(String name) {
    return _controllers[name].value.text;
  }

  @override
  Widget build(BuildContext context) {
    Map arguments = _args;
    return Scaffold(
        appBar: AppBar(
          title: Text("添加分类"),
        ),
        body: Padding(
            padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
            child: Form(
              child: Column(
                children: [
                  arguments['parent'] != null
                      ? Center(
                          child: Text("大分类：${arguments['parent']['name']}"))
                      : Center(),
                  TextFormField(
                    decoration: InputDecoration(
                        labelText: "分类名称",
                        labelStyle: TextStyle(
                            color: arguments["type"] == 0
                                ? Colors.red
                                : Colors.green)),
                    controller: _controllers["name"],
                  ),
                  Center(
                    child: Builder(builder: (context) {
                      return TextButton(
                        child: Center(child: Text("添加分类")),
                        onPressed: () async {
                          try {
                            await api("/category", method: "POST", data: {
                              "name": getValue("name"),
                              "type": arguments["type"],
                              ...(arguments["parent"] != null
                                  ? {"parentId": arguments["parent"]["id"]}
                                  : {})
                            });
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text("分类添加成功"),
                            ));
                            Navigator.pop(context, true);
                          } on DioError catch (e) {
                            handleError(context, e);
                          }
                        },
                      );
                    }),
                  )
                ],
              ),
            )));
  }
}

class NotePage extends StatefulWidget {
  final Map _args;
  NotePage(this._args);

  @override
  State<StatefulWidget> createState() {
    return _NotePageState();
  }
}

class _NotePageState extends State<NotePage> {
  Map<String, TextEditingController> _controllers = {
    "cash": TextEditingController(),
    "date": TextEditingController(),
    "comment": TextEditingController()
  };

  //表单数据
  double _cash;
  DateTime _date;
  dynamic _selectedCategory1;
  dynamic _selectedCategory2;
  String _comment;

  Future _future;

  _NotePageState() {
    _future = _refresh();
  }

  //从表单数据更新Widget
  void _renderForm() {
    _controllers["cash"].text = _cash.toString();
    _controllers["data"].text = DateFormat("yyyy-MM-dd").format(_date);
    _controllers["comment"].text = _comment;
  }

  //从Widget更新表单数据
  void _updateData() {
    _cash = double.parse(_controllers["cash"].text);
    _date = DateTime.parse(_controllers["date"].text);
    _comment = _controllers["comment"].text;
  }

  Future<dynamic> _refresh() async {
    var res = await api("/category/");
    return res.data;
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
    return DefaultTabController(
        length: 2,
        child: Scaffold(
            appBar: AppBar(
              title: Text("记一笔"),
              bottom: TabBar(
                tabs: [Tab(text: "支出"), Tab(text: "收入")],
              ),
            ),
            body: FutureBuilder(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  var categories = snapshot.data;
                  if (_selectedCategory1 == null)
                    _selectedCategory1 =
                        categories.length > 0 ? categories[0] : null;
                  const fieldMargin = EdgeInsets.fromLTRB(0, 0, 0, 10);
                  var payoutForm = Form(
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
                              ...categories.where((i) => i["type"] == 0)
                            ],
                            type: 0,
                            selectedItem: _selectedCategory1 != null
                                ? _selectedCategory1["id"]
                                : null,
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
                                  firstDate: DateTime.parse(
                                      "1900-01-01T00:00:00.000Z"),
                                  lastDate: DateTime.parse(
                                      "2050-12-31T23:59:59.999Z"));
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
                                child: Text("记一笔"),
                                onPressed: () => _handleNote(0)))
                      ],
                    ),
                  );
                  var incomeForm = Center();
                  return TabBarView(children: [payoutForm, incomeForm]);
                } else if (snapshot.hasError) {
                  //Error
                  return Center(child: Text("加载失败"));
                } else {
                  //Loading
                  return Center(child: Text("Loading..."));
                }
              },
            )));
  }
}
