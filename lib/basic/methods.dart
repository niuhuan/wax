import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:url_launcher/url_launcher.dart';
import 'package:wax/configs/host.dart';
import 'package:wax/protos/properties.pb.dart';

final methods = Methods._();

class Methods {
  Methods._();

  static const MethodChannel _channel = MethodChannel("methods");

  Future<Uint8List> _flatInvoke(
    String method,
    $pb.GeneratedMessage params,
  ) async {
    String hexString = await _channel.invokeMethod("flatInvoke", {
      "method": method,
      "params": params.writeToBuffer(),
    });
    return Uint8List.fromList(hex.decode(hexString));
  }

  Future saveProperty({required String k, required String v}) async {
    return _flatInvoke(
      "saveProperty",
      SavePropertyQuery(k: k, v: v),
    );
  }

  Future<String> loadProperty({required String k}) async {
    return LoadPropertyResult.fromBuffer(await _flatInvoke(
      "loadProperty",
      LoadPropertyQuery(k: k),
    ))
        .v;
  }

  Future<FetchComicResult> fetchComic(
    String filterName,
    String filterValue,
    int pageNumber,
  ) async {
    final buff = await _flatInvoke(
        "fetchComic",
        FetchComicQuery(
          host: host,
          filterName: filterName,
          filterValue: filterValue,
          pageNumber: $fixnum.Int64.fromInts(0, pageNumber),
        ));
    return FetchComicResult.fromBuffer(buff);
  }

  Future<FetchComicResult> searchComic(String keyword, int page) async {
    final buff = await _flatInvoke(
        "searchComic",
        ComicSearchQuery(
          host: host,
          query: keyword,
          pageNumber: $fixnum.Int64.fromInts(0, page),
        ));
    return FetchComicResult.fromBuffer(buff);
  }

  Future saveImageToGallery(String path) async {
    if (Platform.isAndroid || Platform.isIOS) {
      return await _channel.invokeMethod("saveImageToGallery", {'path': path});
    }
    throw "?????????????????????";
  }

  Future<int> androidGetVersion() async {
    if (Platform.isAndroid) {
      return await _channel.invokeMethod("androidGetVersion");
    }
    return 0;
  }

  Future<List<String>> loadAndroidModes() async {
    return List.of(await _channel.invokeMethod("androidGetModes"))
        .map((e) => "$e")
        .toList();
  }

  Future setAndroidMode(String androidDisplayMode) {
    return _channel.invokeMethod(
      "androidSetMode",
      {
        "mode": androidDisplayMode,
      },
    );
  }

  Future autoClean({required int time}) async {
    return _flatInvoke(
      "autoClean",
      AutoCleanQuery(
        expire: $fixnum.Int64.fromInts(0, time),
      ),
    );
  }

  Future<String> httpGet({required String url}) async {
    final buff = await _flatInvoke(
        "httpGet",
        HttpGetQuery(
          url: url,
        ));
    return HttpGetResult.fromBuffer(buff).content;
  }

  Future cleanAllCache() async {
    // todo
  }

  Future<CacheImageResult> cacheImage(String url) async {
    final buff = await _flatInvoke(
        "cacheImage",
        CacheImageQuery(
          host: host,
          url: url,
        ));
    return CacheImageResult.fromBuffer(buff);
  }

  Future<ComicInfoResult> comicInfo($fixnum.Int64 id) async {
    final buff = await _flatInvoke(
        "comicInfo",
        ComicInfoQuery(
          host: host,
          id: id,
        ));
    return ComicInfoResult.fromBuffer(buff);
  }

  Future<ComicPagesResult> comicPages($fixnum.Int64 id) async {
    final buff = await _flatInvoke(
        "comicPages",
        ComicInfoQuery(
          host: host,
          id: id,
        ));
    return ComicPagesResult.fromBuffer(buff);
  }

  Future login(String username, String password) {
    return _flatInvoke(
        "login",
        UserLoginQuery(
          host: host,
          username: username,
          password: password,
        ));
  }

  Future register({
    required String username,
    required String nickname,
    required String email,
    required String sex,
    required String pass,
    required String passAgain,
  }) {
    return _flatInvoke(
      "register",
      UserRegisterQuery(
        host: host,
        username: username,
        nickname: nickname,
        email: email,
        sex: sex,
        pass: pass,
        passAgain: passAgain,
      ),
    );
  }

  Future<IsPro> isPro() async {
    return IsPro.fromBuffer(await _flatInvoke(
      "isPro",
      Empty(),
    ));
  }

  Future<IsPro> reloadPro() async {
    return IsPro.fromBuffer(await _flatInvoke(
      "reloadPro",
      Empty(),
    ));
  }

  Future inputCdKey(String k) {
    return _flatInvoke("inputCdKey", Puff(value: k));
  }

  Future saveViewInfo(ComicInfoResult info) async {
    // todo
  }

  Future<bool> hasDownload($fixnum.Int64 comicId) async {
    return BoolValue.fromBuffer(await _flatInvoke(
      "hasDownload",
      DownloadInfoQuery(
        id: comicId,
      ),
    )).value;
  }

  Future updateViewLog($fixnum.Int64 id, int initRank) async {
    // todo
  }

  Future pushToDownloads(List<ComicSimple> list) {
    return _flatInvoke(
      "pushToDownloads",
      PushToDownloads(
        host: host,
        comics: list,
      ),
    );
  }

  Future<ComicDownloadsRes> downloads() async {
    return ComicDownloadsRes.fromBuffer(await _flatInvoke(
      "downloads",
      Empty(),
    ));
  }

  Future<ComicDownloadInfoDto> downloadInfo($fixnum.Int64 id) async {
    return ComicDownloadInfoDto.fromBuffer(await _flatInvoke(
      "downloadInfo",
      DownloadInfoQuery(
        id: id,
      ),
    ));
  }

  Future<DownloadComicPages> downloadPages($fixnum.Int64 id) async {
    return DownloadComicPages.fromBuffer(await _flatInvoke(
      "downloadPages",
      DownloadInfoQuery(
        id: id,
      ),
    ));
  }

  Future resetDownload() {
    return _flatInvoke(
      "resetDownload",
      Empty(),
    );
  }

  Future setDownloadThread(int count) {
    return _flatInvoke(
      "setDownloadThread",
      IntValue(
        value: $fixnum.Int64.fromInts(0, count),
      ),
    );
  }

  Future<int> getDownloadThread() async {
    return IntValue.fromBuffer(await _flatInvoke(
      "getDownloadThread",
      Empty(),
    ))
        .value
        .toInt();
  }
}
