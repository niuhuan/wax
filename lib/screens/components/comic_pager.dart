import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wax/basic/commons.dart';
import 'package:wax/basic/methods.dart';
import 'package:wax/protos/properties.pb.dart';

import '../../configs/is_pro.dart';
import '../../configs/pager_controller_mode.dart';
import 'comic_list.dart';
import 'content_builder.dart';

class ComicPager extends StatefulWidget {
  final Future<FetchComicResult> Function(int page) onPage;

  const ComicPager({required this.onPage, Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ComicPagerState();
}

class _ComicPagerState extends State<ComicPager> {
  @override
  void initState() {
    currentPagerControllerModeEvent.subscribe(_setState);
    super.initState();
  }

  @override
  void dispose() {
    currentPagerControllerModeEvent.unsubscribe(_setState);
    super.dispose();
  }

  _setState(_) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    switch (currentPagerControllerMode) {
      case PagerControllerMode.stream:
        return _StreamPager(onPage: widget.onPage);
      case PagerControllerMode.pager:
        return _PagerPager(onPage: widget.onPage);
    }
  }
}

class _StreamPager extends StatefulWidget {
  final Future<FetchComicResult> Function(int page) onPage;

  const _StreamPager({Key? key, required this.onPage}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _StreamPagerState();
}

class _StreamPagerState extends State<_StreamPager> {
  int _maxPage = 1;
  int _nextPage = 1;

  var _joining = false;
  var _joinSuccess = true;

  bool get _notPro => !isPro && _nextPage > 20;

  Future _join() async {
    try {
      setState(() {
        _joining = true;
      });
      var response = await widget.onPage(_nextPage);
      _nextPage++;
      _data.addAll(response.comics);
      _maxPage = response.maxPage.toInt();
      setState(() {
        _joinSuccess = true;
        _joining = false;
      });
    } catch (e, st) {
      print("$e\n$st");
      setState(() {
        _joinSuccess = false;
        _joining = false;
      });
    }
  }

  final List<ComicSimple> _data = [];
  List<ComicSimple>? _selected = null;
  late ScrollController _controller;

  @override
  void initState() {
    _controller = ScrollController();
    _join();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_joining || _nextPage > _maxPage || _notPro) {
      return;
    }
    if (_controller.position.pixels + 100 >
        _controller.position.maxScrollExtent) {
      _join();
    }
  }

  Widget? _buildLoadingCard() {
    if (_notPro) {
      return Card(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              child: const CupertinoActivityIndicator(
                radius: 14,
              ),
            ),
            const Text(
              '????????????????????????',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    if (_joining) {
      return Card(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              child: const CupertinoActivityIndicator(
                radius: 14,
              ),
            ),
            const Text('?????????'),
          ],
        ),
      );
    }
    if (!_joinSuccess) {
      return Card(
        child: InkWell(
          onTap: () {
            _join();
          },
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                child: const Icon(Icons.sync_problem_rounded),
              ),
              const Text('??????, ????????????'),
            ],
          ),
        ),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildPagerBar(),
        Expanded(
          child: ComicList(
            controller: _controller,
            onScroll: _onScroll,
            data: _data,
            selected: _selected,
            append: _buildLoadingCard(),
          ),
        ),
      ],
    );
  }

  PreferredSize _buildPagerBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(30),
      child: Container(
        padding: const EdgeInsets.only(left: 10, right: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              width: .5,
              style: BorderStyle.solid,
              color: Colors.grey[200]!,
            ),
          ),
        ),
        child: SizedBox(
          height: 30,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("????????? ${_nextPage - 1} / $_maxPage ???"),
            ],
          ),
        ),
      ),
    );
  }
}

class _PagerPager extends StatefulWidget {
  final Future<FetchComicResult> Function(int page) onPage;

  const _PagerPager({Key? key, required this.onPage}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PagerPagerState();
}

class _PagerPagerState extends State<_PagerPager> {
  final TextEditingController _textEditController =
      TextEditingController(text: '');
  late int _currentPage = 1;
  late int _maxPage = 1;
  late final List<ComicSimple> _data = [];
  late Future _pageFuture = _load();
  List<ComicSimple>? _selected;

  Future<dynamic> _load() async {
    _selected = null;
    var response = await widget.onPage(_currentPage);
    setState(() {
      _data.clear();
      _data.addAll(response.comics);
      _maxPage = response.maxPage.toInt();
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _textEditController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ContentBuilder(
      future: _pageFuture,
      onRefresh: () async {
        setState(() {
          _pageFuture = _load();
        });
      },
      successBuilder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        return Scaffold(
          appBar: _buildPagerBar(),
          body: ComicList(
            data: _data,
            selected: _selected,
          ),
        );
      },
    );
  }

  PreferredSize _buildPagerBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(50),
      child: Container(
        padding: const EdgeInsets.only(left: 10, right: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              width: .5,
              style: BorderStyle.solid,
              color: Colors.grey[200]!,
            ),
          ),
        ),
        child: SizedBox(
          height: 50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () {
                  _textEditController.clear();
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        content: Card(
                          child: TextField(
                            controller: _textEditController,
                            decoration: const InputDecoration(
                              labelText: "??????????????????",
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.allow(RegExp(r'\d+')),
                            ],
                          ),
                        ),
                        actions: <Widget>[
                          MaterialButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('??????'),
                          ),
                          MaterialButton(
                            onPressed: () {
                              Navigator.pop(context);
                              var text = _textEditController.text;
                              if (text.isEmpty || text.length > 5) {
                                return;
                              }
                              var num = int.parse(text);
                              if (num == 0 || num > _maxPage) {
                                return;
                              }
                              if (_currentPage > 20) {
                                defaultToast(context, "????????????????????????");
                                return;
                              }
                              setState(() {
                                _currentPage = num;
                                _pageFuture = _load();
                              });
                            },
                            child: const Text('??????'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Row(
                  children: [
                    Text("??? $_currentPage / $_maxPage ???"),
                  ],
                ),
              ),
              Row(children: [
                GestureDetector(
                  onTap: () {
                    if (_selected == null) {
                      _selected = [];
                      setState(() {});
                    } else {
                      _selected = null;
                      setState(() {});
                    }
                  },
                  child: const Text("??????"),
                ),
                const Text(
                  " / ",
                  style: TextStyle(color: Colors.grey),
                ),
                GestureDetector(
                  onTap: () async {
                    if (_selected != null) {
                      if (!isPro) {
                        defaultToast(context, "????????????????????????");
                        return;
                      }
                      await methods.pushToDownloads(_selected!);
                      // todo ??????
                      defaultToast(context, "????????????????????????");
                      _selected = null;
                      setState(() {});
                    }
                  },
                  child: Text(
                    "??????",
                    style: TextStyle(
                      color: _selected == null ? Colors.grey : null,
                    ),
                  ),
                ),
              ]),
              Row(
                children: [
                  MaterialButton(
                    minWidth: 0,
                    onPressed: () {
                      if (_currentPage > 1) {
                        setState(() {
                          _currentPage = _currentPage - 1;
                          _pageFuture = _load();
                        });
                      }
                    },
                    child: const Text('?????????'),
                  ),
                  MaterialButton(
                    minWidth: 0,
                    onPressed: () {
                      if (_currentPage < _maxPage) {
                        if (_currentPage >= 20) {
                          defaultToast(context, "????????????????????????");
                          return;
                        }
                        setState(() {
                          _currentPage = _currentPage + 1;
                          _pageFuture = _load();
                        });
                      }
                    },
                    child: const Text('?????????'),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
